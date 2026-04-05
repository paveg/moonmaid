// Tests for sort animation generation.

///|
fn has_action_type(
  timeline : @types.AnimationTimeline,
  check : (@types.AnimationAction) -> Bool,
) -> Bool {
  for i = 0; i < timeline.steps.length(); i = i + 1 {
    let step = timeline.steps[i]
    for j = 0; j < step.actions.length(); j = j + 1 {
      if check(step.actions[j]) {
        return true
      }
    }
  }
  false
}

///|
fn has_compare(timeline : @types.AnimationTimeline) -> Bool {
  has_action_type(timeline, fn(a) {
    match a {
      CompareNodes(..) => true
      _ => false
    }
  })
}

///|
fn has_swap(timeline : @types.AnimationTimeline) -> Bool {
  has_action_type(timeline, fn(a) {
    match a {
      SwapNodes(..) => true
      _ => false
    }
  })
}

///|
fn has_description_containing(
  timeline : @types.AnimationTimeline,
  text : String,
) -> Bool {
  for i = 0; i < timeline.steps.length(); i = i + 1 {
    if timeline.steps[i].description.contains(text) {
      return true
    }
  }
  false
}

// === Bubble sort tests ===

///|
/// Bubble sort [3,1,2] produces Compare and Swap steps.
test "bubble sort basic produces compare and swap" {
  let def : @types.ArrayAnimDef = { elements: [3, 1, 2], algorithm: Bubble }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
  assert_true(has_compare(timeline))
  assert_true(has_swap(timeline))
  assert_true(has_description_containing(timeline, "Compare"))
}

///|
/// Bubble sort on already sorted array has no SwapNodes.
test "bubble sort already sorted has no swap" {
  let def : @types.ArrayAnimDef = { elements: [1, 2, 3], algorithm: Bubble }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
  assert_false(has_swap(timeline))
}

///|
/// Bubble sort on empty array produces empty timeline.
test "bubble sort empty array" {
  let def : @types.ArrayAnimDef = { elements: [], algorithm: Bubble }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

///|
/// Bubble sort on single element produces empty timeline.
test "bubble sort single element" {
  let def : @types.ArrayAnimDef = { elements: [42], algorithm: Bubble }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

// === Insertion sort tests ===

///|
/// Insertion sort [3,1,2] produces Insert steps.
test "insertion sort basic produces insert steps" {
  let def : @types.ArrayAnimDef = { elements: [3, 1, 2], algorithm: Insertion }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
  assert_true(has_description_containing(timeline, "Insert"))
  assert_true(has_compare(timeline))
}

///|
/// Insertion sort on empty array produces empty timeline.
test "insertion sort empty array" {
  let def : @types.ArrayAnimDef = { elements: [], algorithm: Insertion }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

// === Selection sort tests ===

///|
/// Selection sort [3,1,2] mentions minimum.
test "selection sort basic mentions minimum" {
  let def : @types.ArrayAnimDef = { elements: [3, 1, 2], algorithm: Selection }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
  assert_true(has_description_containing(timeline, "minimum"))
}

///|
/// Selection sort on empty array produces empty timeline.
test "selection sort empty array" {
  let def : @types.ArrayAnimDef = { elements: [], algorithm: Selection }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

// === Quick sort tests ===

///|
/// Quick sort [3,1,4,1,5] mentions pivot.
test "quick sort basic mentions pivot" {
  let def : @types.ArrayAnimDef = {
    elements: [3, 1, 4, 1, 5],
    algorithm: Quick,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
  assert_true(
    has_description_containing(timeline, "pivot") ||
    has_description_containing(timeline, "Pivot"),
  )
}

///|
/// Quick sort on empty array produces empty timeline.
test "quick sort empty array" {
  let def : @types.ArrayAnimDef = { elements: [], algorithm: Quick }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

///|
/// Quick sort on single element produces empty timeline.
test "quick sort single element" {
  let def : @types.ArrayAnimDef = { elements: [1], algorithm: Quick }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

///|
/// Quick sort on already sorted array completes without error.
test "quick sort already sorted" {
  let def : @types.ArrayAnimDef = { elements: [1, 2, 3], algorithm: Quick }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
}

// === Cross-cutting test ===

///|
/// All 4 algorithms produce non-empty timeline for [5,3,1].
test "all algorithms produce non-empty timeline" {
  let config = @types.LayoutConfig::default()
  let algorithms : Array[@types.SortAlgorithm] = [
    Bubble,
    Insertion,
    Selection,
    Quick,
  ]
  for i = 0; i < algorithms.length(); i = i + 1 {
    let def : @types.ArrayAnimDef = {
      elements: [5, 3, 1],
      algorithm: algorithms[i],
    }
    let timeline = @animation.generate_sort_animation(def, config)
    assert_true(timeline.steps.length() > 0)
  }
}
