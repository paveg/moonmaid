///|
/// Dagre layout adapter: bridges moonmaid's GraphDef to diago's Dagre engine.

///|
/// Convert moonmaid direction to diago direction.
fn to_diago_direction(dir : @types.GraphDirection) -> @engine_api.Direction {
  match dir {
    FlowLR => @engine_api.Right
    // FlowTD, Directed, Undirected all default to top-down
    _ => @engine_api.Down
  }
}

///|
/// Convert a moonmaid NodeShape to a diago ShapeType.
fn to_diago_shape(shape : @types.NodeShape) -> @diago_graph.ShapeType {
  match shape {
    Rect => @diago_graph.Rectangle
    Diamond => @diago_graph.Diamond
    Rounded => @diago_graph.Rectangle
  }
}

///|
/// Layout a graph using diago's Dagre engine.
pub fn layout_with_dagre(
  def : @types.GraphDef,
  config : @types.LayoutConfig,
) -> @types.PositionedGraph raise @types.MoonmaidError {
  if def.nodes.length() == 0 {
    return {
      nodes: [],
      edges: [],
      bounds: { x: 0.0, y: 0.0, width: 0.0, height: 0.0 },
    }
  }
  // Build diago GraphInput
  let objects : Array[@diago_graph.ObjectInput] = []
  let root_child_ids : Array[String] = []
  for node in def.nodes {
    let w = @types.compute_node_width(node.label)
    let h = @types.default_node_height
    let obj = @diago_graph.ObjectInput::from_parts(
      node.id,
      node.label,
      to_diago_shape(node.shape),
      @diago_graph.StyleInput::new(),
      Some(@diago_graph.Box::new(0.0, 0.0, w, h)),
      None,
      [],
      0,
      None,
      None,
      None,
      [],
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
    )
    objects.push(obj)
    root_child_ids.push(node.id)
  }
  let edges : Array[@diago_graph.EdgeInput] = []
  for i, edge in def.edges {
    let is_directed = match def.direction {
      Undirected => false
      _ => true
    }
    let e = @diago_graph.EdgeInput::new(
      i,
      edge.from,
      edge.to,
      false,
      is_directed,
    )
    edges.push(e)
  }
  let root = @diago_graph.ObjectInput::from_parts(
    "root",
    "root",
    @diago_graph.Rectangle,
    @diago_graph.StyleInput::new(),
    None,
    None,
    root_child_ids,
    0,
    None,
    None,
    None,
    [],
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  )
  let graph_input = @diago_graph.GraphInput::from_parts(
    "moonmaid",
    root,
    objects,
    edges,
    [],
    [],
    [],
    [],
    [],
    [],
    [],
    None,
  )
  // Configure diago layout — use minimal spacing
  let diago_config = @engine_api.LayoutConfig::with_spacing(30.0, 40.0)
  let direction = to_diago_direction(def.direction)
  // Run Dagre layout
  let laid_out = @engine_api.layout_with_engine(
    @engine_dagre.DagreEngine::new(),
    graph_input,
    diago_config,
    direction,
  ) catch {
    e => raise @types.MoonmaidError::of("Dagre layout failed: \{e}")
  }
  // Convert results back to moonmaid types
  convert_result(laid_out, def, config.padding)
}

///|
/// Arrow marker size used to offset edge endpoints from node boundaries.
let arrow_offset : Double = 8.0

///|
/// Extract positioned nodes and edges from diago's laid-out GraphInput.
fn convert_result(
  laid_out : @diago_graph.GraphInput,
  def : @types.GraphDef,
  padding : Double,
) -> @types.PositionedGraph {
  let nodes : Array[@types.PositionedNode] = []
  // Build a label lookup from the original def
  let label_map : Map[String, String] = {}
  for node in def.nodes {
    label_map[node.id] = node.label
  }
  for obj in laid_out.objects {
    match obj.box {
      Some(b) => {
        let label = match label_map.get(obj.id) {
          Some(l) => l
          None => obj.label
        }
        nodes.push({
          id: obj.id,
          x: b.x,
          y: b.y,
          width: b.width,
          height: b.height,
          label,
        })
      }
      None => ()
    }
  }
  // Build node lookup by id for edge clipping
  let node_map : Map[String, @types.PositionedNode] = {}
  for node in nodes {
    node_map[node.id] = node
  }
  let is_lr = def.direction == FlowLR
  let positioned_edges : Array[@types.PositionedEdge] = []
  for edge in laid_out.edges {
    let points : Array[(Double, Double)] = []
    for pt in edge.route {
      points.push((pt.x, pt.y))
    }
    // Clip edge endpoints to node boundaries
    if points.length() >= 2 {
      let src_node = node_map.get(edge.src_id)
      let tgt_node = node_map.get(edge.dst_id)
      // Detect backward edge (target is above source in TD, or left of source in LR)
      let is_backward = match (src_node, tgt_node) {
        (Some(s), Some(t)) => if is_lr { t.x < s.x } else { t.y < s.y }
        _ => false
      }
      // Clip source (first point)
      match src_node {
        Some(src) =>
          if is_backward {
            // Backward: exit from right side of source
            if is_lr {
              points[0] = (src.x, src.y + src.height / 2.0)
            } else {
              points[0] = (src.x + src.width, src.y + src.height / 2.0)
            }
            // Forward: exit from bottom (TD) or right (LR)
          } else if is_lr {
            points[0] = (src.x + src.width, src.y + src.height / 2.0)
          } else {
            points[0] = (src.x + src.width / 2.0, src.y + src.height)
          }
        None => ()
      }
      // Clip target (last point)
      let last = points.length() - 1
      match tgt_node {
        Some(tgt) =>
          if is_backward {
            // Backward: enter right side of target
            if is_lr {
              points[last] = (
                tgt.x + tgt.width + arrow_offset,
                tgt.y + tgt.height / 2.0,
              )
            } else {
              points[last] = (
                tgt.x + tgt.width + arrow_offset,
                tgt.y + tgt.height / 2.0,
              )
            }
            // Forward: enter top (TD) or left (LR)
          } else if is_lr {
            points[last] = (tgt.x - arrow_offset, tgt.y + tgt.height / 2.0)
          } else {
            points[last] = (tgt.x + tgt.width / 2.0, tgt.y - arrow_offset)
          }
        None => ()
      }
    }
    // Find original label
    let mut label = ""
    for orig_edge in def.edges {
      if orig_edge.from == edge.src_id && orig_edge.to == edge.dst_id {
        label = orig_edge.label
        break
      }
    }
    positioned_edges.push({
      from_id: edge.src_id,
      to_id: edge.dst_id,
      points,
      label,
    })
  }
  // Build shape lookup for diamond expansion
  let shape_map : Map[String, @types.NodeShape] = {}
  for node in def.nodes {
    shape_map[node.id] = node.shape
  }
  // Find minimum x/y considering diamond vertex expansion and edge points
  let mut min_x = 0.0
  let mut min_y = 0.0
  for node in nodes {
    let mut left = node.x
    match shape_map.get(node.id) {
      Some(Diamond) =>
        // Diamond left vertex extends beyond node rect
        left = node.x - node.width * 0.1
      _ => ()
    }
    if left < min_x {
      min_x = left
    }
    if node.y < min_y {
      min_y = node.y
    }
  }
  // Include edge points in min bounds (bezier control points may go negative)
  for edge in positioned_edges {
    for pt in edge.points {
      if pt.0 < min_x {
        min_x = pt.0
      }
      if pt.1 < min_y {
        min_y = pt.1
      }
    }
  }
  // Shift all coordinates so nothing is negative, plus padding
  let shift_x = if min_x < padding { padding - min_x } else { 0.0 }
  let shift_y = if min_y < padding { padding - min_y } else { 0.0 }
  if shift_x > 0.0 || shift_y > 0.0 {
    for i = 0; i < nodes.length(); i = i + 1 {
      let n = nodes[i]
      nodes[i] = { ..n, x: n.x + shift_x, y: n.y + shift_y }
    }
    for i = 0; i < positioned_edges.length(); i = i + 1 {
      let e = positioned_edges[i]
      let shifted_points : Array[(Double, Double)] = []
      for pt in e.points {
        shifted_points.push((pt.0 + shift_x, pt.1 + shift_y))
      }
      positioned_edges[i] = { ..e, points: shifted_points }
    }
  }
  // Compute bounds with extra margin for diamond vertices and edge points
  let mut max_x = 0.0
  let mut max_y = 0.0
  for node in nodes {
    let mut right = node.x + node.width
    match shape_map.get(node.id) {
      Some(Diamond) => right = right + node.width * 0.1
      _ => ()
    }
    if right > max_x {
      max_x = right
    }
    let bottom = node.y + node.height
    if bottom > max_y {
      max_y = bottom
    }
  }
  // Expand bounds to include all edge points (bezier control points may exceed node rects)
  for edge in positioned_edges {
    for pt in edge.points {
      if pt.0 > max_x {
        max_x = pt.0
      }
      if pt.1 > max_y {
        max_y = pt.1
      }
    }
  }
  let bounds : @types.BoundingBox = {
    x: 0.0,
    y: 0.0,
    width: max_x + padding,
    height: max_y + padding,
  }
  { nodes, edges: positioned_edges, bounds }
}
