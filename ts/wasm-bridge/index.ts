/**
 * WASM bridge for the moonmaid MoonBit module.
 *
 * MoonBit wasm-gc target with `use-js-builtin-string: true` uses the
 * JS String Builtins proposal (Chrome 131+, Node.js 22+) for zero-copy
 * string passing between JS and WASM. The module is compiled and
 * instantiated with `compileStreaming` builtins option.
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
 * Instantiates the MoonBit wasm-gc module with JS String Builtins enabled.
 *
 * The `compileStreaming` / `compile` call uses the `builtins: ["js-string"]`
 * option so the engine maps WASM string operations to native JS strings.
 * This requires Node.js 22+ or Chrome 131+.
 */
async function instantiate(wasmPath: string): Promise<MoonmaidInstance> {
  const bytes = await fetchWasm(wasmPath)

  // MoonBit wasm-gc import requirements
  const importObject: WebAssembly.Imports = {
    spectest: {
      print_char: (_c: number) => { /* no-op */ },
    },
    'moonbit:ffi': {
      abort: (message: unknown, _file: unknown, _line: number, _column: number) => {
        const msg = typeof message === 'string' ? message : String(message)
        throw new Error(`MoonBit panic: ${msg}`)
      },
    },
  }

  // Compile with JS String Builtins enabled (Node.js 22+, Chrome 131+)
  // TypeScript doesn't yet have types for the builtins option, so we cast.
  const compileOptions = {
    builtins: ['js-string'],
    importedStringConstants: '_',
  }

  const module = await (WebAssembly.compile as Function)(bytes, compileOptions) as WebAssembly.Module
  const instance = await WebAssembly.instantiate(module, importObject)
  const exports = instance.exports as Record<string, unknown>

  if (typeof exports['render'] !== 'function') {
    throw new Error(
      'WASM module does not export a "render" function. ' +
      'Build with: moon build --target wasm-gc --release',
    )
  }

  const wasmRender = exports['render'] as (input: string) => string

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
