///|
/// Test 1: 3 elements are positioned horizontally with correct spacing, no edges.
test "three elements positioned horizontally with no edges" {
  let def : @types.ArrayDef = { elements: [10, 20, 30], highlights: [] }
  let config = @types.LayoutConfig::default() // node_spacing: 20.0, padding: 20.0
  let graph = layout(def, config)
  // 3 element nodes + 3 index label nodes = 6 total
  assert_eq(graph.nodes.length(), 6)
  assert_eq(graph.edges.length(), 0)
  // Verify element nodes exist with id "elem_0", "elem_1", "elem_2"
  let elem0 = graph.nodes[0]
  let elem1 = graph.nodes[1]
  let elem2 = graph.nodes[2]
  assert_eq(elem0.id, "elem_0")
  assert_eq(elem1.id, "elem_1")
  assert_eq(elem2.id, "elem_2")
  // Horizontal spacing: each cell is 52.0 wide + node_spacing(20.0) gap
  // elem_0.x = padding(20.0), elem_1.x = 20.0 + 52.0 + 20.0 = 92.0, etc.
  assert_eq(elem0.x, 20.0)
  assert_eq(elem1.x, 92.0)
  assert_eq(elem2.x, 164.0)
}

///|
/// Test 2: Index label nodes are created below element cells.
test "index label nodes created below element cells" {
  let def : @types.ArrayDef = { elements: [5, 15], highlights: [] }
  let config = @types.LayoutConfig::default()
  let graph = layout(def, config)
  // 2 element nodes + 2 index label nodes = 4 total
  assert_eq(graph.nodes.length(), 4)
  // Index label nodes have id "idx_0" and "idx_1"
  let idx0 = graph.nodes[2]
  let idx1 = graph.nodes[3]
  assert_eq(idx0.id, "idx_0")
  assert_eq(idx1.id, "idx_1")
  // Index labels are 4.0 below the element cell bottom (y + height + 4.0)
  // elem y = padding = 20.0, elem height = 52.0, so idx y = 20.0 + 52.0 + 4.0 = 76.0
  assert_eq(idx0.y, 76.0)
  assert_eq(idx1.y, 76.0)
  // Index label x should match element x
  assert_eq(idx0.x, graph.nodes[0].x)
  assert_eq(idx1.x, graph.nodes[1].x)
}

///|
/// Test 3: Bounds enclose all nodes with padding.
test "bounds enclose all nodes with padding" {
  let def : @types.ArrayDef = { elements: [1, 2, 3, 4, 5], highlights: [] }
  let config = @types.LayoutConfig::default() // padding: 20.0
  let graph = layout(def, config)
  // 5 elements: last elem_4.x = 20.0 + 4 * (52.0 + 20.0) = 20.0 + 288.0 = 308.0
  // last node right edge: 308.0 + 52.0 = 360.0, plus padding = 380.0
  // bounds.x = 0.0, bounds.width should encompass everything
  assert_true(graph.bounds.width >= 360.0)
  // Index labels go to y=76.0 + 20.0 (height of index label), bounds height should cover that
  assert_true(graph.bounds.height >= 76.0 + 20.0)
}

///|
/// Test 4: Empty array produces 0 nodes with valid bounds.
test "empty array produces zero nodes and valid bounds" {
  let def : @types.ArrayDef = { elements: [], highlights: [] }
  let config = @types.LayoutConfig::default()
  let graph = layout(def, config)
  assert_eq(graph.nodes.length(), 0)
  assert_eq(graph.edges.length(), 0)
  // Bounds should still be valid (non-negative)
  assert_true(graph.bounds.width >= 0.0)
  assert_true(graph.bounds.height >= 0.0)
}

///|
/// Test 5: Single element has exact x/y matching padding.
test "single element positioned at padding offset" {
  let def : @types.ArrayDef = { elements: [42], highlights: [] }
  let config = @types.LayoutConfig::default() // padding: 20.0
  let graph = layout(def, config)
  // 1 element node + 1 index label = 2 nodes
  assert_eq(graph.nodes.length(), 2)
  let elem0 = graph.nodes[0]
  assert_eq(elem0.id, "elem_0")
  assert_eq(elem0.x, 20.0) // padding
  assert_eq(elem0.y, 20.0) // padding
  assert_eq(elem0.width, 52.0)
  assert_eq(elem0.height, 52.0)
  assert_eq(elem0.label, "42")
  let idx0 = graph.nodes[1]
  assert_eq(idx0.id, "idx_0")
  assert_eq(idx0.x, 20.0) // same x as elem
  assert_eq(idx0.label, "0")
}

///|
/// Test 6: Large node_spacing is reflected in element positions.
test "large node_spacing reflected in positions" {
  let def : @types.ArrayDef = { elements: [1, 2, 3], highlights: [] }
  let config : @types.LayoutConfig = {
    node_spacing: 100.0,
    level_spacing: 60.0,
    padding: 20.0,
  }
  let graph = layout(def, config)
  // elem_0.x = padding = 20.0
  // elem_1.x = 20.0 + 52.0 + 100.0 = 172.0
  // elem_2.x = 172.0 + 52.0 + 100.0 = 324.0
  assert_eq(graph.nodes[0].x, 20.0)
  assert_eq(graph.nodes[1].x, 172.0)
  assert_eq(graph.nodes[2].x, 324.0)
}
