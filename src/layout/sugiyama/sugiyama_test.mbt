///|
/// Test: Simple DAG layout produces positioned nodes.
test "sugiyama: simple dag layout" {
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [
      { id: "A", label: "A", shape: Rect },
      { id: "B", label: "B", shape: Rect },
      { id: "C", label: "C", shape: Rect },
    ],
    edges: [
      { from: "A", to: "B", weight: None, style: "", label: "" },
      { from: "B", to: "C", weight: None, style: "", label: "" },
    ],
  }
  let config = @types.LayoutConfig::default()
  let graph = layout(def, config)
  assert_eq(graph.nodes.length(), 3)
  assert_eq(graph.edges.length(), 2)
}

///|
/// Test: Cyclic graph renders without error.
test "sugiyama: cyclic graph renders" {
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [
      { id: "A", label: "A", shape: Rect },
      { id: "B", label: "B", shape: Rect },
    ],
    edges: [
      { from: "A", to: "B", weight: None, style: "", label: "" },
      { from: "B", to: "A", weight: None, style: "", label: "" },
    ],
  }
  let config = @types.LayoutConfig::default()
  let graph = layout(def, config)
  assert_eq(graph.nodes.length(), 2)
  assert_eq(graph.edges.length(), 2)
}

///|
/// Test: Single node.
test "sugiyama: single node" {
  let def : @types.GraphDef = {
    direction: FlowTD,
    nodes: [{ id: "X", label: "Node X", shape: Rect }],
    edges: [],
  }
  let config = @types.LayoutConfig::default()
  let graph = layout(def, config)
  assert_eq(graph.nodes.length(), 1)
  assert_eq(graph.nodes[0].label, "Node X")
  assert_eq(graph.edges.length(), 0)
}

///|
/// Test: Empty graph.
test "sugiyama: empty graph" {
  let def : @types.GraphDef = { direction: Directed, nodes: [], edges: [] }
  let config = @types.LayoutConfig::default()
  let graph = layout(def, config)
  assert_eq(graph.nodes.length(), 0)
  assert_eq(graph.edges.length(), 0)
}

///|
/// Test: Undirected raises error.
test "sugiyama: undirected raises error" {
  let def : @types.GraphDef = {
    direction: Undirected,
    nodes: [{ id: "A", label: "A", shape: Rect }],
    edges: [],
  }
  let config = @types.LayoutConfig::default()
  let mut errored = false
  try {
    let _ = layout(def, config)
  } catch {
    @types.MoonmaidError(_) => errored = true
  }
  assert_true(errored)
}

///|
/// Test: Node labels are preserved.
test "sugiyama: node labels preserved" {
  let def : @types.GraphDef = {
    direction: FlowTD,
    nodes: [
      { id: "n1", label: "Hello", shape: Rect },
      { id: "n2", label: "World", shape: Rect },
    ],
    edges: [{ from: "n1", to: "n2", weight: None, style: "", label: "" }],
  }
  let config = @types.LayoutConfig::default()
  let graph = layout(def, config)
  let mut found_hello = false
  let mut found_world = false
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    if graph.nodes[i].label == "Hello" {
      found_hello = true
    }
    if graph.nodes[i].label == "World" {
      found_world = true
    }
  }
  assert_true(found_hello)
  assert_true(found_world)
}
