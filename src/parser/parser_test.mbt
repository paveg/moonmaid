// Blackbox tests for the parser package.

///|
test "parse array with elements" {
  let result = @parser.parse("array { [3, 1, 4] }")
  assert_eq(
    result,
    @types.Diagram::ArrayDiagram({ elements: [3, 1, 4], highlights: [] }),
  )
}

///|
test "parse array with highlights" {
  let input =
    #| array {
    #|   [1, 2, 3, 4, 5]
    #|   highlight(0..1, color=blue, label="range")
    #|   highlight(3, color=red, label="single")
    #| }
  let result = @parser.parse(input)
  assert_eq(
    result,
    @types.Diagram::ArrayDiagram({
      elements: [1, 2, 3, 4, 5],
      highlights: [
        { start: 0, end: 1, color: "blue", label: "range" },
        { start: 3, end: 3, color: "red", label: "single" },
      ],
    }),
  )
}

///|
test "parse tree bst" {
  let result = @parser.parse("tree bst { insert(5, 3, 7, 1) }")
  assert_eq(
    result,
    @types.Diagram::TreeDiagram({
      kind: @types.TreeKind::BST,
      operations: [5, 3, 7, 1],
    }),
  )
}

///|
test "parse unknown diagram type raises error" {
  let result : Result[@types.Diagram, Unit] = Ok(@parser.parse("unknown { }")) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "parse empty array" {
  let result = @parser.parse("array { [] }")
  assert_eq(
    result,
    @types.Diagram::ArrayDiagram({ elements: [], highlights: [] }),
  )
}

///|
test "parse single element array" {
  let result = @parser.parse("array { [42] }")
  assert_eq(
    result,
    @types.Diagram::ArrayDiagram({ elements: [42], highlights: [] }),
  )
}

///|
test "parse single tree insert" {
  let result = @parser.parse("tree bst { insert(1) }")
  assert_eq(
    result,
    @types.Diagram::TreeDiagram({ kind: @types.TreeKind::BST, operations: [1] }),
  )
}

///|
test "parse array size limit exceeded raises error" {
  // Build a string with 300 elements (default limit is 256)
  let buf = StringBuilder::new()
  buf.write_string("array { [")
  for i = 0; i < 300; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(i.to_string())
  }
  buf.write_string("] }")
  let input = buf.to_string()
  let result : Result[@types.Diagram, Unit] = Ok(
    @parser.parse_with_limits(input, @types.Limits::default()),
  ) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "parse tree node count limit exceeded raises error" {
  // Build a tree insert with 1025 elements (default limit is 1024)
  let buf = StringBuilder::new()
  buf.write_string("tree bst { insert(")
  for i = 0; i < 1025; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(i.to_string())
  }
  buf.write_string(") }")
  let input = buf.to_string()
  let result : Result[@types.Diagram, Unit] = Ok(
    @parser.parse_with_limits(input, @types.Limits::default()),
  ) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "parse highlight with single index" {
  let input =
    #| array {
    #|   [1, 2, 3, 4]
    #|   highlight(3, color=red, label="x")
    #| }
  let result = @parser.parse(input)
  assert_eq(
    result,
    @types.Diagram::ArrayDiagram({
      elements: [1, 2, 3, 4],
      highlights: [{ start: 3, end: 3, color: "red", label: "x" }],
    }),
  )
}

///|
test "parse tree bst @animate produces AnimatedTreeDiagram" {
  let result = @parser.parse("tree bst @animate { insert(5, 3, 7) }")
  assert_eq(
    result,
    @types.Diagram::AnimatedTreeDiagram({
      kind: @types.TreeKind::BST,
      operations: [5, 3, 7],
    }),
  )
}

///|
test "parse tree bst without @animate produces TreeDiagram" {
  let result = @parser.parse("tree bst { insert(5, 3, 7) }")
  assert_eq(
    result,
    @types.Diagram::TreeDiagram({
      kind: @types.TreeKind::BST,
      operations: [5, 3, 7],
    }),
  )
}

///|
test "parse array @animate bubble" {
  let result = @parser.parse("array @animate { [3, 1, 4] sort: bubble }")
  assert_eq(
    result,
    @types.Diagram::AnimatedArrayDiagram({
      elements: [3, 1, 4],
      algorithm: @types.SortAlgorithm::Bubble,
    }),
  )
}

///|
test "parse array @animate all sort algorithms" {
  let bubble = @parser.parse("array @animate { [1, 2] sort: bubble }")
  assert_eq(
    bubble,
    @types.Diagram::AnimatedArrayDiagram({
      elements: [1, 2],
      algorithm: @types.SortAlgorithm::Bubble,
    }),
  )
  let insertion = @parser.parse("array @animate { [1, 2] sort: insertion }")
  assert_eq(
    insertion,
    @types.Diagram::AnimatedArrayDiagram({
      elements: [1, 2],
      algorithm: @types.SortAlgorithm::Insertion,
    }),
  )
  let selection = @parser.parse("array @animate { [1, 2] sort: selection }")
  assert_eq(
    selection,
    @types.Diagram::AnimatedArrayDiagram({
      elements: [1, 2],
      algorithm: @types.SortAlgorithm::Selection,
    }),
  )
  let quick = @parser.parse("array @animate { [1, 2] sort: quick }")
  assert_eq(
    quick,
    @types.Diagram::AnimatedArrayDiagram({
      elements: [1, 2],
      algorithm: @types.SortAlgorithm::Quick,
    }),
  )
}

///|
test "parse array @animate missing sort raises error" {
  let result : Result[@types.Diagram, Unit] = Ok(
    @parser.parse("array @animate { [1, 2] }"),
  ) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "parse array @animate unknown algorithm raises error" {
  let result : Result[@types.Diagram, Unit] = Ok(
    @parser.parse("array @animate { [1, 2] sort: merge }"),
  ) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "parse static array unchanged" {
  let result = @parser.parse("array { [3, 1, 4] }")
  assert_eq(
    result,
    @types.Diagram::ArrayDiagram({ elements: [3, 1, 4], highlights: [] }),
  )
}

///|
test "parse array @animate empty elements" {
  let result = @parser.parse("array @animate { [] sort: bubble }")
  assert_eq(
    result,
    @types.Diagram::AnimatedArrayDiagram({
      elements: [],
      algorithm: @types.SortAlgorithm::Bubble,
    }),
  )
}

///|
test "parse tree bst @unknown raises error" {
  let result : Result[@types.Diagram, Unit] = Ok(
    @parser.parse("tree bst @unknown { insert(1) }"),
  ) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "parse tree bst @animate with empty insert list" {
  let result = @parser.parse("tree bst @animate { insert() }")
  assert_eq(
    result,
    @types.Diagram::AnimatedTreeDiagram({
      kind: @types.TreeKind::BST,
      operations: [],
    }),
  )
}

///|
/// Boundary: exactly 1024 operations (at node limit) succeeds.
test "parse tree at 1024 node limit succeeds" {
  let buf = StringBuilder::new()
  buf.write_string("tree bst { insert(")
  for i = 0; i < 1024; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(i.to_string())
  }
  buf.write_string(") }")
  let input = buf.to_string()
  let result = @parser.parse_with_limits(input, @types.Limits::default())
  match result {
    TreeDiagram(def) => assert_eq(def.operations.length(), 1024)
    _ => fail("Expected TreeDiagram")
  }
}

///|
/// Boundary: 1025 operations (one over node limit) raises error.
test "parse tree at 1025 nodes raises error" {
  let buf = StringBuilder::new()
  buf.write_string("tree bst { insert(")
  for i = 0; i < 1025; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(i.to_string())
  }
  buf.write_string(") }")
  let input = buf.to_string()
  let result : Result[@types.Diagram, Unit] = Ok(
    @parser.parse_with_limits(input, @types.Limits::default()),
  ) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}
