///|
/// Public API: lay out a directed graph using the Sugiyama algorithm.
/// Raises MoonmaidError if the graph is undirected.
pub fn layout(
  def : @types.GraphDef,
  config : @types.LayoutConfig,
) -> @types.PositionedGraph raise @types.MoonmaidError {
  // 1. Validate
  match def.direction {
    Undirected =>
      raise @types.MoonmaidError::of(
        "Sugiyama layout requires a directed graph",
      )
    _ => ()
  }
  // 2. Extract node IDs and edge pairs
  let node_ids : Array[String] = []
  let node_labels : Map[String, String] = Map::new()
  for i = 0; i < def.nodes.length(); i = i + 1 {
    let n = def.nodes[i]
    node_ids.push(n.id)
    node_labels[n.id] = n.label
  }
  let edge_pairs : Array[(String, String)] = []
  let edge_label_map : Map[String, String] = Map::new()
  for i = 0; i < def.edges.length(); i = i + 1 {
    let e = def.edges[i]
    edge_pairs.push((e.from, e.to))
    let key = e.from + "->" + e.to
    edge_label_map[key] = e.label
  }
  // Handle empty graph
  if node_ids.length() == 0 {
    return {
      nodes: [],
      edges: [],
      bounds: { x: 0.0, y: 0.0, width: 0.0, height: 0.0 },
    }
  }
  // 3. Cycle removal
  let acyclic = remove_cycles(node_ids, edge_pairs)
  // 4. Layer assignment
  let layer_map = assign_layers(node_ids, acyclic.edges)
  // 5. Build layer arrays
  let mut max_layer = 0
  for i = 0; i < node_ids.length(); i = i + 1 {
    let l = layer_map.get(node_ids[i]).unwrap_or(0)
    if l > max_layer {
      max_layer = l
    }
  }
  let layer_arrays : Array[Array[String]] = []
  for i = 0; i <= max_layer; i = i + 1 {
    layer_arrays.push([])
  }
  for i = 0; i < node_ids.length(); i = i + 1 {
    let node = node_ids[i]
    let l = layer_map.get(node).unwrap_or(0)
    layer_arrays[l].push(node)
  }
  // 6. Crossing minimization
  let ordered_layers = minimize_crossings(layer_arrays, acyclic.edges)
  // 7. Determine transpose
  let transpose = match def.direction {
    FlowLR => true
    _ => false
  }
  // 8. Build reversed-edge index set for O(1) lookup
  let reversed_set : Map[Int, Bool] = Map::new()
  for i = 0; i < acyclic.reversed.length(); i = i + 1 {
    reversed_set[acyclic.reversed[i]] = true
  }
  // 9. Update edge labels for potentially reversed edges
  let final_edge_labels : Map[String, String] = Map::new()
  for i = 0; i < acyclic.edges.length(); i = i + 1 {
    let (from, to) = acyclic.edges[i]
    let key = from + "->" + to
    let orig_key = if reversed_set.get(i).unwrap_or(false) {
      to + "->" + from
    } else {
      key
    }
    final_edge_labels[key] = edge_label_map.get(orig_key).unwrap_or("")
  }
  // 10. Build node shape map for layout-aware spacing
  let node_shapes : Map[String, @types.NodeShape] = Map::new()
  for i = 0; i < def.nodes.length(); i = i + 1 {
    let n = def.nodes[i]
    node_shapes[n.id] = n.shape
  }
  // 11. Assign coordinates
  let graph = assign_coordinates(
    ordered_layers,
    node_labels,
    acyclic.edges,
    final_edge_labels,
    config,
    transpose,
    node_shapes,
  )
  // 12. Fix reversed edges: build lookup from (from,to) -> reversed index
  let reversed_edge_lookup : Map[String, Bool] = Map::new()
  for i = 0; i < acyclic.edges.length(); i = i + 1 {
    if reversed_set.get(i).unwrap_or(false) {
      let (from, to) = acyclic.edges[i]
      reversed_edge_lookup[from + "->" + to] = true
    }
  }
  // Build node position lookup for backward edge routing
  let node_pos : Map[String, (Double, Double, Double, Double)] = Map::new()
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let n = graph.nodes[i]
    node_pos[n.id] = (n.x, n.y, n.width, n.height)
  }
  // Compute diagram right edge for backward edge routing
  let bounds = graph.bounds
  let route_margin = 30.0
  let final_edges : Array[@types.PositionedEdge] = []
  for i = 0; i < graph.edges.length(); i = i + 1 {
    let edge = graph.edges[i]
    let key = edge.from_id + "->" + edge.to_id
    if reversed_edge_lookup.get(key).unwrap_or(false) {
      // This is a backward edge: route around the right side of the diagram
      // The acyclic edge goes from->to (forward in layers), but the original
      // edge is to->from (backward). We reverse the points to get original direction.
      let (from_id, to_id) = (edge.to_id, edge.from_id)
      match (node_pos.get(from_id), node_pos.get(to_id)) {
        (Some((fx, fy, fw, fh)), Some((tx, ty, tw, th))) =>
          if transpose {
            // LR layout: route via bottom of diagram
            let route_y = bounds.y + bounds.height + route_margin
            let sx = fx + fw
            let sy = fy + fh / 2.0
            let ex = tx
            let ey = ty + th / 2.0
            let points : Array[(Double, Double)] = [
              (sx, sy),
              (sx, route_y),
              (ex, route_y),
              (ex, ey),
            ]
            final_edges.push({ from_id, to_id, points, label: edge.label })
          } else {
            // TD layout: route via right side of diagram
            let route_x = bounds.x + bounds.width + route_margin
            let sx = fx + fw / 2.0
            let sy = fy + fh
            let ex = tx + tw / 2.0
            let ey = ty
            let arrow_offset = 8.0
            let points : Array[(Double, Double)] = [
              (sx, sy),
              (route_x, sy),
              (route_x, ey),
              (ex, ey - arrow_offset),
            ]
            final_edges.push({ from_id, to_id, points, label: edge.label })
          }
        _ => {
          // Fallback: just reverse points
          let reversed_points : Array[(Double, Double)] = []
          for k = edge.points.length() - 1; k >= 0; k = k - 1 {
            reversed_points.push(edge.points[k])
          }
          final_edges.push({
            from_id: edge.to_id,
            to_id: edge.from_id,
            points: reversed_points,
            label: edge.label,
          })
        }
      }
    } else {
      final_edges.push(edge)
    }
  }
  // Recompute bounds to include backward edge routing paths
  let all_nodes = graph.nodes
  let mut max_x = bounds.x + bounds.width
  let mut max_y = bounds.y + bounds.height
  for i = 0; i < final_edges.length(); i = i + 1 {
    let pts = final_edges[i].points
    for j = 0; j < pts.length(); j = j + 1 {
      let (px, py) = pts[j]
      if px + config.padding > max_x {
        max_x = px + config.padding
      }
      if py + config.padding > max_y {
        max_y = py + config.padding
      }
    }
  }
  let final_bounds : @types.BoundingBox = if max_x > bounds.x + bounds.width ||
    max_y > bounds.y + bounds.height {
    {
      x: bounds.x,
      y: bounds.y,
      width: max_x - bounds.x,
      height: max_y - bounds.y,
    }
  } else {
    bounds
  }
  { nodes: all_nodes, edges: final_edges, bounds: final_bounds }
}
