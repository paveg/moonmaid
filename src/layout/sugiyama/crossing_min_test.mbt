///|
/// Test: No crossings stays unchanged.
test "crossing_min: no crossing stays unchanged" {
  let layers : Array[Array[String]] = [["A", "B"], ["C", "D"]]
  let edges = [("A", "C"), ("B", "D")]
  let result = minimize_crossings(layers, edges)
  assert_eq(result[0], ["A", "B"])
  assert_eq(result[1], ["C", "D"])
}

///|
/// Test: Crossing gets reduced (A->D, B->C pattern).
test "crossing_min: crossing gets reduced" {
  let layers : Array[Array[String]] = [["A", "B"], ["C", "D"]]
  // A->D and B->C creates a crossing; after minimization D should come before C
  let edges = [("A", "D"), ("B", "C")]
  let result = minimize_crossings(layers, edges)
  assert_eq(result[1], ["D", "C"])
}

///|
/// Test: Single layer is unchanged.
test "crossing_min: single layer unchanged" {
  let layers : Array[Array[String]] = [["A", "B", "C"]]
  let edges : Array[(String, String)] = []
  let result = minimize_crossings(layers, edges)
  assert_eq(result[0], ["A", "B", "C"])
}
