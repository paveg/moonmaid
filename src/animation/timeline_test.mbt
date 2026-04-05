///|
/// Test 1: Empty timeline serializes to {"steps":[]}.
test "empty timeline to json" {
  let timeline : @types.AnimationTimeline = { steps: [] }
  let json = @animation.timeline_to_json(timeline)
  assert_eq(json, "{\"steps\":[]}")
}

///|
/// Test 2: Single step with Highlight action.
test "single step with Highlight" {
  let timeline : @types.AnimationTimeline = {
    steps: [
      {
        actions: [Highlight(node_id="node_5", color="blue")],
        description: "Highlight node 5",
        duration_ms: 400,
      },
    ],
  }
  let json = @animation.timeline_to_json(timeline)
  assert_true(json.contains("\"type\":\"Highlight\""))
  assert_true(json.contains("\"node_id\":\"node_5\""))
  assert_true(json.contains("\"color\":\"blue\""))
}

///|
/// Test 3: AddNode action includes position fields.
test "AddNode action includes position fields" {
  let timeline : @types.AnimationTimeline = {
    steps: [
      {
        actions: [
          AddNode(
            node_id="node_10",
            x=100.0,
            y=200.0,
            width=48.0,
            height=32.0,
            label="10",
          ),
        ],
        description: "Insert 10",
        duration_ms: 500,
      },
    ],
  }
  let json = @animation.timeline_to_json(timeline)
  assert_true(json.contains("\"type\":\"AddNode\""))
  assert_true(json.contains("\"x\":"))
  assert_true(json.contains("\"y\":"))
  assert_true(json.contains("\"label\":\"10\""))
}

///|
/// Test 4: Multiple steps contain both descriptions.
test "multiple steps both descriptions present" {
  let timeline : @types.AnimationTimeline = {
    steps: [
      {
        actions: [Highlight(node_id="node_5", color="#ff9800")],
        description: "Compare 3 with 5",
        duration_ms: 400,
      },
      {
        actions: [
          AddNode(
            node_id="node_3",
            x=50.0,
            y=100.0,
            width=48.0,
            height=32.0,
            label="3",
          ),
        ],
        description: "Insert 3",
        duration_ms: 500,
      },
    ],
  }
  let json = @animation.timeline_to_json(timeline)
  assert_true(json.contains("Compare 3 with 5"))
  assert_true(json.contains("Insert 3"))
}

///|
/// Test 5: Special characters in description are JSON-escaped.
test "special characters are json escaped" {
  let timeline : @types.AnimationTimeline = {
    steps: [
      {
        actions: [],
        description: "Say \"hello\" and use \\backslash",
        duration_ms: 100,
      },
    ],
  }
  let json = @animation.timeline_to_json(timeline)
  assert_true(json.contains("\\\"hello\\\""))
  assert_true(json.contains("\\\\backslash"))
}
