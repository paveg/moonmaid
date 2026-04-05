///|
/// Minimize edge crossings using the barycenter heuristic.
/// Sweeps top-down then bottom-up, 4 iterations total.
pub fn minimize_crossings(
  layers : Array[Array[String]],
  edges : Array[(String, String)],
) -> Array[Array[String]] {
  if layers.length() <= 1 {
    return layers
  }
  // Build adjacency maps (both directions)
  let down_neighbors : Map[String, Array[String]] = Map::new()
  let up_neighbors : Map[String, Array[String]] = Map::new()
  for i = 0; i < edges.length(); i = i + 1 {
    let (from, to) = edges[i]
    match down_neighbors.get(from) {
      Some(list) => list.push(to)
      None => down_neighbors[from] = [to]
    }
    match up_neighbors.get(to) {
      Some(list) => list.push(from)
      None => up_neighbors[to] = [from]
    }
  }
  // Build position lookup for a layer
  let result : Array[Array[String]] = []
  for i = 0; i < layers.length(); i = i + 1 {
    let layer = layers[i]
    let copy : Array[String] = []
    for j = 0; j < layer.length(); j = j + 1 {
      copy.push(layer[j])
    }
    result.push(copy)
  }
  // 4 iterations: alternate top-down and bottom-up
  for iter = 0; iter < 4; iter = iter + 1 {
    if iter % 2 == 0 {
      // Top-down sweep
      for li = 1; li < result.length(); li = li + 1 {
        sort_layer_by_barycenter(result, li, result[li - 1], up_neighbors)
      }
    } else {
      // Bottom-up sweep
      for li = result.length() - 2; li >= 0; li = li - 1 {
        sort_layer_by_barycenter(result, li, result[li + 1], down_neighbors)
      }
    }
  }
  result
}

///|
fn sort_layer_by_barycenter(
  layers : Array[Array[String]],
  layer_idx : Int,
  fixed_layer : Array[String],
  neighbor_map : Map[String, Array[String]],
) -> Unit {
  // Build position map for fixed layer
  let pos : Map[String, Double] = Map::new()
  for i = 0; i < fixed_layer.length(); i = i + 1 {
    pos[fixed_layer[i]] = i.to_double()
  }
  let layer = layers[layer_idx]
  // Compute barycenter for each node
  let barycenters : Map[String, Double] = Map::new()
  for i = 0; i < layer.length(); i = i + 1 {
    let node = layer[i]
    let neighbors = neighbor_map.get(node).unwrap_or([])
    let mut sum = 0.0
    let mut count = 0
    for j = 0; j < neighbors.length(); j = j + 1 {
      match pos.get(neighbors[j]) {
        Some(p) => {
          sum = sum + p
          count = count + 1
        }
        None => ()
      }
    }
    if count > 0 {
      barycenters[node] = sum / count.to_double()
    } else {
      // Keep original position
      barycenters[node] = i.to_double()
    }
  }
  // Insertion sort by barycenter (stable sort)
  for i = 1; i < layer.length(); i = i + 1 {
    let key = layer[i]
    let key_val = barycenters.get(key).unwrap_or(0.0)
    let mut j = i - 1
    while j >= 0 && barycenters.get(layer[j]).unwrap_or(0.0) > key_val {
      layer[j + 1] = layer[j]
      j = j - 1
    }
    layer[j + 1] = key
  }
}
