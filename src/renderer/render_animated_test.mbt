///|
/// Test 1: Output contains essential structural elements.
test "render_animated contains svg, timeline, controls, description" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3, 7] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  let timeline = @animation.generate_bst_animation(def, config)
  let html = render_animated(graph, timeline)
  assert_true(html.contains("<svg"))
  assert_true(html.contains("</svg>"))
  assert_true(html.contains("moonmaidTimeline") || html.contains("timeline"))
  assert_true(html.contains("moonmaid-controls"))
  assert_true(html.contains("moonmaid-description"))
}

///|
/// Test 2: SVG nodes have data-node-id, edges have data-edge-id.
test "render_animated svg has data-node-id and data-edge-id" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3, 7] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  let timeline = @animation.generate_bst_animation(def, config)
  let html = render_animated(graph, timeline)
  assert_true(html.contains("data-node-id"))
  assert_true(html.contains("data-edge-id"))
}

///|
/// Test 3: Empty timeline produces SVG (final state) without crash.
test "render_animated empty timeline shows svg" {
  let def : @types.TreeDef = { kind: BST, operations: [5] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  let empty_timeline : @types.AnimationTimeline = { steps: [] }
  let html = render_animated(graph, empty_timeline)
  assert_true(html.contains("<svg"))
  assert_true(html.contains("</svg>"))
  assert_true(html.contains("moonmaid-controls"))
}

///|
/// Test 4: XSS in step description is escaped (no raw <script> in output).
test "render_animated xss in description is escaped" {
  let xss_timeline : @types.AnimationTimeline = {
    steps: [
      {
        actions: [],
        description: "<script>alert(1)</script>",
        duration_ms: 400,
      },
    ],
  }
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "node_1", x: 20.0, y: 20.0, width: 48.0, height: 32.0, label: "1" },
    ],
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: 100.0, height: 80.0 },
  }
  let html = render_animated(graph, xss_timeline)
  // Raw <script> must NOT appear — it should be escaped in the JSON
  assert_false(html.contains("<script>alert"))
}

///|
/// Test 5: Output contains style block with .mm-btn.
test "render_animated contains style with mm-btn" {
  let graph : @types.PositionedGraph = {
    nodes: [],
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: 100.0, height: 80.0 },
  }
  let timeline : @types.AnimationTimeline = { steps: [] }
  let html = render_animated(graph, timeline)
  assert_true(html.contains("<style>"))
  assert_true(html.contains(".mm-btn"))
}
