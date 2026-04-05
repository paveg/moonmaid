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

  // Arrow marker definition
  let arrow_path = Path(
    d="M 0 0 L 10 3.5 L 0 7 z",
    fill=edge_color,
    stroke="none",
  )
  let marker = Marker(id="arrow", children=[arrow_path])
  children.push(Defs(children=[marker]))

  // Edges (drawn behind nodes)
  for i = 0; i < graph.edges.length(); i = i + 1 {
    let edge = graph.edges[i]
    if edge.points.length() >= 2 {
      children.push(
        Polyline(
          points=edge.points,
          stroke=edge_color,
          stroke_width=1.5,
          fill="none",
          marker_end="arrow",
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
        font_size=16.0,
        fill=text_color,
        anchor="middle",
        font_family~,
      ),
    )
  }

  Svg(width=svg_width, height=svg_height, children~)
}
