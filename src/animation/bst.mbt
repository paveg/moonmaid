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
/// Create a traversal step: edge animation, annotation, and unhighlight.
fn traverse_step(
  value : Int,
  current_value : Int,
  current_id : String,
  target_id : String,
  direction : String,
) -> @types.AnimationStep {
  let cmp = if direction == "left" { "<" } else { ">" }
  {
    actions: [
      TraverseEdge(from=current_id, to=target_id, color="#2196f3"),
      Annotate(
        text="\{value} \{cmp} \{current_value}, go \{direction}",
        x=0.0,
        y=0.0,
      ),
      Unhighlight(node_id=current_id),
    ],
    description: "\{value} \{cmp} \{current_value}, traverse \{direction}",
    duration_ms: 400,
  }
}

///|
/// Create an AddNode step at a precomputed position.
fn add_node_step(
  node_id : String,
  pos : Map[String, (Double, Double)],
  value : Int,
  node_width : Double,
  node_height : Double,
  description : String,
) -> @types.AnimationStep {
  let (x, y) = match pos.get(node_id) {
    Some(p) => p
    None => (0.0, 0.0)
  }
  {
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
    description,
    duration_ms: 500,
  }
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
        steps.push(
          add_node_step(
            node_id,
            pos,
            value,
            node_width,
            node_height,
            "Insert \{value} as root",
          ),
        )
        root = Some(AnimBSTNode::new(value))
      }
      Some(r) => {
        if contains(r, value) {
          continue i + 1
        }
        let mut current = r
        let mut done = false
        while not(done) {
          let current_id = "node_\{current.value}"
          steps.push({
            actions: [
              Highlight(node_id=current_id, color="#ff9800"),
              CompareNodes(a=value.to_string(), b=current_id),
            ],
            description: "Compare \{value} with \{current.value}",
            duration_ms: 400,
          })
          let go_left = value < current.value
          let direction = if go_left { "left" } else { "right" }
          let child = if go_left { current.left } else { current.right }
          match child {
            Some(next) => {
              let next_id = "node_\{next.value}"
              steps.push(
                traverse_step(
                  value,
                  current.value,
                  current_id,
                  next_id,
                  direction,
                ),
              )
              current = next
            }
            None => {
              steps.push(
                traverse_step(
                  value,
                  current.value,
                  current_id,
                  node_id,
                  direction,
                ),
              )
              steps.push(
                add_node_step(
                  node_id,
                  pos,
                  value,
                  node_width,
                  node_height,
                  "Insert \{value}",
                ),
              )
              done = true
            }
          }
        }
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
