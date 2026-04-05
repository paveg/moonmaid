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
/// Resolve a highlight color name to the GFM palette value.
/// Returns the edge_color as default for unknown names.
pub fn resolve_highlight_color(color : String) -> String {
  if color == "blue" {
    highlight_blue
  } else if color == "purple" {
    highlight_purple
  } else if color == "yellow" {
    highlight_yellow
  } else if color == "red" {
    highlight_red
  } else if color == "green" {
    highlight_green
  } else if color.length() > 0 && color[0] == '#' {
    // Pass through hex colors directly
    color
  } else {
    edge_color
  }
}
