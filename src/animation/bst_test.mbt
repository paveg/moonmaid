///|
/// Test: single insert creates root node with one step.
test "single insert (root)" {
  let def : @types.TreeDef = { kind: BST, operations: [5] }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_bst_animation(def, config)
  assert_eq(timeline.steps.length(), 1)
  assert_eq(timeline.steps[0].description, "Insert 5 as root")
  match timeline.steps[0].actions[0] {
    AddNode(_) => ()
    _ => fail("Expected AddNode action")
  }
}

///|
/// Test: two inserts produce 4 steps (root + highlight/compare + traverse + add).
test "two inserts" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3] }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_bst_animation(def, config)
  assert_eq(timeline.steps.length(), 4)
}

///|
/// Test: three inserts produce 7 steps.
test "three inserts" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3, 7] }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_bst_animation(def, config)
  assert_eq(timeline.steps.length(), 7)
}

///|
/// Test: empty operations produce empty timeline.
test "empty operations" {
  let def : @types.TreeDef = { kind: BST, operations: [] }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_bst_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

///|
/// Test: duplicate values are skipped silently.
test "duplicate values skipped" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 5] }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_bst_animation(def, config)
  assert_eq(timeline.steps.length(), 1)
}

///|
/// Test: deep insertion path produces correct step count.
/// 5->root:1 step, 3->compare 5+traverse+add:3 steps, 1->compare 5+traverse+compare 3+traverse+add:5 steps = 9 total.
test "deep insertion path" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3, 1] }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_bst_animation(def, config)
  assert_eq(timeline.steps.length(), 9)
}

///|
/// Boundary: large tree (50 nodes) has reasonable step count and non-negative positions.
test "large tree 50 nodes has valid positions" {
  let ops : Array[Int] = []
  for i = 0; i < 50; i = i + 1 {
    ops.push(i)
  }
  let def : @types.TreeDef = { kind: BST, operations: ops }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_bst_animation(def, config)
  // Should have a reasonable number of steps (at least 50 AddNode steps)
  assert_true(timeline.steps.length() >= 50)
  // All AddNode actions should have non-negative coordinates
  for i = 0; i < timeline.steps.length(); i = i + 1 {
    let step = timeline.steps[i]
    for j = 0; j < step.actions.length(); j = j + 1 {
      match step.actions[j] {
        AddNode(x~, y~, ..) => {
          assert_true(x >= 0.0)
          assert_true(y >= 0.0)
        }
        _ => ()
      }
    }
  }
}

///|
/// Test: AddNode has valid (non-negative) coordinates.
test "AddNode has valid coordinates" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3] }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_bst_animation(def, config)
  match timeline.steps[0].actions[0] {
    AddNode(x~, y~, ..) => {
      assert_true(x >= 0.0)
      assert_true(y >= 0.0)
    }
    _ => fail("Expected AddNode action")
  }
}
