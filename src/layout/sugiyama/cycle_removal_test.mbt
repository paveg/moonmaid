///|
/// Test: DAG with no cycles produces 0 reversed edges.
test "cycle_removal: dag has no reversed edges" {
  let nodes = ["A", "B", "C"]
  let edges = [("A", "B"), ("B", "C")]
  let result = remove_cycles(nodes, edges)
  assert_eq(result.reversed.length(), 0)
  assert_eq(result.edges, [("A", "B"), ("B", "C")])
}

///|
/// Test: Single cycle A->B->C->A reverses exactly 1 edge.
test "cycle_removal: single cycle reverses one edge" {
  let nodes = ["A", "B", "C"]
  let edges = [("A", "B"), ("B", "C"), ("C", "A")]
  let result = remove_cycles(nodes, edges)
  assert_eq(result.reversed.length(), 1)
  // The graph should now be acyclic
}

///|
/// Test: Self-loop is immediately reversed.
test "cycle_removal: self loop reversed" {
  let nodes = ["A"]
  let edges = [("A", "A")]
  let result = remove_cycles(nodes, edges)
  assert_eq(result.reversed.length(), 1)
  assert_eq(result.edges[0], ("A", "A"))
}

///|
/// Test: Empty graph produces no edges.
test "cycle_removal: empty graph" {
  let nodes : Array[String] = []
  let edges : Array[(String, String)] = []
  let result = remove_cycles(nodes, edges)
  assert_eq(result.edges.length(), 0)
  assert_eq(result.reversed.length(), 0)
}

///|
/// Test: Multiple independent cycles each get one edge reversed.
test "cycle_removal: multiple independent cycles" {
  let nodes = ["A", "B", "C", "D"]
  let edges = [("A", "B"), ("B", "A"), ("C", "D"), ("D", "C")]
  let result = remove_cycles(nodes, edges)
  assert_eq(result.reversed.length(), 2)
}
