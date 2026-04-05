///|
/// Test 1: render_array produces valid SVG with element and index labels.
test "render_array produces svg with element and index labels" {
  let def : @types.ArrayDef = { elements: [10, 20, 30], highlights: [] }
  let config = @types.LayoutConfig::default()
  let graph = @grid.layout(def, config)
  let node = render_array(graph, def)
  let svg = emit(node)
  // Should be a valid SVG element
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
  // Should contain element labels
  assert_true(svg.contains(">10<"))
  assert_true(svg.contains(">20<"))
  assert_true(svg.contains(">30<"))
  // Should contain index labels
  assert_true(svg.contains(">0<"))
  assert_true(svg.contains(">1<"))
  assert_true(svg.contains(">2<"))
}

///|
/// Test 2: render_tree produces SVG with polyline edges and node labels.
test "render_tree produces svg with polylines and labels" {
  let def : @types.TreeDef = { kind: BST, operations: [5, 3, 7] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  let node = render_tree(graph)
  let svg = emit(node)
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
  // Should have edges
  assert_true(svg.contains("<polyline"))
  // Should contain node labels
  assert_true(svg.contains(">5<"))
  assert_true(svg.contains(">3<"))
  assert_true(svg.contains(">7<"))
}

///|
/// Test 3: XSS in node labels is escaped.
test "xss label is escaped in tree svg" {
  // Manually create a PositionedGraph with an XSS label
  let xss_label = "<script>alert(1)</script>"
  let pg : @types.PositionedGraph = {
    nodes: [
      {
        id: "node_0",
        x: 20.0,
        y: 20.0,
        width: 48.0,
        height: 32.0,
        label: xss_label,
      },
    ],
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: 100.0, height: 80.0 },
  }
  let svg = emit(render_tree(pg))
  // The raw XSS string must not appear in the output
  assert_false(svg.contains(xss_label))
  // The escaped version should be present
  assert_true(svg.contains("&lt;script&gt;"))
}

///|
/// Test 4: Empty array renders valid SVG.
test "empty array renders valid svg" {
  let def : @types.ArrayDef = { elements: [], highlights: [] }
  let config = @types.LayoutConfig::default()
  let graph = @grid.layout(def, config)
  let node = render_array(graph, def)
  let svg = emit(node)
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
}

///|
/// Test 5: Single tree node renders without edges.
test "single tree node renders without edges" {
  let def : @types.TreeDef = { kind: BST, operations: [42] }
  let config = @types.LayoutConfig::default()
  let graph = @tree.layout(def, config)
  let node = render_tree(graph)
  let svg = emit(node)
  assert_true(svg.contains(">42<"))
  assert_false(svg.contains("<polyline"))
}

///|
/// Test 6: Valid hex colors are accepted by resolve_highlight_color.
test "valid hex colors accepted" {
  assert_eq(resolve_highlight_color("#fff"), "#fff")
  assert_eq(resolve_highlight_color("#aabbcc"), "#aabbcc")
  assert_eq(resolve_highlight_color("#AABBCC"), "#AABBCC")
  assert_eq(resolve_highlight_color("#abcd"), "#abcd")
  assert_eq(resolve_highlight_color("#aabbccdd"), "#aabbccdd")
}

///|
/// Test 7: Invalid hex colors fall back to the default fill (#f6f8fa).
test "invalid hex colors rejected" {
  let fallback = "#f6f8fa"
  // #xyz is not valid hex
  assert_eq(resolve_highlight_color("#xyz"), fallback)
  // XSS injection attempt
  assert_eq(resolve_highlight_color("#fff\" onclick=alert(1)"), fallback)
  // Too short
  assert_eq(resolve_highlight_color("#ff"), fallback)
  // Too long
  assert_eq(resolve_highlight_color("#aabbccdde"), fallback)
}
