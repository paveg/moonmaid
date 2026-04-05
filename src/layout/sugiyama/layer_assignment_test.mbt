///|
/// Test: Linear chain A->B->C gets layers 0, 1, 2.
test "layer_assignment: linear chain" {
  let nodes = ["A", "B", "C"]
  let edges = [("A", "B"), ("B", "C")]
  let layers = assign_layers(nodes, edges)
  assert_eq(layers.get("A"), Some(0))
  assert_eq(layers.get("B"), Some(1))
  assert_eq(layers.get("C"), Some(2))
}

///|
/// Test: Diamond shape: B and C on same layer, D below both.
test "layer_assignment: diamond" {
  let nodes = ["A", "B", "C", "D"]
  let edges = [("A", "B"), ("A", "C"), ("B", "D"), ("C", "D")]
  let layers = assign_layers(nodes, edges)
  assert_eq(layers.get("A"), Some(0))
  assert_eq(layers.get("B"), Some(1))
  assert_eq(layers.get("C"), Some(1))
  assert_eq(layers.get("D"), Some(2))
}

///|
/// Test: Single node gets layer 0.
test "layer_assignment: single node" {
  let nodes = ["A"]
  let edges : Array[(String, String)] = []
  let layers = assign_layers(nodes, edges)
  assert_eq(layers.get("A"), Some(0))
}

///|
/// Test: Multiple sources all get layer 0.
test "layer_assignment: wide graph with multiple sources" {
  let nodes = ["A", "B", "C", "D"]
  let edges = [("A", "C"), ("B", "C"), ("C", "D")]
  let layers = assign_layers(nodes, edges)
  assert_eq(layers.get("A"), Some(0))
  assert_eq(layers.get("B"), Some(0))
  assert_eq(layers.get("C"), Some(1))
  assert_eq(layers.get("D"), Some(2))
}
