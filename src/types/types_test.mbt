///|
test "AnimationTimeline with one step" {
  let action = @types.AnimationAction::Highlight(node_id="n1", color="red")
  let step = @types.AnimationStep::{
    actions: [action],
    description: "highlight root",
    duration_ms: 500,
  }
  let timeline = @types.AnimationTimeline::{ steps: [step] }
  assert_eq(timeline.steps.length(), 1)
  assert_eq(timeline.steps[0].description, "highlight root")
  assert_eq(timeline.steps[0].duration_ms, 500)
  assert_eq(timeline.steps[0].actions.length(), 1)
}

///|
test "AnimationTimeline empty" {
  let timeline = @types.AnimationTimeline::{ steps: [] }
  assert_eq(timeline.steps.length(), 0)
}

///|
test "ArrayAnimDef construction" {
  let def : @types.ArrayAnimDef = {
    elements: [3, 1, 4],
    algorithm: @types.SortAlgorithm::Bubble,
  }
  assert_eq(def.elements, [3, 1, 4])
  assert_eq(def.algorithm, @types.SortAlgorithm::Bubble)
}

///|
test "SortAlgorithm all variants" {
  assert_eq(@types.SortAlgorithm::Bubble, @types.SortAlgorithm::Bubble)
  assert_eq(@types.SortAlgorithm::Insertion, @types.SortAlgorithm::Insertion)
  assert_eq(@types.SortAlgorithm::Selection, @types.SortAlgorithm::Selection)
  assert_eq(@types.SortAlgorithm::Quick, @types.SortAlgorithm::Quick)
  inspect(@types.SortAlgorithm::Bubble, content="Bubble")
  inspect(@types.SortAlgorithm::Insertion, content="Insertion")
  inspect(@types.SortAlgorithm::Selection, content="Selection")
  inspect(@types.SortAlgorithm::Quick, content="Quick")
}

///|
test "AnimationStep with multiple actions" {
  let actions : Array[@types.AnimationAction] = [
    @types.AnimationAction::Highlight(node_id="n1", color="blue"),
    @types.AnimationAction::TraverseEdge(from="n1", to="n2", color="green"),
    @types.AnimationAction::Unhighlight(node_id="n1"),
  ]
  let step = @types.AnimationStep::{
    actions,
    description: "traverse from n1 to n2",
    duration_ms: 1000,
  }
  assert_eq(step.actions.length(), 3)
  assert_eq(
    step.actions[0],
    @types.AnimationAction::Highlight(node_id="n1", color="blue"),
  )
  assert_eq(
    step.actions[1],
    @types.AnimationAction::TraverseEdge(from="n1", to="n2", color="green"),
  )
  assert_eq(step.actions[2], @types.AnimationAction::Unhighlight(node_id="n1"))
}

///|
test "estimate_text_width ASCII" {
  let w = @types.estimate_text_width("Hello", 16.0)
  assert_true(w > 30.0) // 5 chars * ~8.5px
  assert_true(w < 60.0)
}

///|
test "estimate_text_width Japanese" {
  let w = @types.estimate_text_width("処理", 16.0)
  assert_true(w > 25.0) // 2 CJK chars * ~16px
}

///|
test "compute_node_width short label" {
  let w = @types.compute_node_width("A")
  assert_eq(w, @types.default_node_width) // min width
}

///|
test "compute_node_width long label" {
  let w = @types.compute_node_width("This is a long label")
  assert_true(w > @types.default_node_width)
}

///|
test "compute_node_width Japanese label" {
  let w = @types.compute_node_width("データ処理を実行")
  assert_true(w > 100.0)
}

///|
test "GraphDef with Directed direction" {
  let def : @types.GraphDef = {
    direction: @types.GraphDirection::Directed,
    nodes: [
      { id: "A", label: "A", shape: @types.NodeShape::Rect },
      { id: "B", label: "B", shape: @types.NodeShape::Rect },
    ],
    edges: [{ from: "A", to: "B", weight: None, style: "solid", label: "" }],
  }
  assert_eq(def.direction, @types.GraphDirection::Directed)
  assert_eq(def.nodes.length(), 2)
  assert_eq(def.edges.length(), 1)
}

///|
test "GraphNodeDef with Diamond shape" {
  let node : @types.GraphNodeDef = {
    id: "D1",
    label: "Decision?",
    shape: @types.NodeShape::Diamond,
  }
  assert_eq(node.id, "D1")
  assert_eq(node.label, "Decision?")
  assert_eq(node.shape, @types.NodeShape::Diamond)
}

///|
test "GraphEdgeDef with weight and label" {
  let edge : @types.GraphEdgeDef = {
    from: "A",
    to: "B",
    weight: Some(5),
    style: "dashed",
    label: "Yes",
  }
  assert_eq(edge.from, "A")
  assert_eq(edge.to, "B")
  assert_eq(edge.weight, Some(5))
  assert_eq(edge.style, "dashed")
  assert_eq(edge.label, "Yes")
}
