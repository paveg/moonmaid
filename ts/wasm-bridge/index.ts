/**
 * WASM bridge for the moonmaid MoonBit module.
 *
 * MoonBit wasm-gc target exports functions that operate on WASM-GC strings
 * (externref / stringref). The JS host must supply a `moonbit:ffi` import
 * object so the module can call back into JS for I/O, and we use the
 * `spectest` / `moonbit` import pattern that the MoonBit toolchain expects.
 *
 * Strings cross the boundary via JS string imports (stringref proposal) when
 * compiled with `--enable-gc`. Since the stringref proposal is not yet
 * universally supported, MoonBit falls back to passing strings as opaque
 * JS values through `externref` when calling the exported render function
 * directly from JS.
 */

export interface MoonmaidInstance {
  render(input: string): string
}

/** Cached singleton – survives HMR reloads because the module ref is stable */
let _cache: MoonmaidInstance | null = null

/**
 * Resolves the default WASM path based on environment.
 * Node.js: relative path from repo root to the built artifact.
 * Browser/bundler: override with wasmPath option.
 */
function defaultWasmPath(): string {
  return new URL(
    '../../target/wasm-gc/release/build/lib/lib.wasm',
    import.meta.url,
  ).href
}

/**
 * Loads the raw WASM bytes from the given URL/path.
 * Works in both Node.js (>=18 fetch) and browser environments.
 */
async function fetchWasm(wasmPath: string): Promise<ArrayBuffer> {
  // Node.js file:// URL
  if (wasmPath.startsWith('file://')) {
    const { readFile } = await import('node:fs/promises')
    const path = new URL(wasmPath).pathname
    const buf = await readFile(path)
    return buf.buffer as ArrayBuffer
  }
  const resp = await fetch(wasmPath)
  if (!resp.ok) {
    throw new Error(`Failed to fetch WASM from ${wasmPath}: ${resp.status} ${resp.statusText}`)
  }
  return resp.arrayBuffer()
}

/**
 * Instantiates the MoonBit wasm-gc module and wraps the exported `render`
 * function in a typed JS interface.
 *
 * MoonBit wasm-gc modules require a minimal import object. The `moonbit:ffi`
 * namespace provides host functions that the runtime calls for things like
 * printing and panicking. We supply no-op stubs for the functions we don't
 * need; the `render` function only needs `abort` in the error path.
 */
async function instantiate(wasmPath: string): Promise<MoonmaidInstance> {
  const bytes = await fetchWasm(wasmPath)

  // MoonBit wasm-gc import requirements:
  //   spectest.print_char  – used by println!/eprintln!
  //   moonbit:ffi.abort    – used by panic
  const importObject: WebAssembly.Imports = {
    spectest: {
      print_char: (_c: number) => { /* no-op: suppress stdout */ },
    },
    'moonbit:ffi': {
      // Called when a MoonBit panic occurs.
      // message is a WASM externref (opaque JS value wrapping the string).
      abort: (message: unknown, _file: unknown, _line: number, _column: number) => {
        const msg = typeof message === 'string' ? message : String(message)
        throw new Error(`MoonBit panic: ${msg}`)
      },
    },
  }

  const { instance } = await WebAssembly.instantiate(bytes, importObject)
  const exports = instance.exports as Record<string, unknown>

  if (typeof exports['render'] !== 'function') {
    throw new Error(
      'WASM module does not export a "render" function. ' +
      'Make sure the module was built with: moon build --target wasm-gc --release',
    )
  }

  const wasmRender = exports['render'] as (input: unknown) => unknown

  return {
    render(input: string): string {
      const result = wasmRender(input)
      if (typeof result !== 'string') {
        throw new Error(`WASM render returned unexpected type: ${typeof result}`)
      }
      return result
    },
  }
}

/**
 * Loads and returns the moonmaid WASM instance.
 *
 * The instance is cached after the first call so that HMR-driven re-imports
 * reuse the already-loaded module instead of re-fetching and re-instantiating.
 *
 * @param wasmPath - Optional path/URL to the .wasm file. Defaults to the
 *   built artifact at `target/wasm-gc/release/build/lib/lib.wasm`.
 */
export async function loadMoonmaid(wasmPath?: string): Promise<MoonmaidInstance> {
  if (_cache !== null) return _cache
  const resolvedPath = wasmPath ?? defaultWasmPath()
  _cache = await instantiate(resolvedPath)
  return _cache
}

/**
 * Clears the cached WASM instance.
 *
 * Useful in tests or when you need to reload the module with a different path.
 */
export function clearCache(): void {
  _cache = null
}
