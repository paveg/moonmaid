///| Node dimensions for tree nodes.
let node_width : Double = 48.0

let node_height : Double = 32.0

///| Internal BST node used during layout computation.
priv struct BSTNode {
  value : Int
  mut left : BSTNode?
  mut right : BSTNode?
  mut x : Double
  mut y : Double
}

///| Create a new BST node.
fn BSTNode::new(value : Int) -> BSTNode {
  { value, left: None, right: None, x: 0.0, y: 0.0 }
}

///| Insert a value into the BST, ignoring duplicates.
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

///| Contour: tracks leftmost/rightmost x at each depth.
priv struct Contour {
  values : Array[Double]
}

fn Contour::new() -> Contour {
  { values: [] }
}

fn Contour::push(self : Contour, v : Double) -> Unit {
  self.values.push(v)
}

fn Contour::length(self : Contour) -> Int {
  self.values.length()
}

fn Contour::get(self : Contour, i : Int) -> Double {
  self.values[i]
}

///| First pass: assign relative x-coordinates bottom-up.
/// Returns the left and right contours of the subtree.
fn first_pass(node : BSTNode, depth : Int) -> (Contour, Contour) {
  node.y = depth.to_double()
  match (node.left, node.right) {
    (None, None) => {
      // Leaf
      node.x = 0.0
      let lc = Contour::new()
      lc.push(0.0)
      let rc = Contour::new()
      rc.push(0.0)
      (lc, rc)
    }
    (Some(left), None) => {
      // Only left child
      let (ll, lr) = first_pass(left, depth + 1)
      node.x = left.x + 1.0

      let lc = Contour::new()
      lc.push(node.x)
      for i = 0; i < ll.length(); i = i + 1 {
        lc.push(ll.get(i))
      }
      let rc = Contour::new()
      rc.push(node.x)
      for i = 0; i < lr.length(); i = i + 1 {
        rc.push(lr.get(i))
      }
      (lc, rc)
    }
    (None, Some(right)) => {
      // Only right child
      let (rl, rr) = first_pass(right, depth + 1)
      node.x = right.x - 1.0

      let lc = Contour::new()
      lc.push(node.x)
      for i = 0; i < rl.length(); i = i + 1 {
        lc.push(rl.get(i))
      }
      let rc = Contour::new()
      rc.push(node.x)
      for i = 0; i < rr.length(); i = i + 1 {
        rc.push(rr.get(i))
      }
      (lc, rc)
    }
    (Some(left), Some(right)) => {
      // Both children
      let (ll, lr) = first_pass(left, depth + 1)
      let (rl, rr) = first_pass(right, depth + 1)
      // Find minimum separation so no two nodes at the same depth overlap.
      // Compare right contour of left subtree with left contour of right subtree.
      let min_len = if lr.length() < rl.length() {
        lr.length()
      } else {
        rl.length()
      }
      let mut needed_sep = 2.0 // minimum 2 units apart (children 1 unit each side)
      for i = 0; i < min_len; i = i + 1 {
        let gap = lr.get(i) - rl.get(i)
        // Need at least 1 unit between contours at each depth
        let sep = gap + 1.0
        if sep > needed_sep {
          needed_sep = sep
        }
      }
      // Also ensure left subtree's rightmost nodes don't reach the root position
      // and right subtree's leftmost nodes don't reach root position.
      // After shifting by half each way, root = 0. So we need all lr < 0 and all rl > 0.
      // lr[i] - half < 0 → half > lr[i] for all i
      // rl[i] + half > 0 → half > -rl[i] for all i
      for i = 0; i < lr.length(); i = i + 1 {
        let req = lr.get(i) + 0.5 // need lr - half < -0.5 → half > lr + 0.5
        if req > needed_sep / 2.0 {
          needed_sep = req * 2.0
        }
      }
      for i = 0; i < rl.length(); i = i + 1 {
        let req = -rl.get(i) + 0.5 // need rl + half > 0.5 → half > -rl + 0.5
        if req > needed_sep / 2.0 {
          needed_sep = req * 2.0
        }
      }
      // Total separation: left subtree shifts left, right shifts right
      let half = needed_sep / 2.0
      shift_subtree(left, -half)
      shift_subtree(right, half)
      // Update contours with shifts applied
      for i = 0; i < lr.length(); i = i + 1 {
        lr.values[i] = lr.get(i) - half
      }
      for i = 0; i < ll.length(); i = i + 1 {
        ll.values[i] = ll.get(i) - half
      }
      for i = 0; i < rl.length(); i = i + 1 {
        rl.values[i] = rl.get(i) + half
      }
      for i = 0; i < rr.length(); i = i + 1 {
        rr.values[i] = rr.get(i) + half
      }
      node.x = (left.x + right.x) / 2.0

      // Merge contours
      let result_left = Contour::new()
      result_left.push(node.x)
      let result_right = Contour::new()
      result_right.push(node.x)
      // Left contour: take left of left subtree, extended by left of right if deeper
      let ll_len = ll.length()
      let rl_len = rl.length()
      let max_depth = if ll_len > rl_len { ll_len } else { rl_len }
      for i = 0; i < max_depth; i = i + 1 {
        if i < ll_len {
          result_left.push(ll.get(i))
        } else {
          result_left.push(rl.get(i))
        }
      }
      // Right contour: take right of right subtree, extended by right of left if deeper
      let lr_len = lr.length()
      let rr_len = rr.length()
      let max_depth2 = if lr_len > rr_len { lr_len } else { rr_len }
      for i = 0; i < max_depth2; i = i + 1 {
        if i < rr_len {
          result_right.push(rr.get(i))
        } else {
          result_right.push(lr.get(i))
        }
      }
      (result_left, result_right)
    }
  }
}

///| Shift all x-coordinates in a subtree by dx.
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

///| Collect all nodes from the BST into arrays for output.
fn collect_nodes(
  node : BSTNode,
  config : @types.LayoutConfig,
  min_x : Double,
  nodes : Array[@types.PositionedNode],
  edges : Array[@types.PositionedEdge]
) -> Unit {
  // Convert relative coordinates to pixel coordinates
  let px = config.padding + (node.x - min_x) * (node_width + config.node_spacing)
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
      let child_px = config.padding + (left.x - min_x) * (node_width + config.node_spacing)
      let child_py = config.padding + left.y * (node_height + config.level_spacing)
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
      let child_px = config.padding + (right.x - min_x) * (node_width + config.node_spacing)
      let child_py = config.padding + right.y * (node_height + config.level_spacing)
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

///| Find the minimum x-coordinate in the tree.
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

///| Compute bounding box for positioned nodes.
fn compute_bounds(
  nodes : Array[@types.PositionedNode],
  padding : Double
) -> @types.BoundingBox {
  if nodes.length() == 0 {
    return { x: 0.0, y: 0.0, width: 0.0, height: 0.0 }
  }
  let mut min_x = nodes[0].x
  let mut min_y = nodes[0].y
  let mut max_x = nodes[0].x + nodes[0].width
  let mut max_y = nodes[0].y + nodes[0].height
  for i = 1; i < nodes.length(); i = i + 1 {
    let node = nodes[i]
    if node.x < min_x {
      min_x = node.x
    }
    if node.y < min_y {
      min_y = node.y
    }
    let right = node.x + node.width
    if right > max_x {
      max_x = right
    }
    let bottom = node.y + node.height
    if bottom > max_y {
      max_y = bottom
    }
  }
  {
    x: min_x - padding,
    y: min_y - padding,
    width: max_x - min_x + padding * 2.0,
    height: max_y - min_y + padding * 2.0,
  }
}

///| Layout a tree definition using the Reingold-Tilford algorithm.
pub fn layout(
  def : @types.TreeDef,
  config : @types.LayoutConfig
) -> @types.PositionedGraph {
  let ops = def.operations
  if ops.length() == 0 {
    return { nodes: [], edges: [], bounds: { x: 0.0, y: 0.0, width: 0.0, height: 0.0 } }
  }
  // Build BST
  let mut root : BSTNode? = None
  for i = 0; i < ops.length(); i = i + 1 {
    root = Some(insert(root, ops[i]))
  }
  match root {
    None =>
      { nodes: [], edges: [], bounds: { x: 0.0, y: 0.0, width: 0.0, height: 0.0 } }
    Some(r) => {
      // First pass: assign relative coordinates
      let _ = first_pass(r, 0)
      // Find min x for normalization
      let min_x = find_min_x(r)
      // Collect into positioned nodes/edges
      let nodes : Array[@types.PositionedNode] = []
      let edges : Array[@types.PositionedEdge] = []
      collect_nodes(r, config, min_x, nodes, edges)
      let bounds = compute_bounds(nodes, config.padding)
      { nodes, edges, bounds }
    }
  }
}
