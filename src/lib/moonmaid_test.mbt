// Blackbox end-to-end integration tests for the lib package.
// Exercises the full pipeline: DSL string → parse → layout → render → SVG string.

///|
/// Test 1: Array diagram renders element and index labels.
test "render array produces svg with element and index labels" {
  let svg = @lib.render("array { [3, 1, 4] }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
  assert_true(svg.contains(">3<"))
  assert_true(svg.contains(">1<"))
  assert_true(svg.contains(">4<"))
  assert_true(svg.contains(">0<"))
  assert_true(svg.contains(">1<"))
  assert_true(svg.contains(">2<"))
}

///|
/// Test 2: BST tree diagram renders node labels and polyline edges.
test "render tree bst produces svg with labels and edges" {
  let svg = @lib.render("tree bst { insert(5, 3, 7) }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
  assert_true(svg.contains(">5<"))
  assert_true(svg.contains(">3<"))
  assert_true(svg.contains(">7<"))
  assert_true(svg.contains("<polyline"))
}

///|
/// Test 3: Array with highlight — highlight color appears in SVG.
test "render array with highlight contains highlight color" {
  let input =
    #| array {
    #|   [1, 2, 3]
    #|   highlight(0, color=blue, label="x")
    #| }
  let svg = @lib.render(input)
  assert_true(svg.contains("<svg"))
  // Highlight blue resolves to #0969da
  assert_true(svg.contains("#0969da"))
}

///|
/// Test 4: Invalid input returns an error SVG (no crash) with error color.
test "render invalid input returns error svg" {
  let svg = @lib.render("invalid { }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
  assert_true(svg.contains("#cf222e"))
}

///|
/// Test 5: Empty array renders valid SVG without crash.
test "render empty array produces valid svg" {
  let svg = @lib.render("array { [] }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
}

///|
/// Test 6: Single element array renders the element label.
test "render single element array produces label" {
  let svg = @lib.render("array { [42] }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains(">42<"))
}

///|
/// Test 7: Single tree node renders label and no polyline edges.
test "render single tree node has no edges" {
  let svg = @lib.render("tree bst { insert(1) }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains(">1<"))
  assert_false(svg.contains("<polyline"))
}

///|
/// Test 8: Large array (200 elements) renders valid SVG.
test "render large array 200 elements produces valid svg" {
  let buf = StringBuilder::new()
  buf.write_string("array { [")
  for i = 0; i < 200; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(i.to_string())
  }
  buf.write_string("] }")
  let svg = @lib.render(buf.to_string())
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
}

///|
/// Test 9: Array at limit boundary (256 elements) renders valid SVG.
test "render array at 256 element limit produces valid svg" {
  let buf = StringBuilder::new()
  buf.write_string("array { [")
  for i = 0; i < 256; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(i.to_string())
  }
  buf.write_string("] }")
  let svg = @lib.render(buf.to_string())
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("</svg>"))
  assert_false(svg.contains("#cf222e"))
}

///|
/// Test 10: Array over limit (257 elements) returns error SVG.
test "render array over 256 element limit returns error svg" {
  let buf = StringBuilder::new()
  buf.write_string("array { [")
  for i = 0; i < 257; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(i.to_string())
  }
  buf.write_string("] }")
  let svg = @lib.render(buf.to_string())
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("#cf222e"))
}

///|
/// Test 11: XSS in highlight label is not reflected as raw HTML in output SVG.
/// The highlight label is stored but not rendered as visible text, so the raw
/// XSS payload must not appear verbatim anywhere in the SVG output.
test "xss in highlight label is not reflected in svg output" {
  let xss = "<script>alert(1)</script>"
  let input =
    #| array {
    #|   [1, 2, 3]
    #|   highlight(0, color=red, label="<script>alert(1)</script>")
    #| }
  let svg = @lib.render(input)
  assert_true(svg.contains("<svg"))
  // Raw XSS string must not appear verbatim
  assert_false(svg.contains(xss))
}

///|
/// Test 12: Animated tree produces HTML with controls and SVG.
test "animated tree produces html with controls and svg" {
  let html = @lib.render("tree bst @animate { insert(5, 3, 7) }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("moonmaid-controls"))
  assert_true(html.contains("<svg"))
}

///|
/// Test 13: Animated tree contains step descriptions.
test "animated tree contains step descriptions" {
  let html = @lib.render("tree bst @animate { insert(5, 3, 7) }")
  assert_true(html.contains("Insert 5"))
  assert_true(html.contains("Compare"))
}

///|
/// Test 14: Static tree does NOT contain animation controls.
test "static tree does not contain animation controls" {
  let svg = @lib.render("tree bst { insert(5, 3) }")
  assert_false(svg.contains("moonmaid-controls"))
}

///|
/// Test 15: Single animated node renders without crash.
test "animated single node renders" {
  let html = @lib.render("tree bst @animate { insert(5) }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("<svg"))
  assert_true(html.contains("Insert 5"))
}

///|
/// Test 16: Animated empty tree handles gracefully.
test "animated empty tree handles gracefully" {
  let html = @lib.render("tree bst @animate { insert() }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("<svg"))
}

///|
/// Test 17: Input exceeding 64 KiB returns an error SVG.
test "render input too large returns error svg" {
  let buf = StringBuilder::new()
  // Build a string > 65536 characters
  for i = 0; i < 100000; i = i + 1 {
    buf.write_char('x')
  }
  let svg = @lib.render(buf.to_string())
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("#cf222e"))
  assert_true(svg.contains("Input too large"))
}

///|
/// Test 18: Invalid input returns SVG with a useful error message.
test "render invalid input returns useful error message" {
  let svg = @lib.render("invalid { }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("#cf222e"))
  // Should contain a meaningful message, not just "Parse or render error"
  assert_false(svg.contains("Parse or render error"))
}

///|
/// Security regression: animated tree output never contains raw <script> tag.
test "animated tree output has no raw script tag" {
  let html = @lib.render("tree bst @animate { insert(5) }")
  assert_false(html.contains("<script>alert"))
}

///|
/// Security regression: large input (100KB) returns error SVG gracefully.
test "large input 100KB returns error svg gracefully" {
  let buf = StringBuilder::new()
  for i = 0; i < 100000; i = i + 1 {
    buf.write_char('a')
  }
  let svg = @lib.render(buf.to_string())
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("#cf222e"))
  assert_true(svg.contains("Input too large"))
}

///|
/// Security regression: invalid hex color in highlight falls back safely.
test "invalid hex color in highlight does not inject attributes" {
  let input =
    #| array {
    #|   [1, 2, 3]
    #|   highlight(0, color=fff_onclick_x, label="a")
    #| }
  let svg = @lib.render(input)
  assert_true(svg.contains("<svg"))
  // The color value should be XML-escaped, not injected as raw attribute
  assert_false(svg.contains("onclick"))
}

///|
/// Regression: overflow integer in DSL produces error SVG.
test "overflow integer in array produces error svg" {
  let svg = @lib.render("array { [1000001] }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("#cf222e"))
  assert_true(svg.contains("too large"))
}

// === Animated array e2e tests ===

///|
/// Animated bubble sort produces HTML with controls, SVG, and Compare steps.
test "animated bubble sort produces html with controls and compare" {
  let html = @lib.render("array @animate { [3, 1, 4] sort: bubble }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("moonmaid-controls"))
  assert_true(html.contains("<svg"))
  assert_true(html.contains("Compare"))
}

///|
/// Animated insertion sort produces HTML with Insert steps.
test "animated insertion sort produces html with insert steps" {
  let html = @lib.render("array @animate { [3, 1, 2] sort: insertion }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("Insert"))
}

///|
/// Animated selection sort produces HTML with animation.
test "animated selection sort produces html" {
  let html = @lib.render("array @animate { [5, 3, 1] sort: selection }")
  assert_true(html.contains("moonmaid-animated"))
}

///|
/// Animated quick sort produces HTML with pivot references.
test "animated quick sort produces html with pivot" {
  let html = @lib.render("array @animate { [3, 1, 4, 1, 5] sort: quick }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("pivot") || html.contains("Pivot"))
}

///|
/// Static array unchanged — no animation wrapper.
test "static array has no animation wrapper" {
  let svg = @lib.render("array { [1, 2, 3] }")
  assert_false(svg.contains("moonmaid-animated"))
}

///|
/// Empty animated array handles gracefully.
test "empty animated array handles gracefully" {
  let html = @lib.render("array @animate { [] sort: bubble }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("<svg"))
}

///|
/// Single element animated array handles gracefully.
test "single element animated array handles gracefully" {
  let html = @lib.render("array @animate { [42] sort: bubble }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("<svg"))
}
