///|
/// Eraser.io-inspired modern clean color palette with Tailwind pastel colors.
let bg : String = "transparent"

///|
let node_fill : String = "#ffffff"

///|
let node_stroke : String = "#e2e8f0"

///|
let text_color : String = "#334155"

///|
let edge_color : String = "#cbd5e1"

///|
let index_color : String = "#94a3b8"

///|
let font_family : String = "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"

///|
let font_mono : String = "ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace"

///|
/// SVG filter id for the drop shadow applied to node rectangles.
let shadow_filter_id : String = "shadow"

///|
/// SVG filter definition for the drop shadow.
let shadow_filter_def : String = "<filter id=\"shadow\" x=\"-10%\" y=\"-10%\" width=\"130%\" height=\"140%\"><feDropShadow dx=\"0\" dy=\"2\" stdDeviation=\"3\" flood-color=\"#000000\" flood-opacity=\"0.08\"/></filter>"

///|
/// A highlight style comprising fill, stroke, and text color.
pub(all) struct HighlightStyle {
  fill : String
  stroke : String
  text_color : String
} derive(Show, Eq)

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
/// Resolve a highlight color name to a HighlightStyle with fill, stroke, and text color.
pub fn resolve_highlight_style(color : String) -> HighlightStyle {
  match color {
    "blue" => { fill: "#dbeafe", stroke: "#93c5fd", text_color: "#1e40af" }
    "green" => { fill: "#dcfce7", stroke: "#86efac", text_color: "#166534" }
    "yellow" => { fill: "#fef9c3", stroke: "#fde047", text_color: "#854d0e" }
    "red" => { fill: "#fee2e2", stroke: "#fca5a5", text_color: "#991b1b" }
    "purple" => { fill: "#ede9fe", stroke: "#c4b5fd", text_color: "#5b21b6" }
    _ =>
      if is_valid_hex_color(color) {
        { fill: color, stroke: color, text_color: "#ffffff" }
      } else {
        { fill: node_fill, stroke: node_stroke, text_color }
      }
  }
}

///|
/// Legacy wrapper: resolve a highlight color name to a single fill color.
/// Used in tests that check for specific hex values.
pub fn resolve_highlight_color(color : String) -> String {
  resolve_highlight_style(color).fill
}
