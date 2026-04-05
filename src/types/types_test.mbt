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
