///|
/// Internal BST node used during animation generation.
priv struct AnimBSTNode {
  value : Int
  mut left : AnimBSTNode?
  mut right : AnimBSTNode?
}

///|
/// Create a new internal BST node.
fn AnimBSTNode::new(value : Int) -> AnimBSTNode {
  { value, left: None, right: None }
}

///|
/// Generate a step-by-step BST insertion animation timeline.
///
/// Uses precomputed layout positions so each AddNode action places
/// the node at its final coordinate.
pub fn generate_bst_animation(
  def : @types.TreeDef,
  config : @types.LayoutConfig,
) -> @types.AnimationTimeline {
  let ops = def.operations
  if ops.length() == 0 {
    return { steps: [] }
  }
  // Precompute all final positions via the layout engine.
  let graph = @tree.layout(def, config)
  let pos : Map[String, (Double, Double)] = Map::new()
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    pos[node.id] = (node.x, node.y)
  }
  let node_width = 48.0
  let node_height = 32.0
  let steps : Array[@types.AnimationStep] = []
  let mut root : AnimBSTNode? = None
  for i = 0; i < ops.length(); i = i + 1 {
    let value = ops[i]
    let node_id = "node_\{value}"
    match root {
      None => {
        // Root insert: single AddNode step
        let (x, y) = pos[node_id]
        steps.push({
          actions: [
            AddNode(
              node_id~,
              x~,
              y~,
              width=node_width,
              height=node_height,
              label=value.to_string(),
            ),
          ],
          description: "Insert \{value} as root",
          duration_ms: 500,
        })
        root = Some(AnimBSTNode::new(value))
      }
      Some(r) => {
        // Check for duplicate before generating steps
        if contains(r, value) {
          continue i + 1
        }
        // Walk the search path, generating steps for each comparison
        let mut current = r
        let mut done = false
        while not(done) {
          let current_id = "node_\{current.value}"
          // Step: Highlight + CompareNodes
          steps.push({
            actions: [
              Highlight(node_id=current_id, color="#ff9800"),
              CompareNodes(a=value.to_string(), b=current_id),
            ],
            description: "Compare \{value} with \{current.value}",
            duration_ms: 400,
          })
          if value < current.value {
            // Go left
            match current.left {
              Some(left) => {
                let left_id = "node_\{left.value}"
                steps.push({
                  actions: [
                    TraverseEdge(from=current_id, to=left_id, color="#2196f3"),
                    Annotate(
                      text="\{value} < \{current.value}, go left",
                      x=0.0,
                      y=0.0,
                    ),
                    Unhighlight(node_id=current_id),
                  ],
                  description: "\{value} < \{current.value}, traverse left",
                  duration_ms: 400,
                })
                current = left
              }
              None => {
                // Insert here
                steps.push({
                  actions: [
                    TraverseEdge(from=current_id, to=node_id, color="#2196f3"),
                    Annotate(
                      text="\{value} < \{current.value}, go left",
                      x=0.0,
                      y=0.0,
                    ),
                    Unhighlight(node_id=current_id),
                  ],
                  description: "\{value} < \{current.value}, traverse left",
                  duration_ms: 400,
                })
                let (x, y) = pos[node_id]
                steps.push({
                  actions: [
                    AddNode(
                      node_id~,
                      x~,
                      y~,
                      width=node_width,
                      height=node_height,
                      label=value.to_string(),
                    ),
                  ],
                  description: "Insert \{value}",
                  duration_ms: 500,
                })
                done = true
              }
            }
          } else {
            // Go right (value > current.value; duplicates already filtered)
            match current.right {
              Some(right) => {
                let right_id = "node_\{right.value}"
                steps.push({
                  actions: [
                    TraverseEdge(from=current_id, to=right_id, color="#2196f3"),
                    Annotate(
                      text="\{value} > \{current.value}, go right",
                      x=0.0,
                      y=0.0,
                    ),
                    Unhighlight(node_id=current_id),
                  ],
                  description: "\{value} > \{current.value}, traverse right",
                  duration_ms: 400,
                })
                current = right
              }
              None => {
                // Insert here
                steps.push({
                  actions: [
                    TraverseEdge(from=current_id, to=node_id, color="#2196f3"),
                    Annotate(
                      text="\{value} > \{current.value}, go right",
                      x=0.0,
                      y=0.0,
                    ),
                    Unhighlight(node_id=current_id),
                  ],
                  description: "\{value} > \{current.value}, traverse right",
                  duration_ms: 400,
                })
                let (x, y) = pos[node_id]
                steps.push({
                  actions: [
                    AddNode(
                      node_id~,
                      x~,
                      y~,
                      width=node_width,
                      height=node_height,
                      label=value.to_string(),
                    ),
                  ],
                  description: "Insert \{value}",
                  duration_ms: 500,
                })
                done = true
              }
            }
          }
        }
        // Actually insert into our internal tree
        insert_node(r, value)
      }
    }
  }
  { steps, }
}

///|
/// Check if a value exists in the BST.
fn contains(node : AnimBSTNode, value : Int) -> Bool {
  if value == node.value {
    true
  } else if value < node.value {
    match node.left {
      Some(left) => contains(left, value)
      None => false
    }
  } else {
    match node.right {
      Some(right) => contains(right, value)
      None => false
    }
  }
}

///|
/// Insert a value into the internal BST (mutates in place).
fn insert_node(node : AnimBSTNode, value : Int) -> Unit {
  if value < node.value {
    match node.left {
      Some(left) => insert_node(left, value)
      None => node.left = Some(AnimBSTNode::new(value))
    }
  } else if value > node.value {
    match node.right {
      Some(right) => insert_node(right, value)
      None => node.right = Some(AnimBSTNode::new(value))
    }
  }
  // Duplicate: do nothing
}
