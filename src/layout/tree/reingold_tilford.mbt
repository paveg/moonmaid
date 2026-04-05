///|
/// Node dimensions for tree nodes.
let node_width : Double = 48.0

///|
let node_height : Double = 32.0

///|
/// Internal BST node used during layout computation.
priv struct BSTNode {
  value : Int
  mut left : BSTNode?
  mut right : BSTNode?
  mut x : Double
  mut y : Double
}

///|
/// Create a new BST node.
fn BSTNode::new(value : Int) -> BSTNode {
  { value, left: None, right: None, x: 0.0, y: 0.0 }
}

///|
/// Insert a value into the BST, ignoring duplicates.
fn insert(root : BSTNode?, value : Int) -> BSTNode {
  match root {
    None => BSTNode::new(value)
    Some(node) =>
      if value < node.value {
        node.left = Some(insert(node.left, value))
        node
      } else if value > node.value {
        node.right = Some(insert(node.right, value))
        node
      } else {
        // Duplicate — ignore
        node
      }
  }
}

///|
/// Prepend a value to the front of a contour (Array[Double]),
/// then append all elements from the source contour.
fn prepend_contour(head : Double, tail : Array[Double]) -> Array[Double] {
  let result : Array[Double] = [head]
  for i = 0; i < tail.length(); i = i + 1 {
    result.push(tail[i])
  }
  result
}

///|
/// First pass: assign relative x-coordinates bottom-up.
/// Returns the left and right contours of the subtree as Array[Double].
fn first_pass(node : BSTNode, depth : Int) -> (Array[Double], Array[Double]) {
  node.y = depth.to_double()
  match (node.left, node.right) {
    (None, None) => {
      node.x = 0.0
      ([0.0], [0.0])
    }
    (Some(left), None) => {
      let (ll, lr) = first_pass(left, depth + 1)
      node.x = left.x + 1.0
      (prepend_contour(node.x, ll), prepend_contour(node.x, lr))
    }
    (None, Some(right)) => {
      let (rl, rr) = first_pass(right, depth + 1)
      node.x = right.x - 1.0
      (prepend_contour(node.x, rl), prepend_contour(node.x, rr))
    }
    (Some(left), Some(right)) => {
      let (ll, lr) = first_pass(left, depth + 1)
      let (rl, rr) = first_pass(right, depth + 1)
      // Find minimum separation so no two nodes at the same depth overlap.
      let min_len = if lr.length() < rl.length() {
        lr.length()
      } else {
        rl.length()
      }
      let mut needed_sep = 2.0 // minimum 2 units apart
      for i = 0; i < min_len; i = i + 1 {
        let sep = lr[i] - rl[i] + 1.0
        if sep > needed_sep {
          needed_sep = sep
        }
      }
      // Ensure subtree contours don't cross the root position
      for i = 0; i < lr.length(); i = i + 1 {
        let req = lr[i] + 0.5
        if req > needed_sep / 2.0 {
          needed_sep = req * 2.0
        }
      }
      for i = 0; i < rl.length(); i = i + 1 {
        let req = -rl[i] + 0.5
        if req > needed_sep / 2.0 {
          needed_sep = req * 2.0
        }
      }
      let half = needed_sep / 2.0
      shift_subtree(left, -half)
      shift_subtree(right, half)
      // Update contours with shifts applied
      for i = 0; i < lr.length(); i = i + 1 {
        lr[i] = lr[i] - half
      }
      for i = 0; i < ll.length(); i = i + 1 {
        ll[i] = ll[i] - half
      }
      for i = 0; i < rl.length(); i = i + 1 {
        rl[i] = rl[i] + half
      }
      for i = 0; i < rr.length(); i = i + 1 {
        rr[i] = rr[i] + half
      }
      node.x = (left.x + right.x) / 2.0

      // Merge contours: left from left subtree, right from right subtree,
      // extending with the other if one is deeper
      let ll_len = ll.length()
      let rl_len = rl.length()
      let max_depth = if ll_len > rl_len { ll_len } else { rl_len }
      let result_left : Array[Double] = [node.x]
      for i = 0; i < max_depth; i = i + 1 {
        result_left.push(if i < ll_len { ll[i] } else { rl[i] })
      }
      let lr_len = lr.length()
      let rr_len = rr.length()
      let max_depth2 = if lr_len > rr_len { lr_len } else { rr_len }
      let result_right : Array[Double] = [node.x]
      for i = 0; i < max_depth2; i = i + 1 {
        result_right.push(if i < rr_len { rr[i] } else { lr[i] })
      }
      (result_left, result_right)
    }
  }
}

///|
/// Shift all x-coordinates in a subtree by dx.
fn shift_subtree(node : BSTNode, dx : Double) -> Unit {
  node.x = node.x + dx
  match node.left {
    Some(left) => shift_subtree(left, dx)
    None => ()
  }
  match node.right {
    Some(right) => shift_subtree(right, dx)
    None => ()
  }
}

///|
/// Collect all nodes from the BST into arrays for output.
fn collect_nodes(
  node : BSTNode,
  config : @types.LayoutConfig,
  min_x : Double,
  nodes : Array[@types.PositionedNode],
  edges : Array[@types.PositionedEdge],
) -> Unit {
  // Convert relative coordinates to pixel coordinates
  let px = config.padding +
    (node.x - min_x) * (node_width + config.node_spacing)
  let py = config.padding + node.y * (node_height + config.level_spacing)
  nodes.push({
    id: "node_\{node.value}",
    x: px,
    y: py,
    width: node_width,
    height: node_height,
    label: node.value.to_string(),
  })
  let parent_cx = px + node_width / 2.0
  let parent_bottom = py + node_height
  match node.left {
    Some(left) => {
      collect_nodes(left, config, min_x, nodes, edges)
      let child_px = config.padding +
        (left.x - min_x) * (node_width + config.node_spacing)
      let child_py = config.padding +
        left.y * (node_height + config.level_spacing)
      let child_cx = child_px + node_width / 2.0
      edges.push({
        from_id: "node_\{node.value}",
        to_id: "node_\{left.value}",
        points: [(parent_cx, parent_bottom), (child_cx, child_py)],
        label: "",
      })
    }
    None => ()
  }
  match node.right {
    Some(right) => {
      collect_nodes(right, config, min_x, nodes, edges)
      let child_px = config.padding +
        (right.x - min_x) * (node_width + config.node_spacing)
      let child_py = config.padding +
        right.y * (node_height + config.level_spacing)
      let child_cx = child_px + node_width / 2.0
      edges.push({
        from_id: "node_\{node.value}",
        to_id: "node_\{right.value}",
        points: [(parent_cx, parent_bottom), (child_cx, child_py)],
        label: "",
      })
    }
    None => ()
  }
}

///|
/// Find the minimum x-coordinate in the tree.
fn find_min_x(node : BSTNode) -> Double {
  let mut min = node.x
  match node.left {
    Some(left) => {
      let lmin = find_min_x(left)
      if lmin < min {
        min = lmin
      }
    }
    None => ()
  }
  match node.right {
    Some(right) => {
      let rmin = find_min_x(right)
      if rmin < min {
        min = rmin
      }
    }
    None => ()
  }
  min
}

///|
/// Layout a tree definition using the Reingold-Tilford algorithm.
pub fn layout(
  def : @types.TreeDef,
  config : @types.LayoutConfig,
) -> @types.PositionedGraph {
  let ops = def.operations
  if ops.length() == 0 {
    return {
      nodes: [],
      edges: [],
      bounds: { x: 0.0, y: 0.0, width: 0.0, height: 0.0 },
    }
  }
  // Build BST
  let mut root : BSTNode? = None
  for i = 0; i < ops.length(); i = i + 1 {
    root = Some(insert(root, ops[i]))
  }
  match root {
    None =>
      {
        nodes: [],
        edges: [],
        bounds: { x: 0.0, y: 0.0, width: 0.0, height: 0.0 },
      }
    Some(r) => {
      // First pass: assign relative coordinates
      let _ = first_pass(r, 0)
      // Find min x for normalization
      let min_x = find_min_x(r)
      // Collect into positioned nodes/edges
      let nodes : Array[@types.PositionedNode] = []
      let edges : Array[@types.PositionedEdge] = []
      collect_nodes(r, config, min_x, nodes, edges)
      let bounds = @types.compute_bounds(nodes, config.padding)
      { nodes, edges, bounds }
    }
  }
}
