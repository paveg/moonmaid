///|
test "dagre: empty graph produces empty result" {
  let def : @types.GraphDef = { direction: Directed, nodes: [], edges: [] }
  let config = @types.LayoutConfig::default()
  let result = layout_with_dagre(def, config)
  assert_eq(result.nodes.length(), 0)
  assert_eq(result.edges.length(), 0)
  assert_eq(result.bounds.width, 0.0)
}

///|
test "dagre: single node graph" {
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [{ id: "A", label: "A", shape: Rect }],
    edges: [],
  }
  let config = @types.LayoutConfig::default()
  let result = layout_with_dagre(def, config)
  assert_eq(result.nodes.length(), 1)
  assert_eq(result.nodes[0].id, "A")
  assert_true(result.nodes[0].width > 0.0)
  assert_true(result.nodes[0].height > 0.0)
}

///|
test "dagre: simple DAG produces valid output" {
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [
      { id: "A", label: "Start", shape: Rect },
      { id: "B", label: "Middle", shape: Rect },
      { id: "C", label: "End", shape: Rect },
    ],
    edges: [
      { from: "A", to: "B", weight: None, style: "->", label: "" },
      { from: "B", to: "C", weight: None, style: "->", label: "" },
    ],
  }
  let config = @types.LayoutConfig::default()
  let result = layout_with_dagre(def, config)
  assert_eq(result.nodes.length(), 3)
  assert_eq(result.edges.length(), 2)
  assert_true(result.bounds.width > 0.0)
  assert_true(result.bounds.height > 0.0)
}

///|
test "dagre: cyclic graph renders without error" {
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [
      { id: "A", label: "A", shape: Rect },
      { id: "B", label: "B", shape: Rect },
    ],
    edges: [
      { from: "A", to: "B", weight: None, style: "->", label: "" },
      { from: "B", to: "A", weight: None, style: "->", label: "" },
    ],
  }
  let config = @types.LayoutConfig::default()
  let result = layout_with_dagre(def, config)
  assert_eq(result.nodes.length(), 2)
  assert_eq(result.edges.length(), 2)
}

///|
test "dagre: flowchart TD direction" {
  let def : @types.GraphDef = {
    direction: FlowTD,
    nodes: [
      { id: "A", label: "Top", shape: Rect },
      { id: "B", label: "Bottom", shape: Rect },
    ],
    edges: [{ from: "A", to: "B", weight: None, style: "->", label: "" }],
  }
  let config = @types.LayoutConfig::default()
  let result = layout_with_dagre(def, config)
  assert_eq(result.nodes.length(), 2)
  // In TD layout, A should be above B (smaller y)
  let node_a = result.nodes[0]
  let node_b = result.nodes[1]
  let (top, bottom) = if node_a.id == "A" {
    (node_a, node_b)
  } else {
    (node_b, node_a)
  }
  assert_true(top.y < bottom.y)
}

///|
test "dagre: flowchart LR direction" {
  let def : @types.GraphDef = {
    direction: FlowLR,
    nodes: [
      { id: "A", label: "Left", shape: Rect },
      { id: "B", label: "Right", shape: Rect },
    ],
    edges: [{ from: "A", to: "B", weight: None, style: "->", label: "" }],
  }
  let config = @types.LayoutConfig::default()
  let result = layout_with_dagre(def, config)
  assert_eq(result.nodes.length(), 2)
  // In LR layout, A should be left of B (smaller x)
  let node_a = result.nodes[0]
  let node_b = result.nodes[1]
  let (left, right) = if node_a.id == "A" {
    (node_a, node_b)
  } else {
    (node_b, node_a)
  }
  assert_true(left.x < right.x)
}
