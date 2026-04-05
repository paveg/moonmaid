///| Test 1: Single node — insert(5), 1 node, 0 edges.
test "single node produces one node and zero edges" {
  let def : @types.TreeDef = { kind: BST, operations: [5] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  assert_eq(graph.nodes.length(), 1)
  assert_eq(graph.edges.length(), 0)
  assert_eq(graph.nodes[0].id, "node_5")
  assert_eq(graph.nodes[0].label, "5")
  assert_eq(graph.nodes[0].width, 48.0)
  assert_eq(graph.nodes[0].height, 32.0)
}

///| Test 2: Left and right children — insert(5, 3, 7).
test "root centered with left child left and right child right" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3, 7] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  assert_eq(graph.nodes.length(), 3)
  assert_eq(graph.edges.length(), 2)
  // Find nodes by id
  let mut root_x = 0.0
  let mut left_x = 0.0
  let mut right_x = 0.0
  let mut left_y = 0.0
  let mut right_y = 0.0
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    if node.id == "node_5" {
      root_x = node.x
    } else if node.id == "node_3" {
      left_x = node.x
      left_y = node.y
    } else if node.id == "node_7" {
      right_x = node.x
      right_y = node.y
    }
  }
  assert_true(left_x < root_x)
  assert_true(right_x > root_x)
  // Children on same y level
  assert_eq(left_y, right_y)
}

///| Test 3: BST x-order invariant — insert(5, 3, 7, 1, 4).
test "inorder traversal x-coordinates are sorted" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3, 7, 1, 4] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  assert_eq(graph.nodes.length(), 5)
  // Collect x by value
  let mut x1 = 0.0
  let mut x3 = 0.0
  let mut x4 = 0.0
  let mut x5 = 0.0
  let mut x7 = 0.0
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    if node.id == "node_1" {
      x1 = node.x
    } else if node.id == "node_3" {
      x3 = node.x
    } else if node.id == "node_4" {
      x4 = node.x
    } else if node.id == "node_5" {
      x5 = node.x
    } else if node.id == "node_7" {
      x7 = node.x
    }
  }
  // In-order: 1, 3, 4, 5, 7 — x-coordinates should be strictly increasing
  assert_true(x1 < x3)
  assert_true(x3 < x4)
  assert_true(x4 < x5)
  assert_true(x5 < x7)
}

///| Test 4: Empty operations — 0 nodes, 0 edges.
test "empty operations produces zero nodes and edges" {
  let def : @types.TreeDef = { kind: BST, operations: [] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  assert_eq(graph.nodes.length(), 0)
  assert_eq(graph.edges.length(), 0)
  assert_eq(graph.bounds.width, 0.0)
  assert_eq(graph.bounds.height, 0.0)
}

///| Test 5: Duplicate values ignored — insert(5, 5, 5) → 1 node, 0 edges.
test "duplicate values are ignored" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 5, 5] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  assert_eq(graph.nodes.length(), 1)
  assert_eq(graph.edges.length(), 0)
}

///| Test 6: Deep left chain — insert(5, 4, 3, 2, 1).
test "deep left chain has increasing y and decreasing x" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 4, 3, 2, 1] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  assert_eq(graph.nodes.length(), 5)
  // Collect (value, x, y)
  let xs : Array[Double] = Array::make(5, 0.0)
  let ys : Array[Double] = Array::make(5, 0.0)
  let vals = [5, 4, 3, 2, 1]
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    for j = 0; j < vals.length(); j = j + 1 {
      if node.id == "node_\{vals[j]}" {
        xs[j] = node.x
        ys[j] = node.y
      }
    }
  }
  // Each deeper node has increasing y
  for i = 0; i < 4; i = i + 1 {
    assert_true(ys[i] < ys[i + 1])
  }
  // Each deeper node has decreasing x (left chain)
  for i = 0; i < 4; i = i + 1 {
    assert_true(xs[i] > xs[i + 1])
  }
}

///| Test 7: Symmetric tree — insert(4, 2, 6, 1, 3, 5, 7).
test "symmetric tree has root centered between leftmost and rightmost" {
  let def : @types.TreeDef = { kind: BST, operations: [4, 2, 6, 1, 3, 5, 7] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  assert_eq(graph.nodes.length(), 7)
  let mut root_x = 0.0
  let mut min_x = 1.0e18
  let mut max_x = -1.0e18
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    if node.id == "node_4" {
      root_x = node.x
    }
    if node.x < min_x {
      min_x = node.x
    }
    if node.x > max_x {
      max_x = node.x
    }
  }
  // Root should be centered: midpoint of min_x and max_x
  let mid = (min_x + max_x) / 2.0
  assert_true((root_x - mid) < 1.0)
  assert_true((mid - root_x) < 1.0)
}

///| Test 8: Edge count — n nodes should have n-1 edges.
test "n nodes have n minus 1 edges" {
  let cases : Array[(Array[Int], Int)] = [
    ([5], 1),
    ([5, 3], 2),
    ([5, 3, 7], 3),
    ([5, 3, 7, 1, 4, 6, 8], 7),
  ]
  for i = 0; i < cases.length(); i = i + 1 {
    let (ops, expected_nodes) = cases[i]
    let def : @types.TreeDef = { kind: BST, operations: ops }
    let config = @types.LayoutConfig::default()
    let graph = @tree.layout(def, config)
    assert_eq(graph.nodes.length(), expected_nodes)
    assert_eq(graph.edges.length(), expected_nodes - 1)
  }
}
