# Phase 2a: Graph DSL + Sugiyama Layout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `graph directed { A -> B }` DSL with Sugiyama hierarchical layout for directed graph visualization.

**Architecture:** Extend parser with graph DSL tokens and grammar. Implement 5-phase Sugiyama as independent package (`src/layout/sugiyama/`). Add graph renderer following existing render_tree pattern. Integrate into public API.

**Tech Stack:** MoonBit, existing renderer/parser/types packages, eraser.io theme

**Spec:** `docs/superpowers/specs/2026-04-05-graph-sugiyama-design.md`

**Prerequisite:** 135 MoonBit tests passing on main

---

## File Structure

```
src/
├── types/
│   └── types.mbt              # MODIFY: add GraphDirection, GraphNodeDef, GraphEdgeDef, GraphDef, max_edges
├── parser/
│   ├── token.mbt              # MODIFY: add TkGraph, TkDirected, TkUndirected, TkStyle
│   ├── lexer.mbt              # MODIFY: add keywords
│   ├── parser.mbt             # MODIFY: add TkGraph branch, parse_graph_body
│   ├── lexer_test.mbt         # MODIFY
│   └── parser_test.mbt        # MODIFY
├── layout/
│   └── sugiyama/
│       ├── moon.pkg            # NEW: imports types only
│       ├── sugiyama.mbt        # NEW: public layout() API + orchestration
│       ├── cycle_removal.mbt   # NEW: DFS back-edge reversal
│       ├── layer_assignment.mbt # NEW: longest-path layering
│       ├── crossing_min.mbt    # NEW: barycenter heuristic
│       ├── coordinate.mbt      # NEW: x/y coordinate assignment
│       ├── sugiyama_test.mbt   # NEW: integration tests
│       ├── cycle_test.mbt      # NEW
│       ├── layer_test.mbt      # NEW
│       ├── crossing_test.mbt   # NEW
│       └── coordinate_test.mbt # NEW
├── renderer/
│   ├── render_graph.mbt       # NEW: graph diagram → SvgNode
│   └── render_graph_test.mbt  # NEW
├── lib/
│   ├── moonmaid.mbt           # MODIFY: add GraphDiagram case
│   └── moonmaid_test.mbt      # MODIFY: add e2e tests
```

---

### Task 1: Graph Types

**Files:**
- Modify: `src/types/types.mbt`
- Modify: `src/types/types_test.mbt`

- [ ] **Step 1: Write failing tests**

Append to `src/types/types_test.mbt`:
```moonbit
test "construct GraphDef" {
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [
      { id: "A", label: "Start" },
      { id: "B", label: "B" },
    ],
    edges: [
      { from: "A", to: "B", weight: Some(3), style: "solid" },
    ],
  }
  assert_eq(def.edges.length(), 1)
  assert_eq(def.nodes[0].label, "Start")
}

test "GraphEdgeDef optional weight" {
  let edge : @types.GraphEdgeDef = { from: "A", to: "B", weight: None, style: "dashed" }
  assert_eq(edge.weight, None)
  assert_eq(edge.style, "dashed")
}
```

- [ ] **Step 2: Add types to types.mbt**

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
  style : String
} derive(Show, Eq)

pub(all) struct GraphDef {
  direction : GraphDirection
  nodes : Array[GraphNodeDef]
  edges : Array[GraphEdgeDef]
} derive(Show, Eq)
```

Add `GraphDiagram(GraphDef)` to Diagram enum.

Add `max_edges : Int` to Limits struct (default: 4096). Update `Limits::default()`.

Fix `render_result` in lib/moonmaid.mbt to handle `GraphDiagram` (temporary: return error SVG "Graph rendering not yet connected").

- [ ] **Step 3: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc && moon fmt
git commit -m "feat: add graph types (GraphDirection, GraphNodeDef, GraphEdgeDef, GraphDef)"
```

---

### Task 2: Lexer — Graph Tokens

**Files:**
- Modify: `src/parser/token.mbt`, `src/parser/lexer.mbt`, `src/parser/lexer_test.mbt`

- [ ] **Step 1: Write failing tests**

Append to `src/parser/lexer_test.mbt`:
```moonbit
test "lex graph directed" {
  let input = "graph directed { A -> B }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkGraph, @parser.Token::TkDirected, @parser.Token::LBrace,
    @parser.Token::Ident("A"), @parser.Token::Arrow, @parser.Token::Ident("B"),
    @parser.Token::RBrace, @parser.Token::Eof,
  ])
}

test "lex graph with weight and style" {
  let input = "graph directed { A -> B [weight=3, style=dashed] }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_true(kinds.contains(@parser.Token::TkGraph))
  assert_true(kinds.contains(@parser.Token::TkDirected))
  assert_true(kinds.contains(@parser.Token::IntLit(3)))
  assert_true(kinds.contains(@parser.Token::Ident("dashed")))
}

test "lex graph undirected keyword" {
  let tokens = @parser.lex("graph undirected { }")
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds[1], @parser.Token::TkUndirected)
}
```

- [ ] **Step 2: Add tokens**

In token.mbt add: `TkGraph`, `TkDirected`, `TkUndirected`

In lexer.mbt keyword_token add:
```
"graph" => Some(TkGraph)
"directed" => Some(TkDirected)
"undirected" => Some(TkUndirected)
```

NOTE: `style` is parsed as `Ident("style")`, not a dedicated token — edge attributes use `Ident` for key names. Same for `weight` — it's `Ident("weight")`. This avoids token proliferation.

- [ ] **Step 3: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/parser && moon fmt
git commit -m "feat: add graph/directed/undirected tokens to lexer"
```

---

### Task 3: Parser — Graph DSL

**Files:**
- Modify: `src/parser/parser.mbt`, `src/parser/parser_test.mbt`

- [ ] **Step 1: Write failing tests**

Append to `src/parser/parser_test.mbt`:
```moonbit
test "parse simple directed graph" {
  let input = "graph directed { A -> B }"
  match @parser.parse(input) {
    @types.Diagram::GraphDiagram(def) => {
      assert_eq(def.direction, @types.GraphDirection::Directed)
      assert_eq(def.nodes.length(), 2)
      assert_eq(def.edges.length(), 1)
      assert_eq(def.edges[0].from, "A")
      assert_eq(def.edges[0].to, "B")
    }
    _ => fail("Expected GraphDiagram")
  }
}

test "parse graph with labeled nodes" {
  let input = "graph directed { A(\"Start\") -> B(\"End\") }"
  match @parser.parse(input) {
    @types.Diagram::GraphDiagram(def) => {
      assert_eq(def.nodes.length(), 2)
      // Find node A
      let a = def.nodes.iter().find(fn(n) { n.id == "A" })
      match a {
        Some(node) => assert_eq(node.label, "Start")
        None => fail("Node A not found")
      }
    }
    _ => fail("Expected GraphDiagram")
  }
}

test "parse graph with edge attributes" {
  let input = "graph directed { A -> B [weight=5, style=dashed] }"
  match @parser.parse(input) {
    @types.Diagram::GraphDiagram(def) => {
      assert_eq(def.edges[0].weight, Some(5))
      assert_eq(def.edges[0].style, "dashed")
    }
    _ => fail("Expected GraphDiagram")
  }
}

test "parse graph multiple edges" {
  let input =
    #|graph directed {
    #|  A -> B
    #|  B -> C
    #|  A -> C [weight=2]
    #|}
  match @parser.parse(input) {
    @types.Diagram::GraphDiagram(def) => {
      assert_eq(def.edges.length(), 3)
      assert_eq(def.nodes.length(), 3)
    }
    _ => fail("Expected GraphDiagram")
  }
}

test "parse graph node labels override" {
  // Node A appears with label in first edge, without in second
  let input = "graph directed { A(\"Hello\") -> B  C -> A }"
  match @parser.parse(input) {
    @types.Diagram::GraphDiagram(def) => {
      let a = def.nodes.iter().find(fn(n) { n.id == "A" })
      match a {
        Some(node) => assert_eq(node.label, "Hello")
        None => fail("Node A not found")
      }
    }
    _ => fail("Expected GraphDiagram")
  }
}

test "parse graph undirected parses but layout errors" {
  // Parser should accept undirected syntax
  match @parser.parse("graph undirected { A -> B }") {
    @types.Diagram::GraphDiagram(def) => {
      assert_eq(def.direction, @types.GraphDirection::Undirected)
    }
    _ => fail("Expected GraphDiagram")
  }
}

test "parse graph @animate errors in Phase 2a" {
  let result : Result[Unit, Unit] = try {
    let _ = @parser.parse("graph directed @animate { A -> B }")
    Ok(())
  } catch { _ => Err(()) }
  assert_eq(result, Err(()))
}

test "parse graph empty body" {
  match @parser.parse("graph directed { }") {
    @types.Diagram::GraphDiagram(def) => {
      assert_eq(def.nodes.length(), 0)
      assert_eq(def.edges.length(), 0)
    }
    _ => fail("Expected GraphDiagram")
  }
}

test "parse graph edge default style is solid" {
  let input = "graph directed { A -> B }"
  match @parser.parse(input) {
    @types.Diagram::GraphDiagram(def) => {
      assert_eq(def.edges[0].style, "solid")
      assert_eq(def.edges[0].weight, None)
    }
    _ => fail("Expected GraphDiagram")
  }
}

test "parse graph edge count limit" {
  // Build a graph with > 4096 edges
  let buf = StringBuilder::new()
  buf.write_string("graph directed { ")
  for i = 0; i < 4097; i = i + 1 {
    buf.write_string("A\{i} -> B\{i} ")
  }
  buf.write_string("}")
  let result : Result[Unit, Unit] = try {
    let _ = @parser.parse(buf.to_string())
    Ok(())
  } catch { _ => Err(()) }
  assert_eq(result, Err(()))
}
```

- [ ] **Step 2: Implement graph parsing**

In `src/parser/parser.mbt`, add a `TkGraph` branch to `parse_diagram`:

```moonbit
TkGraph => {
  let _ = self.advance()  // consume TkGraph
  let direction = match self.advance() {
    TkDirected => @types.GraphDirection::Directed
    TkUndirected => @types.GraphDirection::Undirected
    other => raise @types.MoonmaidError::of("Expected 'directed' or 'undirected', got \{other}")
  }
  // Check for @animate (not supported in Phase 2a)
  if self.peek() == At {
    raise @types.MoonmaidError::of("@animate is not yet supported for graph diagrams")
  }
  self.parse_graph_body(direction)
}
```

Implement `parse_graph_body`:
- Read `{`
- Loop: while peek != `}`, parse an edge: `node_ref -> node_ref [attrs]?`
- `node_ref`: `Ident` optionally followed by `( StringLit )`
- Collect nodes in a Map[String, String] (id → label), labeled version wins
- Read `}`
- Check edge count limit
- Convert node map to Array[GraphNodeDef]
- Return `GraphDiagram(GraphDef)`

- [ ] **Step 3: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc && moon fmt
git commit -m "feat: implement graph DSL parser with edge attributes and node labels"
```

---

### Task 4: Sugiyama — Cycle Removal

**Files:**
- Create: `src/layout/sugiyama/moon.pkg`
- Create: `src/layout/sugiyama/cycle_removal.mbt`
- Create: `src/layout/sugiyama/cycle_test.mbt`

- [ ] **Step 1: Create package**

`src/layout/sugiyama/moon.pkg`:
```
import {
  "paveg/moonmaid/types",
}
```

- [ ] **Step 2: Write failing tests**

Create `src/layout/sugiyama/cycle_test.mbt`:
```moonbit
test "DAG has no reversed edges" {
  // A -> B -> C (no cycles)
  let nodes = ["A", "B", "C"]
  let edges = [("A", "B"), ("B", "C")]
  let result = @sugiyama.remove_cycles(nodes, edges)
  assert_eq(result.reversed.length(), 0)
  assert_eq(result.edges.length(), 2)
}

test "single cycle gets one edge reversed" {
  // A -> B -> C -> A
  let nodes = ["A", "B", "C"]
  let edges = [("A", "B"), ("B", "C"), ("C", "A")]
  let result = @sugiyama.remove_cycles(nodes, edges)
  assert_eq(result.reversed.length(), 1)
  // All edges still present (one reversed)
  assert_eq(result.edges.length(), 3)
}

test "self-loop is reversed" {
  let nodes = ["A"]
  let edges = [("A", "A")]
  let result = @sugiyama.remove_cycles(nodes, edges)
  assert_eq(result.reversed.length(), 1)
}

test "empty graph" {
  let nodes : Array[String] = []
  let edges : Array[(String, String)] = []
  let result = @sugiyama.remove_cycles(nodes, edges)
  assert_eq(result.edges.length(), 0)
}

test "multiple independent cycles" {
  // A -> B -> A, C -> D -> C
  let nodes = ["A", "B", "C", "D"]
  let edges = [("A", "B"), ("B", "A"), ("C", "D"), ("D", "C")]
  let result = @sugiyama.remove_cycles(nodes, edges)
  assert_eq(result.reversed.length(), 2)
}
```

- [ ] **Step 3: Implement cycle removal**

Create `src/layout/sugiyama/cycle_removal.mbt`:

DFS-based approach:
1. Maintain visited (0=unvisited, 1=in-stack, 2=done) per node
2. When a back edge (to node in-stack) is found, reverse it
3. Track reversed edge indices

```moonbit
pub(all) struct AcyclicResult {
  edges : Array[(String, String)]
  reversed : Array[Int]  // indices of reversed edges
} derive(Show, Eq)

pub fn remove_cycles(
  nodes : Array[String],
  edges : Array[(String, String)],
) -> AcyclicResult
```

- [ ] **Step 4: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/layout/sugiyama && moon fmt
git commit -m "feat: implement Sugiyama cycle removal (DFS back-edge reversal)"
```

---

### Task 5: Sugiyama — Layer Assignment

**Files:**
- Create: `src/layout/sugiyama/layer_assignment.mbt`
- Create: `src/layout/sugiyama/layer_test.mbt`

- [ ] **Step 1: Write failing tests**

Create `src/layout/sugiyama/layer_test.mbt`:
```moonbit
test "linear chain A->B->C gets 3 layers" {
  let nodes = ["A", "B", "C"]
  let edges = [("A", "B"), ("B", "C")]
  let layers = @sugiyama.assign_layers(nodes, edges)
  // A=layer 0, B=layer 1, C=layer 2
  assert_eq(layers.get("A"), Some(0))
  assert_eq(layers.get("B"), Some(1))
  assert_eq(layers.get("C"), Some(2))
}

test "diamond graph" {
  // A -> B, A -> C, B -> D, C -> D
  let nodes = ["A", "B", "C", "D"]
  let edges = [("A", "B"), ("A", "C"), ("B", "D"), ("C", "D")]
  let layers = @sugiyama.assign_layers(nodes, edges)
  assert_eq(layers.get("A"), Some(0))
  // B and C should be same layer
  assert_eq(layers.get("B"), layers.get("C"))
  assert_eq(layers.get("D"), Some(2))
}

test "single node" {
  let layers = @sugiyama.assign_layers(["A"], [])
  assert_eq(layers.get("A"), Some(0))
}

test "wide graph (multiple roots)" {
  // A -> C, B -> C
  let nodes = ["A", "B", "C"]
  let edges = [("A", "C"), ("B", "C")]
  let layers = @sugiyama.assign_layers(nodes, edges)
  assert_eq(layers.get("A"), Some(0))
  assert_eq(layers.get("B"), Some(0))
  assert_eq(layers.get("C"), Some(1))
}
```

- [ ] **Step 2: Implement longest-path layer assignment**

Create `src/layout/sugiyama/layer_assignment.mbt`:

```moonbit
pub fn assign_layers(
  nodes : Array[String],
  edges : Array[(String, String)],
) -> Map[String, Int]
```

Algorithm:
1. Build adjacency list (successors per node)
2. Find source nodes (no incoming edges)
3. BFS/topological order: layer[node] = max(layer[pred] + 1) for all predecessors
4. Sources get layer 0

- [ ] **Step 3: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/layout/sugiyama && moon fmt
git commit -m "feat: implement Sugiyama layer assignment (longest-path)"
```

---

### Task 6: Sugiyama — Crossing Minimization

**Files:**
- Create: `src/layout/sugiyama/crossing_min.mbt`
- Create: `src/layout/sugiyama/crossing_test.mbt`

- [ ] **Step 1: Write failing tests**

Create `src/layout/sugiyama/crossing_test.mbt`:
```moonbit
test "no crossing stays unchanged" {
  // Layer 0: [A, B], Layer 1: [C, D]
  // A->C, B->D (no crossing)
  let layers : Array[Array[String]] = [["A", "B"], ["C", "D"]]
  let edges = [("A", "C"), ("B", "D")]
  let result = @sugiyama.minimize_crossings(layers, edges)
  assert_eq(result[0], ["A", "B"])
  assert_eq(result[1], ["C", "D"])
}

test "crossing gets reduced" {
  // Layer 0: [A, B], Layer 1: [C, D]
  // A->D, B->C (1 crossing)
  // After minimization: Layer 1 should be [D, C] or Layer 0 reordered
  let layers : Array[Array[String]] = [["A", "B"], ["C", "D"]]
  let edges = [("A", "D"), ("B", "C")]
  let result = @sugiyama.minimize_crossings(layers, edges)
  // Count crossings should be 0 after optimization
  let crossings = count_crossings(result, edges)
  assert_eq(crossings, 0)
}

test "single layer no change" {
  let layers : Array[Array[String]] = [["A", "B", "C"]]
  let edges : Array[(String, String)] = []
  let result = @sugiyama.minimize_crossings(layers, edges)
  assert_eq(result[0].length(), 3)
}

///| Helper to count edge crossings between adjacent layers.
fn count_crossings(layers : Array[Array[String]], edges : Array[(String, String)]) -> Int {
  let mut total = 0
  for l = 0; l < layers.length() - 1; l = l + 1 {
    let top = layers[l]
    let bot = layers[l + 1]
    // Get edges between these layers
    let layer_edges : Array[(Int, Int)] = []
    for e = 0; e < edges.length(); e = e + 1 {
      let (from, to) = edges[e]
      let top_idx = top.iter().position(fn(n) { n == from })
      let bot_idx = bot.iter().position(fn(n) { n == to })
      match (top_idx, bot_idx) {
        (Some(ti), Some(bi)) => layer_edges.push((ti, bi))
        _ => ()
      }
    }
    // Count crossings
    for i = 0; i < layer_edges.length(); i = i + 1 {
      for j = i + 1; j < layer_edges.length(); j = j + 1 {
        let (t1, b1) = layer_edges[i]
        let (t2, b2) = layer_edges[j]
        if (t1 < t2 && b1 > b2) || (t1 > t2 && b1 < b2) {
          total = total + 1
        }
      }
    }
  }
  total
}
```

- [ ] **Step 2: Implement barycenter crossing minimization**

Create `src/layout/sugiyama/crossing_min.mbt`:

```moonbit
pub fn minimize_crossings(
  layers : Array[Array[String]],
  edges : Array[(String, String)],
) -> Array[Array[String]]
```

Barycenter heuristic:
1. For each layer (top-down): compute barycenter of each node (average position of neighbors in previous layer)
2. Sort layer by barycenter
3. Repeat bottom-up
4. 4 iterations total

- [ ] **Step 3: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/layout/sugiyama && moon fmt
git commit -m "feat: implement Sugiyama crossing minimization (barycenter)"
```

---

### Task 7: Sugiyama — Coordinate Assignment + Public API

**Files:**
- Create: `src/layout/sugiyama/coordinate.mbt`
- Create: `src/layout/sugiyama/coordinate_test.mbt`
- Create: `src/layout/sugiyama/sugiyama.mbt`
- Create: `src/layout/sugiyama/sugiyama_test.mbt`

- [ ] **Step 1: Write coordinate tests**

Create `src/layout/sugiyama/coordinate_test.mbt`:
```moonbit
test "linear chain coordinates are vertical" {
  let layers : Array[Array[String]] = [["A"], ["B"], ["C"]]
  let config = @types.LayoutConfig::default()
  let node_labels : Map[String, String] = { "A": "A", "B": "B", "C": "C" }
  let result = @sugiyama.assign_coordinates(layers, node_labels, config)
  // All nodes should have same x (centered)
  assert_eq(result.nodes[0].x, result.nodes[1].x)
  assert_eq(result.nodes[1].x, result.nodes[2].x)
  // y increases with layer
  assert_true(result.nodes[0].y < result.nodes[1].y)
  assert_true(result.nodes[1].y < result.nodes[2].y)
}

test "wide layer nodes are spaced" {
  let layers : Array[Array[String]] = [["A", "B", "C"]]
  let config = @types.LayoutConfig::default()
  let node_labels : Map[String, String] = { "A": "A", "B": "B", "C": "C" }
  let result = @sugiyama.assign_coordinates(layers, node_labels, config)
  // Nodes should be horizontally spaced
  assert_true(result.nodes[0].x < result.nodes[1].x)
  assert_true(result.nodes[1].x < result.nodes[2].x)
}

test "bounds enclose all nodes" {
  let layers : Array[Array[String]] = [["A", "B"], ["C"]]
  let config = @types.LayoutConfig::default()
  let node_labels : Map[String, String] = { "A": "A", "B": "B", "C": "C" }
  let result = @sugiyama.assign_coordinates(layers, node_labels, config)
  for i = 0; i < result.nodes.length(); i = i + 1 {
    let n = result.nodes[i]
    assert_true(n.x >= 0.0)
    assert_true(n.y >= 0.0)
    assert_true(n.x + n.width <= result.bounds.width)
    assert_true(n.y + n.height <= result.bounds.height)
  }
}
```

- [ ] **Step 2: Write integration tests**

Create `src/layout/sugiyama/sugiyama_test.mbt`:
```moonbit
test "layout simple DAG" {
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [{ id: "A", label: "A" }, { id: "B", label: "B" }, { id: "C", label: "C" }],
    edges: [
      { from: "A", to: "B", weight: None, style: "solid" },
      { from: "B", to: "C", weight: None, style: "solid" },
    ],
  }
  let config = @types.LayoutConfig::default()
  let graph = @sugiyama.layout(def, config)
  assert_eq(graph.nodes.length(), 3)
  assert_eq(graph.edges.length(), 2)
}

test "layout cyclic graph" {
  // A -> B -> C -> A (cycle)
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [{ id: "A", label: "A" }, { id: "B", label: "B" }, { id: "C", label: "C" }],
    edges: [
      { from: "A", to: "B", weight: None, style: "solid" },
      { from: "B", to: "C", weight: None, style: "solid" },
      { from: "C", to: "A", weight: None, style: "solid" },
    ],
  }
  let config = @types.LayoutConfig::default()
  let graph = @sugiyama.layout(def, config)
  assert_eq(graph.nodes.length(), 3)
  assert_eq(graph.edges.length(), 3)
}

test "layout single node" {
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [{ id: "A", label: "A" }],
    edges: [],
  }
  let config = @types.LayoutConfig::default()
  let graph = @sugiyama.layout(def, config)
  assert_eq(graph.nodes.length(), 1)
  assert_eq(graph.edges.length(), 0)
}

test "layout empty graph" {
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [],
    edges: [],
  }
  let config = @types.LayoutConfig::default()
  let graph = @sugiyama.layout(def, config)
  assert_eq(graph.nodes.length(), 0)
}

test "layout undirected raises error" {
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Undirected,
    nodes: [{ id: "A", label: "A" }],
    edges: [],
  }
  let config = @types.LayoutConfig::default()
  let result : Result[Unit, Unit] = try {
    let _ = @sugiyama.layout(def, config)
    Ok(())
  } catch { _ => Err(()) }
  assert_eq(result, Err(()))
}

test "layout preserves node labels" {
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [{ id: "A", label: "Start" }, { id: "B", label: "End" }],
    edges: [{ from: "A", to: "B", weight: None, style: "solid" }],
  }
  let config = @types.LayoutConfig::default()
  let graph = @sugiyama.layout(def, config)
  let a = graph.nodes.iter().find(fn(n) { n.id == "A" })
  match a {
    Some(node) => assert_eq(node.label, "Start")
    None => fail("Node A not found")
  }
}
```

- [ ] **Step 3: Implement coordinate assignment**

Create `src/layout/sugiyama/coordinate.mbt`:

```moonbit
pub fn assign_coordinates(
  layers : Array[Array[String]],
  node_labels : Map[String, String],
  config : @types.LayoutConfig,
) -> @types.PositionedGraph
```

- y = padding + layer_index * (node_height + level_spacing)
- x = padding + position_in_layer * (node_width + node_spacing), centered
- Node dimensions: `@types.default_node_width` x `@types.default_node_height`

- [ ] **Step 4: Implement public layout API**

Create `src/layout/sugiyama/sugiyama.mbt`:

```moonbit
pub fn layout(
  def : @types.GraphDef,
  config : @types.LayoutConfig,
) -> @types.PositionedGraph raise @types.MoonmaidError
```

Orchestrates: cycle removal → layer assignment → crossing minimization → coordinate assignment → edge routing.

Edge routing: for each original edge, create polyline from source node bottom-center to target node top-center. Reversed edges (from cycle removal) get their arrow direction restored.

- [ ] **Step 5: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/layout/sugiyama && moon fmt
git commit -m "feat: implement Sugiyama coordinate assignment and public layout API"
```

---

### Task 8: Graph Renderer

**Files:**
- Create: `src/renderer/render_graph.mbt`
- Create: `src/renderer/render_graph_test.mbt`

- [ ] **Step 1: Write failing tests**

Create `src/renderer/render_graph_test.mbt`:
```moonbit
test "render graph produces SVG with nodes and edges" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "A", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: "Start" },
      { id: "B", x: 20.0, y: 120.0, width: 56.0, height: 40.0, label: "End" },
    ],
    edges: [
      { from_id: "A", to_id: "B", points: [(48.0, 60.0), (48.0, 120.0)], label: "" },
    ],
    bounds: { x: 0.0, y: 0.0, width: 96.0, height: 180.0 },
  }
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [{ id: "A", label: "Start" }, { id: "B", label: "End" }],
    edges: [{ from: "A", to: "B", weight: None, style: "solid" }],
  }
  let svg = @renderer.emit(@renderer.render_graph(graph, def))
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains(">Start<"))
  assert_true(svg.contains(">End<"))
  assert_true(svg.contains("<polyline"))
}

test "render graph weight label" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "A", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: "A" },
      { id: "B", x: 20.0, y: 120.0, width: 56.0, height: 40.0, label: "B" },
    ],
    edges: [
      { from_id: "A", to_id: "B", points: [(48.0, 60.0), (48.0, 120.0)], label: "5" },
    ],
    bounds: { x: 0.0, y: 0.0, width: 96.0, height: 180.0 },
  }
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [{ id: "A", label: "A" }, { id: "B", label: "B" }],
    edges: [{ from: "A", to: "B", weight: Some(5), style: "solid" }],
  }
  let svg = @renderer.emit(@renderer.render_graph(graph, def))
  assert_true(svg.contains(">5<"))
}

test "render graph dashed edge" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "A", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: "A" },
      { id: "B", x: 20.0, y: 120.0, width: 56.0, height: 40.0, label: "B" },
    ],
    edges: [
      { from_id: "A", to_id: "B", points: [(48.0, 60.0), (48.0, 120.0)], label: "" },
    ],
    bounds: { x: 0.0, y: 0.0, width: 96.0, height: 180.0 },
  }
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [{ id: "A", label: "A" }, { id: "B", label: "B" }],
    edges: [{ from: "A", to: "B", weight: None, style: "dashed" }],
  }
  let svg = @renderer.emit(@renderer.render_graph(graph, def))
  assert_true(svg.contains("stroke-dasharray"))
}

test "render graph XSS in label escaped" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "A", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: "<script>alert(1)</script>" },
    ],
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: 96.0, height: 80.0 },
  }
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [{ id: "A", label: "<script>alert(1)</script>" }],
    edges: [],
  }
  let svg = @renderer.emit(@renderer.render_graph(graph, def))
  assert_true(svg.contains("<script>").not())
  assert_true(svg.contains("&lt;script&gt;"))
}
```

- [ ] **Step 2: Implement graph renderer**

Create `src/renderer/render_graph.mbt`:

```moonbit
pub fn render_graph(
  graph : @types.PositionedGraph,
  def : @types.GraphDef,
) -> SvgNode
```

Follow `render_tree.mbt` pattern:
- Background rect
- Arrow marker in defs (for directed graphs)
- Edges as polylines, with stroke-dasharray for dashed/dotted
- Weight labels at edge midpoint (small text with white background rect)
- Nodes as rounded rects (rx=14) with shadow filter
- Node labels centered

Edge style mapping:
- `"solid"` → no dasharray
- `"dashed"` → `stroke-dasharray="6,4"`
- `"dotted"` → `stroke-dasharray="2,4"`

To support dasharray, either add a field to `Polyline` in SvgNode or build the SVG string directly for edges. Recommend: add optional `dash_array` field to SvgNode::Polyline.

- [ ] **Step 3: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/renderer && moon fmt
git commit -m "feat: implement graph renderer with weight labels and edge styles"
```

---

### Task 9: API Integration + E2E Tests

**Files:**
- Modify: `src/lib/moon.pkg` — add sugiyama import
- Modify: `src/lib/moonmaid.mbt` — handle GraphDiagram
- Modify: `src/lib/moonmaid_test.mbt` — add e2e tests

- [ ] **Step 1: Write failing e2e tests**

Append to `src/lib/moonmaid_test.mbt`:
```moonbit
test "e2e: directed graph" {
  let input = "graph directed { A -> B  B -> C }"
  let svg = @lib.render(input)
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains(">A<"))
  assert_true(svg.contains(">B<"))
  assert_true(svg.contains(">C<"))
  assert_true(svg.contains("<polyline"))
}

test "e2e: graph with labeled nodes" {
  let input = "graph directed { A(\"Start\") -> B(\"End\") }"
  let svg = @lib.render(input)
  assert_true(svg.contains(">Start<"))
  assert_true(svg.contains(">End<"))
}

test "e2e: graph with weight" {
  let input = "graph directed { A -> B [weight=5] }"
  let svg = @lib.render(input)
  assert_true(svg.contains(">5<"))
}

test "e2e: graph undirected returns error" {
  let svg = @lib.render("graph undirected { A -> B }")
  assert_true(svg.contains("#991b1b")) // error color
}

test "e2e: empty graph" {
  let svg = @lib.render("graph directed { }")
  assert_true(svg.contains("<svg"))
}

test "e2e: graph with dashed edge" {
  let input = "graph directed { A -> B [style=dashed] }"
  let svg = @lib.render(input)
  assert_true(svg.contains("stroke-dasharray"))
}

test "e2e: cyclic graph renders without error" {
  let input = "graph directed { A -> B  B -> C  C -> A }"
  let svg = @lib.render(input)
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains(">A<"))
}
```

- [ ] **Step 2: Integrate into render_result**

Add to `src/lib/moon.pkg`: import `"paveg/moonmaid/layout/sugiyama" @sugiyama`

In `render_result`, replace GraphDiagram stub:
```moonbit
GraphDiagram(def) => {
  let graph = @sugiyama.layout(def, config)
  @renderer.emit(@renderer.render_graph(graph, def))
}
```

- [ ] **Step 3: Run full test suite, moon fmt, commit**

```bash
moon test --target wasm-gc && moon fmt
git commit -m "feat: integrate graph DSL + Sugiyama layout into public API"
```

---

## Summary

| Task | Component | New Tests |
|---|---|---|
| 1 | Graph types | 2 |
| 2 | Lexer: graph tokens | 3 |
| 3 | Parser: graph DSL | 10 |
| 4 | Sugiyama: cycle removal | 5 |
| 5 | Sugiyama: layer assignment | 4 |
| 6 | Sugiyama: crossing minimization | 3 |
| 7 | Sugiyama: coordinates + public API | 9 |
| 8 | Graph renderer | 4 |
| 9 | API integration + E2E | 7 |

**Total: 9 tasks, ~47 new tests, ~9 commits**

## Next Plans

- **Phase 2b**: Graph animation (@animate BFS/DFS/Dijkstra)
- **Phase 3**: Linkedlist, Hashtable, State, Flow DSL types
- **Phase 4**: Web editor (CodeMirror + real-time preview)
