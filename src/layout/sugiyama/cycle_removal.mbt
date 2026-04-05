///|
/// Result of cycle removal: edges with back edges reversed, plus indices of reversed edges.
pub(all) struct AcyclicResult {
  edges : Array[(String, String)]
  reversed : Array[Int]
} derive(Show, Eq)

///|
/// Remove cycles from a directed graph by reversing back edges.
/// Uses DFS with 3 states: unvisited (0), in-stack (1), done (2).
pub fn remove_cycles(
  nodes : Array[String],
  edges : Array[(String, String)],
) -> AcyclicResult {
  let result_edges : Array[(String, String)] = []
  let reversed : Array[Int] = []
  // Build adjacency list with edge indices
  let adj : Map[String, Array[(String, Int)]] = Map::new()
  for i = 0; i < nodes.length(); i = i + 1 {
    adj[nodes[i]] = []
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (from, to) = edges[i]
    // Self-loop: immediately reverse
    if from == to {
      result_edges.push((to, from))
      reversed.push(i)
    } else {
      result_edges.push((from, to))
      match adj.get(from) {
        Some(list) => list.push((to, i))
        None => adj[from] = [(to, i)]
      }
    }
  }
  // DFS state: 0 = unvisited, 1 = in-stack, 2 = done
  let state : Map[String, Int] = Map::new()
  for i = 0; i < nodes.length(); i = i + 1 {
    state[nodes[i]] = 0
  }
  // Iterative DFS
  for i = 0; i < nodes.length(); i = i + 1 {
    let node = nodes[i]
    if state.get(node).unwrap_or(0) != 0 {
      continue
    }
    // Stack contains (node, index into adjacency list)
    let stack : Array[(String, Int)] = [(node, 0)]
    state[node] = 1
    while stack.length() > 0 {
      let top_idx = stack.length() - 1
      let (curr, edge_idx) = stack[top_idx]
      let neighbors = adj.get(curr).unwrap_or([])
      if edge_idx >= neighbors.length() {
        // Done with this node
        state[curr] = 2
        let _ = stack.pop()
      } else {
        // Advance edge index
        stack[top_idx] = (curr, edge_idx + 1)
        let (neighbor, orig_idx) = neighbors[edge_idx]
        let neighbor_state = state.get(neighbor).unwrap_or(0)
        if neighbor_state == 1 {
          // Back edge found: reverse it
          let (from, to) = result_edges[orig_idx]
          result_edges[orig_idx] = (to, from)
          reversed.push(orig_idx)
        } else if neighbor_state == 0 {
          state[neighbor] = 1
          stack.push((neighbor, 0))
        }
        // If done (2), it's a cross/forward edge, no action needed
      }
    }
  }
  { edges: result_edges, reversed }
}
