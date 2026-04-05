# moonmaid Design Specification

> A MoonBit-powered diagram tool for algorithm and data structure visualization.

## Overview

moonmaid is a text-to-diagram tool built with MoonBit, focused on algorithm and data structure visualization for learning. It provides step-by-step animation, interactive exploration, and static SVG export — all from a concise, domain-specific DSL.

Inspired by [Mermaid](https://mermaid.js.org/), moonmaid takes a different architectural path: MoonBit compiles to lightweight WASM, enabling fast startup, dev server HMR compatibility, and a self-contained layout engine with no dependency on ELK.js.

## Goals

- **Primary**: Algorithm and data structure learning through visualization
- **Secondary**: Embeddable in Astro/Starlight documentation sites (me.wiki)
- **Non-goal (initial)**: Mermaid syntax compatibility (migration tooling deferred)

## Target Users

- Developers studying algorithms and data structures
- Technical writers documenting algorithmic concepts
- Educators creating visual teaching materials

## Architecture

### Monorepo Structure

```
moonmaid/
├── core/            ← MoonBit: parser, data structures, animation
├── renderer/        ← MoonBit: Virtual SVG Tree generation, diffing
├── wasm-bridge/     ← TypeScript: WASM↔DOM thin glue layer
├── remark-plugin/   ← TypeScript: remark-moonmaid for Markdown integration
├── web-editor/      ← TypeScript: live editor with real-time preview
└── docs/            ← Specs, ADRs, acknowledgements
```

### Companion Packages (separate MoonBit packages, published to mooncakes.io)

```
paveg/moonmaid-layout-tree/      ← Reingold-Tilford tree layout (new)
paveg/moonmaid-layout-sugiyama/  ← Sugiyama hierarchical layout (referencing diago's Railway engine)
paveg/moonmaid-layout-force/     ← Force-Directed layout (Phase 3, new)
```

These layout packages are general-purpose and independently usable, contributing to the MoonBit ecosystem beyond moonmaid.

### Data Flow

```
DSL string
  → core/parser: AST generation
  → layout packages: coordinate calculation (tree layout, Sugiyama, etc.)
  → renderer: Virtual SVG Tree generation
  → renderer: diff against previous frame
  → wasm-bridge: apply diff as batched DOM operations
```

### Package Dependencies

```
moonmaid-layout-tree ─┐
moonmaid-layout-sugiyama ─┤
                          ▼
core ← renderer ← wasm-bridge ← remark-plugin
                               ← web-editor
```

- `moonmaid-layout-*`: zero external dependencies, independently publishable
- `core`: depends on layout packages for coordinate calculation
- `renderer`: depends only on `core`
- `wasm-bridge`: consumes WASM output from `renderer`
- `remark-plugin` and `web-editor`: access WASM through `wasm-bridge`

### Technology Split

| Layer | Language | Responsibility |
|---|---|---|
| core + renderer | MoonBit (~95%+) | Parser, layout, animation state, Virtual SVG Tree, diff |
| wasm-bridge | TypeScript (<5%) | DOM patch application, browser event forwarding, requestAnimationFrame loop |
| remark-plugin | TypeScript | remark integration, WASM caching for HMR |
| web-editor | TypeScript | CodeMirror integration, playback UI |

### Virtual SVG Tree Pattern

MoonBit generates a declarative SVG tree (virtual DOM). A thin TypeScript layer diffs and patches the real DOM. This minimizes WASM↔JS boundary crossings (one batch per frame instead of hundreds of individual DOM calls).

```
MoonBit (WASM):
  Computation, layout, animation state → Virtual SVG Tree → diff

TypeScript (thin glue):
  Receive diff → batch DOM patch → forward browser events to WASM
```

## Supported Diagram Types

| Diagram | Use Cases |
|---|---|
| **Graph (directed/undirected)** | BFS, DFS, shortest path, topological sort |
| **Tree** | BST, AVL, heap, trie, segment tree |
| **Array / Linear structures** | Array, linked list, stack, queue, deque |
| **Hash table** | Bucket visualization, collision handling |
| **State transition diagram** | Automata, algorithm state transitions |
| **Flowchart** | Algorithm logic flow |

## DSL Design

### Design Principles

- Brace-based syntax (aligned with MoonBit/Rust/Go style)
- Attributes in `[key=value]` square brackets (more readable than Mermaid's `-->|label|`)
- `@animate` is opt-in (static diagrams are the default)
- DSL compiles to MoonBit API calls internally; advanced users can use the API directly

### Syntax Examples

**Graph (directed/undirected):**

```
graph directed {
  A -> B [weight=3]
  B -> C
  A -> C [weight=1, style=dashed]
}
```

**Tree:**

```
tree bst {
  insert(5, 3, 7, 1, 4, 6, 8)
}
```

```
tree heap(min) {
  push(10, 4, 15, 1, 7)
}
```

**Array / Linear structures:**

```
array {
  [3, 1, 4, 1, 5, 9, 2, 6]
  highlight(0..2, color=blue, label="sorted")
  highlight(3, color=red, label="current")
}
```

```
linkedlist {
  1 -> 3 -> 5 -> 7
  pointer(head, 0)
  pointer(current, 2)
}
```

**Hash table:**

```
hashtable(size=8) {
  insert("apple", "banana", "cherry", "date")
  hash: fnv1a
}
```

**State transition diagram:**

```
state {
  idle -> loading [on="fetch"]
  loading -> success [on="resolve"]
  loading -> error [on="reject"]
  error -> loading [on="retry"]

  initial: idle
  accepting: success
}
```

**Flowchart:**

```
flow {
  start("Begin")
  if("n <= 1") {
    return("n")
  } else {
    step("fib(n-1) + fib(n-2)")
    return("result")
  }
}
```

### Animation Directives

```
graph directed @animate {
  A -> B -> C -> D
  A -> C

  step: visit(A)
  step: visit(B), traverse(A -> B)
  step: visit(C), traverse(B -> C)
  step: visit(D), traverse(C -> D)
}
```

Diagrams with `@animate` render in step-execution mode with playback controls. Without `@animate`, only static SVG is produced.

### DSL → API Relationship

```
// DSL: tree bst { insert(5, 3, 7) }
// → Parser converts to API calls:
let tree = BST::new()
tree.insert(5)  // → AnimationStep recorded
tree.insert(3)  // → AnimationStep recorded
tree.insert(7)  // → AnimationStep recorded
```

## Layout Engine

### Ecosystem Reuse Strategy

Analysis of existing MoonBit libraries informed the layout strategy:

| Library | Assessment | Decision |
|---|---|---|
| **[diago](https://github.com/moonbit-community/diago)** (v0.2.4) | Production-ready. Sugiyama self-implementation in Railway engine (~130k LOC). Trait-separated layout engine. SVG renderer is D2-agnostic. | **Reference for Sugiyama**. Extract and re-implement as independent package. |
| **[vg](https://github.com/moonbit-community/vg)** (v0.1.3) | Experimental. SVG generation works but no Virtual SVG Tree diffing. | **Not used**. moonmaid needs diffing-capable SVG generation. |
| **[NetworkX](https://github.com/moonbit-community/NetworkX)** (v0.1.4) | Experimental. Basic graph + DFS/BFS/Dijkstra. No tree structures. | **Not used**. moonmaid's graph model needs animation-aware extensions. |

### Companion Layout Packages

Layout algorithms are published as independent MoonBit packages to mooncakes.io, contributing to the MoonBit ecosystem.

| Package | Algorithm | Source |
|---|---|---|
| `paveg/moonmaid-layout-tree` | Reingold-Tilford | **New implementation** (no existing MoonBit implementation found) |
| `paveg/moonmaid-layout-sugiyama` | Sugiyama (layered) | **Re-implementation referencing diago's Railway engine** |
| `paveg/moonmaid-layout-force` | Force-Directed | **New implementation** (Phase 3) |

Each package:
- Has zero external dependencies (pure MoonBit)
- Implements the shared `Layout` trait
- Is independently testable and publishable
- Can be used outside moonmaid

### Layout Algorithms by Diagram Type

| Diagram Type | Algorithm | Package |
|---|---|---|
| **Tree** | Reingold-Tilford | `moonmaid-layout-tree` |
| **Graph (directed)** | Sugiyama (layered) | `moonmaid-layout-sugiyama` |
| **Graph (undirected)** | Force-Directed | `moonmaid-layout-force` |
| **Array / Linear** | Fixed Grid | `core` (trivial, no separate package) |
| **Hash table** | Bucket Column + Chain | `core` (trivial, no separate package) |
| **State transition** | Sugiyama or Force-Directed | Auto-selected based on state count |
| **Flowchart** | Sugiyama | `moonmaid-layout-sugiyama` |

### Implementation Phases

```
Phase 1: Fixed Grid (array, core) + Reingold-Tilford (moonmaid-layout-tree)
  → Simplest to implement and test. Immediately useful for learning.

Phase 2: Sugiyama (moonmaid-layout-sugiyama)
  → Reference diago's Railway engine for the 5-step implementation:
    1. Cycle removal (MFAS)
    2. Layer assignment
    3. Crossing minimization (barycenter / median heuristic)
    4. Coordinate assignment
    5. Post-processing
  → Covers: directed graphs, flowcharts, state transition diagrams

Phase 3: Force-Directed (moonmaid-layout-force)
  → Good synergy with animation but heavier implementation.
  → Phase 1-2 covers sufficient use cases first.
```

### Layout Interface

Shared across all layout packages:

```moonbit
trait Layout {
  layout(self: Self, model: DiagramModel, config: LayoutConfig) -> PositionedGraph
}

struct LayoutConfig {
  width: Double
  height: Double
  node_spacing: Double
  level_spacing: Double
  padding: Double
}

struct PositionedGraph {
  nodes: Array[PositionedNode]
  edges: Array[PositionedEdge]
  bounds: BoundingBox
}
```

### ELK.js Problem Resolution

| ELK.js Problem | moonmaid Solution |
|---|---|
| Large WASM binary (~2MB) | Lightweight MoonBit WASM (target: <200KB) |
| Initialization takes hundreds of ms | WASM instance caching + instant startup |
| No HMR in dev server | remark plugin caches WASM module in-process; file changes trigger re-layout only (no re-initialization) |
| Java-derived API design | Native MoonBit API |

## Animation System

### Animation State Machine

```
                    play
  ┌───────┐    ──────────▶    ┌─────────┐
  │ Idle  │                   │ Playing │◀─┐
  └───┬───┘    ◀──────────    └────┬────┘  │
      │          pause             │       │ next_step
      │                            ▼       │ (auto)
      │                      ┌─────────┐   │
      │         step         │ Paused  │───┘
      └─────────────────────▶│ AtStep  │
                             └────┬────┘
                                  │ step (manual)
                                  └───▶ next step
```

### Animation Data Model

```moonbit
enum AnimationAction {
  Highlight(node_id: String, color: Color)
  Unhighlight(node_id: String)
  TraverseEdge(from: String, to: String, color: Color)
  AddNode(node_id: String, position: Position)
  RemoveNode(node_id: String)
  SwapNodes(a: String, b: String)
  UpdateLabel(node_id: String, text: String)
  CompareNodes(a: String, b: String)
  Annotate(text: String, position: Position)
}

struct AnimationStep {
  actions: Array[AnimationAction]
  description: String
  duration_ms: Int
}

struct AnimationTimeline {
  steps: Array[AnimationStep]
  current: Int
  state: PlaybackState  // Idle | Playing | Paused
}
```

### Animation Example: BST Insert

```
tree bst @animate { insert(5, 3, 7, 1) }
```

Expands to:

```
Step 0: "Insert 5 (root)"       → AddNode("5", root_position)
Step 1: "Insert 3: compare 5"   → Highlight("5", blue), CompareNodes("3", "5")
Step 2: "3 < 5, go left"        → TraverseEdge("5", "left"), Annotate("3 < 5")
Step 3: "Insert 3 as left of 5" → AddNode("3", left_of_5), Unhighlight("5")
Step 4: "Insert 7: compare 5"   → Highlight("5", blue), CompareNodes("7", "5")
...
```

### Playback Controls

```
 ◁◁  ◁  ▷/⏸  ▷  ▷▷   Step 3/12   [========----]  1x ▾
 Insert 3: compare with 5
```

- Skip to start/end
- Step forward/backward (manual)
- Auto-play with speed control (0.5x, 1x, 2x, 4x)
- Progress bar with click-to-seek
- Step description display

### Static vs Animated Mode

Diagrams without `@animate` do not generate an `AnimationTimeline`. The renderer draws only the final state with no playback controls. This keeps static SVG output in remark plugin lightweight.

## UI Design

### Design Principles

- Minimal and clean — blends naturally into GitHub Flavored Markdown
- Auto-follows `prefers-color-scheme` for light/dark themes
- Uses GitHub's system font stack
- Does not visually compete with document content

### Color Palette

**Light Mode (GFM-aligned):**

| Role | Color | Usage |
|---|---|---|
| Background | `#ffffff` | Diagram background |
| Node fill | `#f6f8fa` | GitHub code block background |
| Node stroke | `#d1d9e0` | Border |
| Text | `#1f2328` | Labels |
| Edge | `#656d76` | Connections |
| Highlight | `#0969da` | Active/current node (GitHub blue) |
| Visited | `#8250df` | Already visited (GitHub purple) |
| Comparing | `#bf8700` | Under comparison (GitHub yellow) |
| Error/Delete | `#cf222e` | Error state (GitHub red) |
| Success/Insert | `#1a7f37` | Successful operation (GitHub green) |

**Dark Mode:** Corresponding GitHub dark theme colors (`#0d1117` background, `#161b22` node fill, etc.)

### Typography

- Node labels: GitHub system font stack, 14px
- Monospace: `ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace`
- Annotations: 12px, muted color

### Node Shapes

- Default: rounded rectangle (rx=6), padding 8px 12px
- Array element: square (40x40), index label below
- Highlighted: thicker stroke (3px) + subtle shadow
- State: larger border-radius (rx=16)

### Edge Styles

- Default: 1.5px solid, arrow marker
- Traversing: 2px, highlight color, dash-offset animation
- Weighted: label at midpoint with background
- Self-loop: arc above node

### Animation Transitions

- Node color change: 300ms ease
- Edge traversal: dash-offset 600ms linear
- Node appearance: fade-in 300ms
- Node swap: position 400ms ease-in-out

### remark Plugin Embedding

- SVG wrapped in `<figure>` tag
- Width follows container (`width="100%"` + viewBox)
- 16px vertical margin (GFM block element spacing)
- Playback controls shown only for `@animate` diagrams

## Security

### Threat Model

| Threat | Severity | Mitigation |
|---|---|---|
| SVG XSS | CRITICAL | Escape all text nodes and attribute values (`<`, `>`, `"`, `'`, `&`). Never generate `<script>`, `<foreignObject>`, or `on*` event handler attributes. Enforced at renderer level. |
| Resource exhaustion | IMPORTANT | Node count limit (default: 1024), array size limit (default: 256), hash table size limit (default: 64), input size limit at parser level. Explicit error on limit exceeded (no silent truncation). |
| ReDoS | LOW | Hand-written recursive descent parser in MoonBit (no regex). Low risk by design. |
| WASM sandbox escape | LOW | WASM runs in browser sandbox. No file system access. |

### Configurable Limits

```typescript
// remark-plugin configuration
remarkMoonmaid({
  maxNodes: 2048,
  maxArraySize: 512,
  maxHashTableSize: 128,
})
```

Limit overrides are only available in trusted contexts (remark plugin config, not DSL).

## remark Plugin Integration

### Usage

```javascript
// astro.config.mjs
import remarkMoonmaid from 'remark-moonmaid'

export default defineConfig({
  markdown: {
    remarkPlugins: [remarkMath, remarkMoonmaid],
    rehypePlugins: [rehypeKatex],
  },
})
```

### HMR Support

```
Dev server startup:
  1. Load WASM module (once)
  2. Cache in-process

On file change:
  1. Re-parse only changed moonmaid blocks
  2. Re-layout using cached WASM instance
  3. Replace SVG output
  → No WASM re-initialization, fast HMR
```

## Distribution (Priority Order)

1. **remark/rehype plugin** — Direct me.wiki integration. Write `moonmaid` code blocks in Markdown.
2. **Web editor** — Real-time preview for DSL authoring. WASM runs directly in browser.
3. **npm package (core library)** — Foundation for the above. Embeddable in other projects.
4. **Future**: CLI, GitHub Action (when needed)

## Testing Strategy

| Layer | Method | Focus |
|---|---|---|
| core/parser | MoonBit unit tests | DSL→AST accuracy, error cases |
| core/layout | MoonBit unit tests + snapshots | Coordinate calculation, known layout comparisons |
| core/animation | MoonBit unit tests | Timeline generation accuracy |
| renderer | Snapshot tests | Virtual SVG Tree output comparison |
| wasm-bridge | Vitest | WASM↔TS data passing |
| remark-plugin | Vitest + snapshots | Markdown→SVG integration tests |
| Security | Fuzz tests + dedicated tests | XSS inputs, resource limit enforcement |

Mermaid's test cases serve as reference for coverage targets (re-designed for moonmaid's syntax, not ported).

## Acknowledgements

moonmaid is inspired by [Mermaid](https://mermaid.js.org/) — the pioneering tool that made text-based diagramming accessible to developers worldwide. We stand on the shoulders of the Mermaid team's work and are grateful for the ecosystem they built. moonmaid takes a different path, focusing on algorithm and data structure visualization with MoonBit, but the spirit of "diagrams from text" lives on.

We also thank [diago](https://github.com/moonbit-community/diago) for demonstrating what's possible with MoonBit in the diagram space. diago's Railway engine and Sugiyama implementation served as a valuable reference for moonmaid's layout algorithms. The MoonBit community's work on [vg](https://github.com/moonbit-community/vg) and [NetworkX](https://github.com/moonbit-community/NetworkX) also informed our design decisions.
