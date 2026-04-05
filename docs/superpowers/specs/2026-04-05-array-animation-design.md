# Array Animation Design Specification

> Sort algorithm visualization for moonmaid's array diagrams.

## Overview

Extend moonmaid's `array` DSL with `@animate` support for visualizing sort algorithms. Reuse the existing animation infrastructure (AnimationAction, AnimationTimeline, playback controls).

## DSL Syntax

```
array @animate {
  [3, 1, 4, 1, 5, 9, 2, 6]
  sort: bubble
}
```

Supported `sort:` values: `bubble`, `insertion`, `selection`, `quick`

## Types

```moonbit
pub(all) enum SortAlgorithm {
  Bubble
  Insertion
  Selection
  Quick
} derive(Show, Eq)

pub(all) struct ArrayAnimDef {
  elements : Array[Int]
  algorithm : SortAlgorithm
} derive(Show, Eq)

// Extend Diagram enum:
AnimatedArrayDiagram(ArrayAnimDef)
```

## Parser Changes

- Add tokens: `TkSort`, `TkBubble`, `TkInsertion`, `TkSelection`, `TkQuick`
- Parse `array @animate { [...] sort: <algorithm> }`
- `array @animate` without `sort:` → error

## Animation Generation

Each sort algorithm generates steps using existing AnimationAction variants:

| Action | Usage |
|---|---|
| `Highlight(node_id, "yellow")` | Mark pivot (quicksort) |
| `Highlight(node_id, "blue")` | Current comparison element |
| `Highlight(node_id, "green")` | Element in sorted position |
| `CompareNodes(a, b)` | Comparing two elements |
| `SwapNodes(a, b)` | Swapping two elements |
| `Unhighlight(node_id)` | Clear highlight |
| `Annotate(text, x, y)` | Partition range, explanation |

Node IDs follow grid layout convention: `elem_0`, `elem_1`, etc.

### Algorithm Step Counts (approximate for n elements)

| Algorithm | Steps | Complexity |
|---|---|---|
| Bubble sort | ~3n² (compare + swap + unhighlight per pair) | O(n²) |
| Insertion sort | ~2n² | O(n²) |
| Selection sort | ~2n² | O(n²) |
| Quick sort | ~2n log n average | O(n log n) avg |

## Renderer

Reuse `render_animated(graph, timeline)`. The grid layout produces PositionedGraph with `elem_*` node IDs, which the animated renderer already wraps with `data-node-id` attributes. No renderer changes needed.

## Security

- Array size limit (256) already enforced by parser
- Sort algorithm name is an enum — no injection risk
- Input size limit (64KB) already enforced

## Acknowledgements

No new external dependencies.
