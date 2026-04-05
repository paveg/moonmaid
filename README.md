# moonmaid

A MoonBit-powered diagram tool for algorithm and data structure visualization.

## Status

Early development — Phase 1 (static rendering for array and tree diagrams).

## Quick Start

### Build

```bash
moon build --target wasm-gc
```

### Test

```bash
moon test --target wasm-gc
```

### Usage in Astro/Starlight

```js
// astro.config.mjs
import remarkMoonmaid from 'moonmaid/remark-plugin'

export default defineConfig({
  markdown: {
    remarkPlugins: [remarkMoonmaid],
  },
})
```

Then in Markdown:

````markdown
```moonmaid
array {
  [3, 1, 4, 1, 5, 9]
  highlight(0..2, color=blue, label="sorted")
}
```
````

````markdown
```moonmaid
tree bst {
  insert(5, 3, 7, 1, 4, 6, 8)
}
```
````

## Acknowledgements

moonmaid is inspired by [Mermaid](https://mermaid.js.org/) — the pioneering tool that made text-based diagramming accessible to developers worldwide. We stand on the shoulders of the Mermaid team's work and are grateful for the ecosystem they built. moonmaid takes a different path, focusing on algorithm and data structure visualization with MoonBit, but the spirit of "diagrams from text" lives on.

We also thank [diago](https://github.com/moonbit-community/diago) for demonstrating what's possible with MoonBit in the diagram space. diago's Railway engine and Sugiyama implementation served as a valuable reference for moonmaid's layout algorithms. The MoonBit community's work on [vg](https://github.com/moonbit-community/vg) and [NetworkX](https://github.com/moonbit-community/NetworkX) also informed our design decisions.

## License

MIT
