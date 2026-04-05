///|
/// Escape XML/HTML special characters to prevent XSS injection.
/// Escapes: & < > " '
pub fn escape_xml(input : String) -> String {
  let buf = StringBuilder::new()
  let len = input.length()
  for i = 0; i < len; i = i + 1 {
    let c = Int::unsafe_to_char(input[i].to_int())
    if c == '&' {
      buf.write_string("&amp;")
    } else if c == '<' {
      buf.write_string("&lt;")
    } else if c == '>' {
      buf.write_string("&gt;")
    } else if c == '"' {
      buf.write_string("&quot;")
    } else if c == '\'' {
      buf.write_string("&#39;")
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}
