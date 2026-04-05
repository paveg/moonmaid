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
  node_shapes : Map[String, @types.NodeShape],
) -> @types.PositionedGraph {
  let nh = @types.default_node_height
  let padding = config.padding
  let node_spacing = config.node_spacing
  let level_spacing = config.level_spacing
  // Precompute widths for all nodes, accounting for diamond visual expansion
  let node_widths : Map[String, Double] = Map::new()
  for i = 0; i < layers.length(); i = i + 1 {
    let layer = layers[i]
    for j = 0; j < layer.length(); j = j + 1 {
      let node_id = layer[j]
      let label = node_labels.get(node_id).unwrap_or(node_id)
      let base_width = @types.compute_node_width(label)
      // Diamond shapes extend 1.2x beyond their rect bounds in rendering
      let effective_width = match node_shapes.get(node_id) {
        Some(Diamond) => base_width * 1.2
        _ => base_width
      }
      node_widths[node_id] = effective_width
    }
  }
  // Compute layer spans (sum of node widths + spacing between nodes)
  let layer_spans : Array[Double] = []
  for i = 0; i < layers.length(); i = i + 1 {
    let layer = layers[i]
    let mut span = 0.0
    for j = 0; j < layer.length(); j = j + 1 {
      span = span + node_widths.get(layer[j]).unwrap_or(56.0)
      if j < layer.length() - 1 {
        span = span + node_spacing
      }
    }
    layer_spans.push(span)
  }
  // Find max layer span for centering
  let mut max_span = 0.0
  for i = 0; i < layer_spans.length(); i = i + 1 {
    if layer_spans[i] > max_span {
      max_span = layer_spans[i]
    }
  }
  // Position nodes
  let positioned_nodes : Array[@types.PositionedNode] = []
  let node_pos : Map[String, (Double, Double, Double, Double)] = Map::new()
  for li = 0; li < layers.length(); li = li + 1 {
    let layer = layers[li]
    let layer_count = layer.length()
    let layer_span = layer_spans[li]
    let offset = (max_span - layer_span) / 2.0
    let mut accumulated_x = offset
    for pi = 0; pi < layer_count; pi = pi + 1 {
      let node_id = layer[pi]
      let label = node_labels.get(node_id).unwrap_or(node_id)
      let nw = node_widths.get(node_id).unwrap_or(56.0)
      let pos_in_layer = accumulated_x
      accumulated_x = accumulated_x + nw + node_spacing
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
      (Some((fx, fy, fw, fh)), Some((tx, ty, tw, _th))) => {
        // Offset endpoint by marker size so arrow doesn't overlap node
        let arrow_offset = 8.0
        let points : Array[(Double, Double)] = if transpose {
          // LR: right-center of source to left-center of target
          [(fx + fw, fy + fh / 2.0), (tx - arrow_offset, ty + fh / 2.0)]
        } else {
          // TD: bottom-center of source to top-center of target
          [(fx + fw / 2.0, fy + fh), (tx + tw / 2.0, ty - arrow_offset)]
        }
        positioned_edges.push({ from_id: from, to_id: to, points, label })
      }
      _ => ()
    }
  }
  let bounds = @types.compute_bounds(positioned_nodes, padding)
  { nodes: positioned_nodes, edges: positioned_edges, bounds }
}
