///|
/// Render an array diagram as a Virtual SVG Tree.
///
/// Layout: background rect, element cells with optional highlight colors,
/// element value labels centered in cells, index labels below cells.
pub fn render_array(
  graph : @types.PositionedGraph,
  def : @types.ArrayDef,
) -> SvgNode {
  let children : Array[SvgNode] = []
  let bounds = graph.bounds
  let svg_width = bounds.width
  let svg_height = bounds.height

  // Background rect
  children.push(
    Rect(
      x=0.0,
      y=0.0,
      width=svg_width,
      height=svg_height,
      rx=0.0,
      fill=bg,
      stroke="none",
      stroke_width=0.0,
      filter="",
    ),
  )

  // Build a lookup: index -> highlight style for that index
  let n = def.elements.length()
  let highlight_styles : Array[HighlightStyle?] = Array::make(n, None)
  for h = 0; h < def.highlights.length(); h = h + 1 {
    let hi = def.highlights[h]
    let resolved = resolve_highlight_style(hi.color)
    for i = hi.start; i <= hi.end && i < n; i = i + 1 {
      highlight_styles[i] = Some(resolved)
    }
  }

  // Render nodes from the graph (elem_* and idx_* nodes)
  for ni = 0; ni < graph.nodes.length(); ni = ni + 1 {
    let node = graph.nodes[ni]
    // Determine if this is an element node or index node by id prefix
    let is_elem = node.id.has_prefix("elem_")
    let is_idx = node.id.has_prefix("idx_")
    if is_elem {
      // Parse the element index from id "elem_N"
      let idx_str = node.id[5:].to_string()
      let elem_idx = parse_int(idx_str)
      let style : HighlightStyle? = if elem_idx >= 0 &&
        elem_idx < highlight_styles.length() {
        highlight_styles[elem_idx]
      } else {
        None
      }
      let fill = match style {
        Some(s) => s.fill
        None => node_fill
      }
      let stroke = match style {
        Some(s) => s.stroke
        None => node_stroke
      }
      let label_color = match style {
        Some(s) => s.text_color
        None => text_color
      }
      let sw = match style {
        Some(_) => 2.0
        None => 1.0
      }
      let fw = match style {
        Some(_) => 600.0
        None => 500.0
      }
      let _ = fw
      // Cell rect
      children.push(
        Rect(
          x=node.x,
          y=node.y,
          width=node.width,
          height=node.height,
          rx=12.0,
          fill~,
          stroke~,
          stroke_width=sw,
          filter=shadow_filter_id,
        ),
      )
      // Element value label centered in cell
      let cx = node.x + node.width / 2.0
      let cy = node.y + node.height / 2.0
      children.push(
        Text(
          x=cx,
          y=cy,
          content=node.label,
          font_size=14.0,
          fill=label_color,
          anchor="middle",
          font_family=font_mono,
        ),
      )
    } else if is_idx {
      // Index label below cell — smaller font, muted color
      let cx = node.x + node.width / 2.0
      let cy = node.y + node.height / 2.0
      children.push(
        Text(
          x=cx,
          y=cy,
          content=node.label,
          font_size=11.0,
          fill=index_color,
          anchor="middle",
          font_family=font_mono,
        ),
      )
    }
  }

  Svg(width=svg_width, height=svg_height, children~)
}

///|
/// Parse a non-negative integer from a string.
/// Returns -1 on failure.
fn parse_int(s : String) -> Int {
  if s.length() == 0 {
    return -1
  }
  let mut result = 0
  for i = 0; i < s.length(); i = i + 1 {
    let c = Int::unsafe_to_char(s[i].to_int())
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    } else {
      return -1
    }
  }
  result
}
