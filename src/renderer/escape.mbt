///|
/// Escape XML/HTML special characters to prevent XSS injection.
/// Escapes: & < > " '
pub fn escape_xml(input : String) -> String {
  let buf = StringBuilder::new()
  let len = input.length()
  for i = 0; i < len; i = i + 1 {
    let c = Int::unsafe_to_char(input[i].to_int())
    match c {
      '&' => buf.write_string("&amp;")
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}
