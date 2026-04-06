///|
/// Render a graph/flowchart diagram as a Virtual SVG Tree.
///
/// Layout: background rect, arrow marker + shadow defs, edges as polylines
/// with optional dash styles and labels, node shapes (rect/diamond/rounded),
/// and centered node labels.
pub fn render_graph(
  graph : @types.PositionedGraph,
  def : @types.GraphDef,
) -> SvgNode {
  let children : Array[SvgNode] = []
  let bounds = graph.bounds
  let svg_width = bounds.width
  let svg_height = bounds.height

  // Build lookup maps for edge/node metadata
  let edge_defs : Map[String, @types.GraphEdgeDef] = Map::new()
  for i = 0; i < def.edges.length(); i = i + 1 {
    let e = def.edges[i]
    let key = e.from + "->" + e.to
    edge_defs[key] = e
  }
  let node_defs : Map[String, @types.GraphNodeDef] = Map::new()
  for i = 0; i < def.nodes.length(); i = i + 1 {
    let n = def.nodes[i]
    node_defs[n.id] = n
  }

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

  // Edges (drawn behind nodes)
  for i = 0; i < graph.edges.length(); i = i + 1 {
    let edge = graph.edges[i]
    if edge.points.length() >= 2 {
      let key = edge.from_id + "->" + edge.to_id
      let style = match edge_defs.get(key) {
        Some(edef) => edef.style
        None => ""
      }
      let dash = match style {
        "dashed" => "6,4"
        "dotted" => "2,4"
        _ => ""
      }
      // Multi-waypoint edges (e.g., backward edges routed around the diagram)
      // use rounded polyline paths; simple 2-point edges use smooth bezier curves
      let path_d = if edge.points.length() > 2 {
        // Build SVG path with rounded corners through waypoints
        let buf = StringBuilder::new()
        let (x0, y0) = edge.points[0]
        buf.write_string("M \{x0} \{y0}")
        for pi = 1; pi < edge.points.length(); pi = pi + 1 {
          let (px, py) = edge.points[pi]
          buf.write_string(" L \{px} \{py}")
        }
        buf.to_string()
      } else {
        let (x1, y1) = edge.points[0]
        let (x2, y2) = edge.points[edge.points.length() - 1]
        let dx = (x2 - x1).abs()
        let dy = (y2 - y1).abs()
        // Control points: gentle S-curve
        let (cx1, cy1, cx2, cy2) = if dy > dx {
          // Mostly vertical (TD layout) — curve horizontally
          (x1, y1 + dy * 0.4, x2, y2 - dy * 0.4)
        } else {
          // Mostly horizontal (LR layout) — curve vertically
          (x1 + dx * 0.4, y1, x2 - dx * 0.4, y2)
        }
        "M \{x1} \{y1} C \{cx1} \{cy1}, \{cx2} \{cy2}, \{x2} \{y2}"
      }
      children.push(
        Path(
          d=path_d,
          fill="none",
          stroke=edge_color,
          stroke_width=1.5,
          marker_end="arrow",
          dash_array=dash,
        ),
      )
      let effective_label = if edge.label.length() > 0 {
        edge.label
      } else {
        match edge_defs.get(key) {
          Some({ weight: Some(w), .. }) => w.to_string()
          _ => ""
        }
      }
      if effective_label.length() > 0 {
        // Position label at 35% from source (biased away from target node)
        let (x1, y1) = edge.points[0]
        let (x2, y2) = edge.points[edge.points.length() - 1]
        let mx = x1 + (x2 - x1) * 0.35
        let my = y1 + (y2 - y1) * 0.35
        // White background rect behind label
        let label_width = effective_label.length().to_double() * 8.0 + 16.0
        let label_height = 20.0
        children.push(
          Rect(
            x=mx - label_width / 2.0,
            y=my - label_height / 2.0,
            width=label_width,
            height=label_height,
            rx=4.0,
            fill="#ffffff",
            stroke="none",
            stroke_width=0.0,
            filter="",
          ),
        )
        children.push(
          Text(
            x=mx,
            y=my,
            content=effective_label,
            font_size=12.0,
            fill=text_color,
            anchor="middle",
            font_family~,
          ),
        )
      }
    }
  }

  // Node shapes and labels
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    let shape = match node_defs.get(node.id) {
      Some(ndef) => ndef.shape
      None => @types.NodeShape::Rect
    }
    let cx = node.x + node.width / 2.0
    let cy = node.y + node.height / 2.0
    match shape {
      Diamond => {
        let dw = node.width * 1.2 / 2.0
        let dh = node.height * 1.2 / 2.0
        let pts : Array[(Double, Double)] = [
          (cx, cy - dh),
          (cx + dw, cy),
          (cx, cy + dh),
          (cx - dw, cy),
        ]
        children.push(
          Polygon(
            points=pts,
            fill=node_fill,
            stroke=node_stroke,
            stroke_width=1.5,
            filter=shadow_filter_id,
          ),
        )
      }
      _ => {
        let rx = match shape {
          Rounded => 20.0
          _ => 14.0
        }
        children.push(
          Rect(
            x=node.x,
            y=node.y,
            width=node.width,
            height=node.height,
            rx~,
            fill=node_fill,
            stroke=node_stroke,
            stroke_width=1.5,
            filter=shadow_filter_id,
          ),
        )
      }
    }
    // Node label
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
