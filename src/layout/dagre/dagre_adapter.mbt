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
  // Configure diago layout
  let diago_config = @engine_api.LayoutConfig::with_spacing(
    config.node_spacing + 40.0,
    config.level_spacing + 60.0,
  )
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
  let positioned_edges : Array[@types.PositionedEdge] = []
  for edge in laid_out.edges {
    let points : Array[(Double, Double)] = []
    for pt in edge.route {
      points.push((pt.x, pt.y))
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
  let bounds = @types.compute_bounds(nodes, padding)
  { nodes, edges: positioned_edges, bounds }
}
