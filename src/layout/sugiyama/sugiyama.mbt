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
  // 8. Update edge labels for potentially reversed edges
  let final_edge_labels : Map[String, String] = Map::new()
  for i = 0; i < acyclic.edges.length(); i = i + 1 {
    let (from, to) = acyclic.edges[i]
    let key = from + "->" + to
    // Try original direction first, then reversed
    let orig_key = if is_reversed(acyclic.reversed, i) {
      to + "->" + from
    } else {
      from + "->" + to
    }
    let label = edge_label_map.get(orig_key).unwrap_or("")
    final_edge_labels[key] = label
  }
  // 9. Assign coordinates
  let mut graph = assign_coordinates(
    ordered_layers,
    node_labels,
    acyclic.edges,
    final_edge_labels,
    config,
    transpose,
  )
  // 10. Fix reversed edges: swap arrow direction back
  let final_edges : Array[@types.PositionedEdge] = []
  for i = 0; i < graph.edges.length(); i = i + 1 {
    let edge = graph.edges[i]
    // Find if this edge corresponds to a reversed edge
    let mut was_reversed = false
    for j = 0; j < acyclic.edges.length(); j = j + 1 {
      let (from, to) = acyclic.edges[j]
      if from == edge.from_id &&
        to == edge.to_id &&
        is_reversed(acyclic.reversed, j) {
        was_reversed = true
        break
      }
    }
    if was_reversed {
      // Swap from/to and reverse points
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
    } else {
      final_edges.push(edge)
    }
  }
  graph = { nodes: graph.nodes, edges: final_edges, bounds: graph.bounds }
  graph
}

///|
fn is_reversed(reversed : Array[Int], idx : Int) -> Bool {
  for i = 0; i < reversed.length(); i = i + 1 {
    if reversed[i] == idx {
      return true
    }
  }
  false
}
