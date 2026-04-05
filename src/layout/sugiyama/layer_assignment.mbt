///|
/// Assign each node to a layer using longest-path layering.
/// Sources (no predecessors) get layer 0. Each other node gets
/// max(layer[pred] + 1) across all predecessors.
pub fn assign_layers(
  nodes : Array[String],
  edges : Array[(String, String)],
) -> Map[String, Int] {
  if nodes.length() == 0 {
    return Map::new()
  }
  // Build predecessor map
  let preds : Map[String, Array[String]] = Map::new()
  for i = 0; i < nodes.length(); i = i + 1 {
    preds[nodes[i]] = []
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (from, to) = edges[i]
    match preds.get(to) {
      Some(list) => list.push(from)
      None => preds[to] = [from]
    }
  }
  // Find sources (no predecessors)
  let layers : Map[String, Int] = Map::new()
  let queue : Array[String] = []
  for i = 0; i < nodes.length(); i = i + 1 {
    let node = nodes[i]
    let pred_list = preds.get(node).unwrap_or([])
    if pred_list.length() == 0 {
      layers[node] = 0
      queue.push(node)
    }
  }
  // Build successor map for BFS traversal
  let succs : Map[String, Array[String]] = Map::new()
  for i = 0; i < nodes.length(); i = i + 1 {
    succs[nodes[i]] = []
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (from, to) = edges[i]
    match succs.get(from) {
      Some(list) => list.push(to)
      None => succs[from] = [to]
    }
  }
  // In-degree tracking for topological BFS
  let in_degree : Map[String, Int] = Map::new()
  for i = 0; i < nodes.length(); i = i + 1 {
    let node = nodes[i]
    in_degree[node] = preds.get(node).unwrap_or([]).length()
  }
  // BFS (Kahn's algorithm style)
  let mut qi = 0
  while qi < queue.length() {
    let curr = queue[qi]
    qi = qi + 1
    let curr_layer = layers.get(curr).unwrap_or(0)
    let children = succs.get(curr).unwrap_or([])
    for j = 0; j < children.length(); j = j + 1 {
      let child = children[j]
      let new_layer = curr_layer + 1
      let old_layer = layers.get(child).unwrap_or(0)
      if new_layer > old_layer {
        layers[child] = new_layer
      }
      // Decrement in-degree
      let deg = in_degree.get(child).unwrap_or(1) - 1
      in_degree[child] = deg
      if deg == 0 {
        queue.push(child)
      }
    }
  }
  // Handle isolated nodes not yet assigned
  for i = 0; i < nodes.length(); i = i + 1 {
    let node = nodes[i]
    match layers.get(node) {
      None => layers[node] = 0
      Some(_) => ()
    }
  }
  layers
}
