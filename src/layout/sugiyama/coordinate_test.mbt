///|
/// Test: Linear chain has vertical alignment (same x) in TD mode.
test "coordinate: linear chain vertical alignment" {
  let layers : Array[Array[String]] = [["A"], ["B"], ["C"]]
  let labels : Map[String, String] = Map::new()
  labels["A"] = "A"
  labels["B"] = "B"
  labels["C"] = "C"
  let edges = [("A", "B"), ("B", "C")]
  let edge_labels : Map[String, String] = Map::new()
  let config = @types.LayoutConfig::default()
  let graph = assign_coordinates(
    layers,
    labels,
    edges,
    edge_labels,
    config,
    false,
    Map::new(),
  )
  assert_eq(graph.nodes.length(), 3)
  // All nodes should have the same x (single node per layer, centered)
  assert_eq(graph.nodes[0].x, graph.nodes[1].x)
  assert_eq(graph.nodes[1].x, graph.nodes[2].x)
  // Y should increase with layer
  assert_true(graph.nodes[1].y > graph.nodes[0].y)
  assert_true(graph.nodes[2].y > graph.nodes[1].y)
}

///|
/// Test: Wide layer has nodes horizontally spaced.
test "coordinate: wide layer horizontal spacing" {
  let layers : Array[Array[String]] = [["A", "B", "C"]]
  let labels : Map[String, String] = Map::new()
  labels["A"] = "A"
  labels["B"] = "B"
  labels["C"] = "C"
  let edges : Array[(String, String)] = []
  let edge_labels : Map[String, String] = Map::new()
  let config = @types.LayoutConfig::default()
  let graph = assign_coordinates(
    layers,
    labels,
    edges,
    edge_labels,
    config,
    false,
    Map::new(),
  )
  assert_eq(graph.nodes.length(), 3)
  // Nodes should be horizontally spaced
  assert_true(graph.nodes[1].x > graph.nodes[0].x)
  assert_true(graph.nodes[2].x > graph.nodes[1].x)
  // All same y
  assert_eq(graph.nodes[0].y, graph.nodes[1].y)
}

///|
/// Test: Single node gets valid non-negative coordinates.
test "single node coordinates" {
  let layers : Array[Array[String]] = [["A"]]
  let labels : Map[String, String] = Map::new()
  labels["A"] = "A"
  let edges : Array[(String, String)] = []
  let edge_labels : Map[String, String] = Map::new()
  let config = @types.LayoutConfig::default()
  let result = assign_coordinates(
    layers,
    labels,
    edges,
    edge_labels,
    config,
    false,
    Map::new(),
  )
  assert_eq(result.nodes.length(), 1)
  assert_true(result.nodes[0].x >= 0.0)
  assert_true(result.nodes[0].y >= 0.0)
}

///|
/// Test: Empty graph produces no nodes.
test "empty graph coordinates" {
  let layers : Array[Array[String]] = []
  let labels : Map[String, String] = Map::new()
  let edges : Array[(String, String)] = []
  let edge_labels : Map[String, String] = Map::new()
  let config = @types.LayoutConfig::default()
  let result = assign_coordinates(
    layers,
    labels,
    edges,
    edge_labels,
    config,
    false,
    Map::new(),
  )
  assert_eq(result.nodes.length(), 0)
}

///|
/// Test: Bounds enclose all nodes.
test "coordinate: bounds enclose all nodes" {
  let layers : Array[Array[String]] = [["A", "B"], ["C"]]
  let labels : Map[String, String] = Map::new()
  labels["A"] = "A"
  labels["B"] = "B"
  labels["C"] = "C"
  let edges = [("A", "C"), ("B", "C")]
  let edge_labels : Map[String, String] = Map::new()
  let config = @types.LayoutConfig::default()
  let graph = assign_coordinates(
    layers,
    labels,
    edges,
    edge_labels,
    config,
    false,
    Map::new(),
  )
  let b = graph.bounds
  // All nodes should be within bounds
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let n = graph.nodes[i]
    assert_true(n.x >= b.x)
    assert_true(n.y >= b.y)
    assert_true(n.x + n.width <= b.x + b.width)
    assert_true(n.y + n.height <= b.y + b.height)
  }
}
