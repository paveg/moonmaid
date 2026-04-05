///|
/// GFM light mode color palette.
let bg : String = "#ffffff"

///|
let node_fill : String = "#f6f8fa"

///|
let node_stroke : String = "#d1d9e0"

///|
let text_color : String = "#1f2328"

///|
let edge_color : String = "#656d76"

///|
let highlight_blue : String = "#0969da"

///|
let highlight_purple : String = "#8250df"

///|
let highlight_yellow : String = "#bf8700"

///|
let highlight_red : String = "#cf222e"

///|
let highlight_green : String = "#1a7f37"

///|
let index_color : String = "#656d76"

///|
let font_family : String = "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif"

///|
let font_mono : String = "ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace"

///|
/// Validate that a string is a well-formed hex color (#RGB, #RGBA, #RRGGBB, or #RRGGBBAA).
fn is_valid_hex_color(s : String) -> Bool {
  let len = s.length()
  if len != 4 && len != 5 && len != 7 && len != 9 {
    return false
  }
  if s[0] != '#' {
    return false
  }
  for i = 1; i < len; i = i + 1 {
    let c = Int::unsafe_to_char(s[i].to_int())
    if not(
        (c >= '0' && c <= '9') ||
        (c >= 'a' && c <= 'f') ||
        (c >= 'A' && c <= 'F'),
      ) {
      return false
    }
  }
  true
}

///|
/// Resolve a highlight color name to the GFM palette value.
/// Returns the edge_color as default for unknown names.
/// Custom hex colors are validated to prevent injection.
pub fn resolve_highlight_color(color : String) -> String {
  match color {
    "blue" => highlight_blue
    "purple" => highlight_purple
    "yellow" => highlight_yellow
    "red" => highlight_red
    "green" => highlight_green
    _ => if is_valid_hex_color(color) { color } else { node_fill }
  }
}
