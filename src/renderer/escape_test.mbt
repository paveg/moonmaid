///|
/// Test 1: Normal string passes through unchanged.
test "normal string passes through unchanged" {
  let result = escape_xml("hello world")
  assert_eq(result, "hello world")
}

///|
/// Test 2: HTML tag characters are escaped.
test "script tag is escaped" {
  let result = escape_xml("<script>")
  assert_eq(result, "&lt;script&gt;")
}

///|
/// Test 3: Ampersand is escaped.
test "ampersand is escaped" {
  let result = escape_xml("&")
  assert_eq(result, "&amp;")
}

///|
/// Test 4: Double and single quotes are escaped.
test "double quote is escaped" {
  let result = escape_xml("\"")
  assert_eq(result, "&quot;")
}

///|
/// Test 4b: Single quote is escaped.
test "single quote is escaped" {
  let result = escape_xml("'")
  assert_eq(result, "&#39;")
}

///|
/// Test 5: Empty string returns empty string.
test "empty string returns empty string" {
  let result = escape_xml("")
  assert_eq(result, "")
}

///|
/// Test 6: Combined XSS payload is fully escaped.
test "xss payload is fully escaped" {
  let result = escape_xml("<script>alert('xss')</script>")
  assert_eq(result, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}
