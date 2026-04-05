# Phase 2a: Graph DSL + Sugiyama Layout Design Specification

> Directed graph visualization with hierarchical (Sugiyama) layout for moonmaid.

## Overview

Add `graph directed { ... }` DSL to moonmaid with Sugiyama hierarchical layout. Supports weighted edges, edge styles, and node labels. The Sugiyama layout is implemented as an independent package (`src/layout/sugiyama/`) designed for future extraction to mooncakes.io.

## DSL Syntax

```
graph directed {
  A("Start") -> B("Process") [weight=3]
  B -> C
  A -> C [style=dashed]
}
```

### Elements

- **Direction**: `directed` (required). `undirected` is parsed but returns an error ("undirected layout not yet supported") until Phase 3.
- **Node**: Identifier or identifier with label. `A` uses "A" as both ID and display label. `A("Start")` uses "A" as ID and "Start" as display label.
- **Edge**: `A -> B` with optional attributes in `[key=value, ...]`.
- **Edge attributes**: `weight` (integer), `style` ("solid" | "dashed" | "dotted"). Defaults: no weight, solid style.
- **Node collection**: Nodes are implicitly defined by their appearance in edges. No separate node declaration needed.
- **`@animate`**: Parsed but returns error in Phase 2a ("graph animation not yet supported"). Phase 2b adds BFS/DFS/Dijkstra.

## Types

```moonbit
pub(all) enum GraphDirection { Directed; Undirected } derive(Show, Eq)

pub(all) struct GraphNodeDef {
  id : String
  label : String
} derive(Show, Eq)

pub(all) struct GraphEdgeDef {
  from : String
  to : String
  weight : Int?
  style : String  // "solid" | "dashed" | "dotted"
} derive(Show, Eq)

pub(all) struct GraphDef {
  direction : GraphDirection
  nodes : Array[GraphNodeDef]
  edges : Array[GraphEdgeDef]
} derive(Show, Eq)
```

Extend `Diagram` enum:
```moonbit
GraphDiagram(GraphDef)
```

Extend `Limits` struct:
```moonbit
max_edges : Int  // default: 4096
```

## Parser Changes

### New Tokens

`TkGraph`, `TkDirected`, `TkUndirected`, `TkStyle`

Reuse existing: `Arrow` (->), `LBracket`/`RBracket` ([]), `Eq`, `Comma`, `Ident`, `IntLit`, `StringLit`, `LBrace`/`RBrace`, `At`/`TkAnimate`

### Parse Algorithm

```
graph_diagram := "graph" direction "{" edge_list "}"
direction     := "directed" | "undirected"
edge_list     := (edge)*
edge          := node_ref "->" node_ref edge_attrs?
node_ref      := IDENT | IDENT "(" STRING ")"
edge_attrs    := "[" attr ("," attr)* "]"
attr          := "weight" "=" INT | "style" "=" IDENT
```

Nodes are collected from edge endpoints. If a node appears with a label in one edge and without in another, the labeled version wins.

## Sugiyama Layout Algorithm

### Package Structure

```
src/layout/sugiyama/
├── moon.pkg              # imports: paveg/moonmaid/types
├── sugiyama.mbt          # Public API: layout()
├── cycle_removal.mbt     # Phase 1: DFS-based cycle removal
├── layer_assignment.mbt  # Phase 2: Longest-path layering
├── crossing_min.mbt      # Phase 3: Barycenter crossing minimization
├── coordinate.mbt        # Phase 4: Coordinate assignment
└── *_test.mbt            # Tests for each phase
```

### Phase 1: Cycle Removal

DFS-based back-edge detection. Back edges are temporarily reversed. After layout, reversed edges are restored and drawn with reversed arrow direction.

Input: `GraphDef`
Output: `AcyclicGraph` (same structure, with reversed edges tracked)

### Phase 2: Layer Assignment

Longest-path algorithm:
1. Find all sink nodes (no outgoing edges in DAG)
2. Assign layer 0 to sinks
3. For each remaining node, layer = max(layer of successors) + 1
4. Invert layers so sources are at top (layer 0)

Long edges (spanning multiple layers) get dummy nodes inserted.

Input: `AcyclicGraph`
Output: `LayeredGraph` (nodes assigned to layers, dummy nodes inserted)

### Phase 3: Crossing Minimization

Barycenter heuristic:
1. Fix layer 0 order
2. For each subsequent layer, compute barycenter (average position of neighbors in previous layer) for each node
3. Sort by barycenter
4. Repeat top-down and bottom-up for 4 iterations (configurable)

Input: `LayeredGraph`
Output: `OrderedGraph` (node order within each layer finalized)

### Phase 4: Coordinate Assignment

1. y-coordinate: `layer * level_spacing + padding`
2. x-coordinate: position within layer * node_spacing, centered around midpoint
3. Node dimensions: same as tree nodes (56x40, rx=14)
4. Dummy nodes are invisible (no rect/label), used only for edge routing

Input: `OrderedGraph`
Output: `PositionedGraph` (existing type)

### Phase 5: Edge Routing

Edges that pass through dummy nodes become polylines through the dummy positions. Direct edges (adjacent layers) are straight lines. Self-loops rendered as arcs above the node.

### Public API

```moonbit
pub fn layout(def : @types.GraphDef, config : @types.LayoutConfig) -> @types.PositionedGraph raise @types.MoonmaidError
```

Raises error for `Undirected` direction.

## Renderer

New file: `src/renderer/render_graph.mbt`

```moonbit
pub fn render_graph(graph : @types.PositionedGraph, def : @types.GraphDef) -> SvgNode
```

- Nodes: rounded rect (rx=14), shadow, label centered
- Edges: polyline with arrowhead marker (directed only)
- Weight labels: small text at edge midpoint with white background rect
- Edge styles: `stroke-dasharray="6,4"` for dashed, `stroke-dasharray="2,4"` for dotted
- Uses eraser.io theme (Tailwind pastel colors)

## Security

- Node count limit: `max_nodes` (1024)
- Edge count limit: `max_edges` (4096) — new field in Limits
- Node ID/label: `escape_xml` applied
- Input size: 64KB limit (existing)
- Cycle removal: DFS with visited set prevents infinite loops on cyclic input

## Testing Strategy

| Component | Tests |
|---|---|
| Lexer: graph tokens | 2-3 |
| Parser: graph DSL | 6-8 (happy path + boundary + error) |
| Cycle removal | 3-4 (DAG, single cycle, multiple cycles, self-loop) |
| Layer assignment | 3-4 (linear chain, diamond, wide graph) |
| Crossing minimization | 2-3 (known crossing count reduction) |
| Coordinate assignment | 2-3 (positions within bounds, spacing) |
| Full Sugiyama layout | 3-4 (integration: DAG, cyclic, single node, linear) |
| Renderer | 3-4 (SVG structure, weight labels, dashed edges) |
| E2E | 4-5 (full pipeline, error cases, boundary) |

## Flowchart DSL (Extension)

### Syntax

```
flowchart TD {
  A["Process data"] -> B{"Valid?"}
  B ->|Yes| C["Save"]
  B ->|No| D["Error"]
}
```

### Direction

- `TD` — top-down (default, same as `graph directed` layout)
- `LR` — left-right (transpose: x↔y in coordinate assignment)

### Node Shapes

Encoded in syntax brackets:
- `A["label"]` — rectangle (default processing step)
- `A{"label"}` — diamond (decision/condition)
- `A("label")` — rounded rectangle (start/end/terminal)
- `A` — rectangle with ID as label (shorthand)

### Edge Labels

`->|label|` attaches a label to the edge. Stored as `GraphEdgeDef.label` (extend the existing `label` field on `PositionedEdge`).

### Types

```moonbit
pub(all) enum NodeShape { Rect; Diamond; Rounded } derive(Show, Eq)
```

`GraphNodeDef` extended with `shape : NodeShape` field.

`GraphDef` extended with `is_flowchart : Bool` and `direction : GraphDirection` generalized to include LR layout.

Or cleaner: extend `GraphDirection` enum:
```moonbit
pub(all) enum GraphDirection { Directed; Undirected; FlowTD; FlowLR } derive(Show, Eq)
```

### Renderer Changes

- Diamond nodes: rotated square SVG `<polygon>` with 4 points
- Rounded nodes: `rx=20` (more rounded than default rx=14)
- Edge labels: small text at midpoint with white background rect (same as weight labels)
- LR direction: transpose all coordinates (swap x/y) after Sugiyama

### Parser Changes

New tokens: `TkFlowchart`, `TkTD`, `TkLR`
New syntax: `->|label|` edge labels, `{}` / `[]` / `()` node shape brackets

### Priority

This is the highest-priority feature for me.wiki migration (56 mermaid flowchart blocks).

## Acknowledgements

Sugiyama implementation references [diago](https://github.com/moonbit-community/diago)'s Railway engine for algorithmic approach (MFAS cycle removal, barycenter crossing minimization).
