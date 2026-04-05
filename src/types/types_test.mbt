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
