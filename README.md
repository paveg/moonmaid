# moonmaid

A MoonBit-powered diagram tool for algorithm and data structure visualization.

## Installation

### Prerequisites

- [MoonBit](https://www.moonbitlang.com/) toolchain (v0.1.20260309+)
- Node.js 22+ (for WASM JS String Builtins support)
- pnpm (for TypeScript dependencies)

### Build from source

```bash
git clone https://github.com/paveg/moonmaid.git
cd moonmaid

# Build WASM
moon build --target wasm-gc --release

# Build TypeScript (remark plugin)
cd ts && pnpm install && pnpm build && cd ..
```

### Use in Astro/Starlight

1. Copy the WASM binary to your project:

```bash
cp _build/wasm-gc/release/build/lib/lib.wasm /path/to/your-project/src/moonmaid.wasm
```

2. Create a remark plugin wrapper in your project:

```typescript
// src/plugins/remark-moonmaid.ts
import { readFile } from 'node:fs/promises'
import type { Plugin } from 'unified'
import type { Root, Code } from 'mdast'
import { visit } from 'unist-util-visit'

let instance: any = null

async function loadWasm(wasmPath: string) {
  if (instance) return instance
  const bytes = await readFile(wasmPath)
  const module = await WebAssembly.compile(bytes, {
    builtins: ['js-string'],
    importedStringConstants: '_',
  } as any)
  const inst = await WebAssembly.instantiate(module, {
    spectest: { print_char: () => {} },
    'moonbit:ffi': {
      abort: (msg: unknown) => { throw new Error(`moonmaid panic: ${msg}`) },
    },
  })
  instance = inst.exports
  return instance
}

const remarkMoonmaid: Plugin<[{ wasmPath: string }], Root> = ({ wasmPath }) => {
  return async (tree: Root) => {
    const blocks: Code[] = []
    visit(tree, 'code', (node: Code) => {
      if (node.lang === 'moonmaid') blocks.push(node)
    })
    if (blocks.length === 0) return

    const wasm = await loadWasm(wasmPath)
    for (const node of blocks) {
      const svg = wasm.render(node.value)
      const html = node as unknown as { type: string; value: string }
      html.type = 'html'
      html.value = `<figure class="moonmaid">${svg}</figure>`
    }
  }
}

export default remarkMoonmaid
```

3. Add to your Astro config:

```javascript
// astro.config.mjs
import remarkMoonmaid from './src/plugins/remark-moonmaid.ts'

export default defineConfig({
  markdown: {
    remarkPlugins: [
      [remarkMoonmaid, { wasmPath: './src/moonmaid.wasm' }],
    ],
  },
})
```

4. Use in Markdown:

````markdown
```moonmaid
tree bst {
  insert(5, 3, 7, 1, 4, 6, 8)
}
```

```moonmaid
array {
  [3, 1, 4, 1, 5, 9]
  highlight(0..2, color=blue, label="sorted")
}
```

```moonmaid
flowchart TD {
  A["Start"] -> B{"Condition?"}
  B ->|Yes| C["Process"]
  B ->|No| D["Error"]
  C -> E["Done"]
}
```
````

### Troubleshooting

**WASM cache issues**: If changes don't take effect after rebuilding, clear your build cache:

```bash
# Astro/Starlight
rm -rf .astro dist node_modules/.cache

# Rebuild moonmaid WASM
cd /path/to/moonmaid
moon build --target wasm-gc --release
```

**Node.js version**: WASM JS String Builtins requires Node.js 22+. Check with `node --version`.

## Supported DSL

| DSL | Output |
|---|---|
| `array { [1,2,3] highlight(...) }` | Static SVG |
| `array @animate { [3,1,4] sort: bubble/insertion/selection/quick }` | Animated HTML |
| `tree bst { insert(5,3,7) }` | Static SVG |
| `tree bst @animate { insert(5,3,7) }` | Animated HTML |
| `graph directed { A -> B [weight=3] }` | Static SVG |
| `flowchart TD { A["Label"] -> B{"Cond?"} ->|Yes| C }` | Static SVG |
| `flowchart LR { A -> B -> C }` | Static SVG |

## Development

```bash
# Run tests
moon test --target wasm-gc

# Format
moon fmt

# Build
moon build --target wasm-gc --release
```

## Acknowledgements

moonmaid is inspired by [Mermaid](https://mermaid.js.org/) — the pioneering tool that made text-based diagramming accessible to developers worldwide. We stand on the shoulders of the Mermaid team's work and are grateful for the ecosystem they built. moonmaid takes a different path, focusing on algorithm and data structure visualization with MoonBit, but the spirit of "diagrams from text" lives on.

We also thank [diago](https://github.com/moonbit-community/diago) for demonstrating what's possible with MoonBit in the diagram space. diago's Railway engine and Sugiyama implementation served as a valuable reference for moonmaid's layout algorithms. The MoonBit community's work on [vg](https://github.com/moonbit-community/vg) and [NetworkX](https://github.com/moonbit-community/NetworkX) also informed our design decisions.

## License

MIT
