///|
/// Assign x/y coordinates to nodes and generate edge polylines.
/// For TD (transpose=false): y varies by layer, x varies by position.
/// For LR (transpose=true): x varies by layer, y varies by position.
pub fn assign_coordinates(
  layers : Array[Array[String]],
  node_labels : Map[String, String],
  edges : Array[(String, String)],
  edge_labels : Map[String, String],
  config : @types.LayoutConfig,
  transpose : Bool,
) -> @types.PositionedGraph {
  let nw = @types.default_node_width
  let nh = @types.default_node_height
  let padding = config.padding
  let node_spacing = config.node_spacing
  let level_spacing = config.level_spacing
  // Find max layer width for centering
  let mut max_width = 0
  for i = 0; i < layers.length(); i = i + 1 {
    if layers[i].length() > max_width {
      max_width = layers[i].length()
    }
  }
  let total_span = if max_width > 0 {
    max_width.to_double() * nw + (max_width - 1).to_double() * node_spacing
  } else {
    0.0
  }
  // Position nodes
  let positioned_nodes : Array[@types.PositionedNode] = []
  let node_pos : Map[String, (Double, Double, Double, Double)] = Map::new()
  for li = 0; li < layers.length(); li = li + 1 {
    let layer = layers[li]
    let layer_count = layer.length()
    let layer_span = layer_count.to_double() * nw +
      (layer_count - 1).to_double() * node_spacing
    let offset = (total_span - layer_span) / 2.0
    for pi = 0; pi < layer_count; pi = pi + 1 {
      let node_id = layer[pi]
      let label = node_labels.get(node_id).unwrap_or(node_id)
      let pos_in_layer = offset + pi.to_double() * (nw + node_spacing)
      let layer_coord = li.to_double() * (nh + level_spacing)
      let (x, y) = if transpose {
        (padding + layer_coord, padding + pos_in_layer)
      } else {
        (padding + pos_in_layer, padding + layer_coord)
      }
      node_pos[node_id] = (x, y, nw, nh)
      positioned_nodes.push({ id: node_id, x, y, width: nw, height: nh, label })
    }
  }
  // Generate edges
  let positioned_edges : Array[@types.PositionedEdge] = []
  for i = 0; i < edges.length(); i = i + 1 {
    let (from, to) = edges[i]
    let edge_key = from + "->" + to
    let label = edge_labels.get(edge_key).unwrap_or("")
    match (node_pos.get(from), node_pos.get(to)) {
      (Some((fx, fy, fw, fh)), Some((tx, ty, _tw, _th))) => {
        let points : Array[(Double, Double)] = if transpose {
          // LR: right-center of source to left-center of target
          [(fx + fw, fy + fh / 2.0), (tx, ty + fh / 2.0)]
        } else {
          // TD: bottom-center of source to top-center of target
          [(fx + fw / 2.0, fy + fh), (tx + fw / 2.0, ty)]
        }
        positioned_edges.push({ from_id: from, to_id: to, points, label })
      }
      _ => ()
    }
  }
  let bounds = @types.compute_bounds(positioned_nodes, padding)
  { nodes: positioned_nodes, edges: positioned_edges, bounds }
}
