///|
/// Test 1: Basic graph SVG contains svg element, node labels, and polylines.
test "render_graph produces svg with labels and polylines" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "A", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: "A" },
      { id: "B", x: 20.0, y: 100.0, width: 56.0, height: 40.0, label: "B" },
    ],
    edges: [
      {
        from_id: "A",
        to_id: "B",
        points: [(48.0, 60.0), (48.0, 100.0)],
        label: "",
      },
    ],
    bounds: { x: 0.0, y: 0.0, width: 120.0, height: 160.0 },
  }
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [
      { id: "A", label: "A", shape: Rect },
      { id: "B", label: "B", shape: Rect },
    ],
    edges: [{ from: "A", to: "B", weight: None, style: "solid", label: "" }],
  }
  let svg = emit(render_graph(graph, def))
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains(">A<"))
  assert_true(svg.contains(">B<"))
  assert_true(svg.contains("<polyline"))
}

///|
/// Test 2: Edge label (weight) renders as small text in SVG.
test "render_graph edge label renders text" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "A", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: "A" },
      { id: "B", x: 20.0, y: 100.0, width: 56.0, height: 40.0, label: "B" },
    ],
    edges: [
      {
        from_id: "A",
        to_id: "B",
        points: [(48.0, 60.0), (48.0, 100.0)],
        label: "5",
      },
    ],
    bounds: { x: 0.0, y: 0.0, width: 120.0, height: 160.0 },
  }
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [
      { id: "A", label: "A", shape: Rect },
      { id: "B", label: "B", shape: Rect },
    ],
    edges: [{ from: "A", to: "B", weight: Some(5), style: "solid", label: "5" }],
  }
  let svg = emit(render_graph(graph, def))
  assert_true(svg.contains(">5<"))
}

///|
/// Test 3: Dashed edge produces stroke-dasharray attribute.
test "render_graph dashed edge contains stroke-dasharray" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "A", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: "A" },
      { id: "B", x: 20.0, y: 100.0, width: 56.0, height: 40.0, label: "B" },
    ],
    edges: [
      {
        from_id: "A",
        to_id: "B",
        points: [(48.0, 60.0), (48.0, 100.0)],
        label: "",
      },
    ],
    bounds: { x: 0.0, y: 0.0, width: 120.0, height: 160.0 },
  }
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [
      { id: "A", label: "A", shape: Rect },
      { id: "B", label: "B", shape: Rect },
    ],
    edges: [{ from: "A", to: "B", weight: None, style: "dashed", label: "" }],
  }
  let svg = emit(render_graph(graph, def))
  assert_true(svg.contains("stroke-dasharray"))
}

///|
/// Test 4: Diamond node renders as polygon element.
test "render_graph diamond node contains polygon" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "D", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: "D" },
    ],
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: 100.0, height: 80.0 },
  }
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [{ id: "D", label: "D", shape: Diamond }],
    edges: [],
  }
  let svg = emit(render_graph(graph, def))
  assert_true(svg.contains("<polygon"))
}

///|
/// Test 5: XSS in node label is escaped.
test "render_graph xss in label escaped" {
  let xss = "<script>alert(1)</script>"
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "X", x: 20.0, y: 20.0, width: 56.0, height: 40.0, label: xss },
    ],
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: 100.0, height: 80.0 },
  }
  let def : @types.GraphDef = {
    direction: Directed,
    nodes: [{ id: "X", label: xss, shape: Rect }],
    edges: [],
  }
  let svg = emit(render_graph(graph, def))
  assert_false(svg.contains(xss))
  assert_true(svg.contains("&lt;script&gt;"))
}
