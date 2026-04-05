///|
/// Render a tree diagram as a Virtual SVG Tree.
///
/// Layout: background rect, arrow marker defs, edges as polylines (behind nodes),
/// node rectangles with rounded corners, node labels centered.
pub fn render_tree(graph : @types.PositionedGraph) -> SvgNode {
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

  // Arrow marker — small filled triangle
  let arrow_path = Path(
    d="M 0 0 L 8 4 L 0 8 Z",
    fill=edge_color,
    stroke="none",
    stroke_width=0.0,
    marker_end="",
    dash_array="",
  )
  let marker = Marker(id="arrow", children=[arrow_path])
  children.push(Defs(children=[marker]))

  // Edges as smooth bezier curves (drawn behind nodes)
  for i = 0; i < graph.edges.length(); i = i + 1 {
    let edge = graph.edges[i]
    if edge.points.length() >= 2 {
      let (x1, y1) = edge.points[0]
      let (x2, y2) = edge.points[edge.points.length() - 1]
      let dy = (y2 - y1).abs()
      let bezier_d = "M \{x1} \{y1} C \{x1} \{y1 + dy * 0.4}, \{x2} \{y2 - dy * 0.4}, \{x2} \{y2}"
      children.push(
        Path(
          d=bezier_d,
          fill="none",
          stroke=edge_color,
          stroke_width=1.5,
          marker_end="arrow",
          dash_array="",
        ),
      )
    }
  }

  // Node rectangles and labels
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    children.push(
      Rect(
        x=node.x,
        y=node.y,
        width=node.width,
        height=node.height,
        rx=14.0,
        fill=node_fill,
        stroke=node_stroke,
        stroke_width=1.5,
        filter=shadow_filter_id,
      ),
    )
    let cx = node.x + node.width / 2.0
    let cy = node.y + node.height / 2.0
    children.push(
      Text(
        x=cx,
        y=cy,
        content=node.label,
        font_size=14.0,
        fill=text_color,
        anchor="middle",
        font_family~,
      ),
    )
  }

  Svg(width=svg_width, height=svg_height, children~)
}
