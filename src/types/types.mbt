///|
/// AST node types produced by the parser.
pub(all) enum Diagram {
  ArrayDiagram(ArrayDef)
  TreeDiagram(TreeDef)
  AnimatedTreeDiagram(TreeDef)
  AnimatedArrayDiagram(ArrayAnimDef)
  GraphDiagram(GraphDef)
} derive(Show, Eq)

///|
/// Array diagram definition.
pub(all) struct ArrayDef {
  elements : Array[Int]
  highlights : Array[Highlight]
} derive(Show, Eq)

///|
/// Highlight range on an array.
pub(all) struct Highlight {
  start : Int
  end : Int
  color : String
  label : String
} derive(Show, Eq)

///|
/// Tree diagram definition.
pub(all) struct TreeDef {
  kind : TreeKind
  operations : Array[Int]
} derive(Show, Eq)

///|
/// Tree variant.
pub(all) enum TreeKind {
  BST
} derive(Show, Eq)

///|
/// Layout output: a node with computed position.
pub(all) struct PositionedNode {
  id : String
  x : Double
  y : Double
  width : Double
  height : Double
  label : String
} derive(Show, Eq)

///|
/// Layout output: an edge with routing points.
pub(all) struct PositionedEdge {
  from_id : String
  to_id : String
  points : Array[(Double, Double)]
  label : String
} derive(Show, Eq)

///|
/// Bounding box for the entire diagram.
pub(all) struct BoundingBox {
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Show, Eq)

///|
/// Complete layout result.
pub(all) struct PositionedGraph {
  nodes : Array[PositionedNode]
  edges : Array[PositionedEdge]
  bounds : BoundingBox
} derive(Show, Eq)

///|
/// Layout configuration.
pub(all) struct LayoutConfig {
  node_spacing : Double
  level_spacing : Double
  padding : Double
} derive(Show, Eq)

///|
/// Default layout configuration.
pub fn LayoutConfig::default() -> LayoutConfig {
  { node_spacing: 20.0, level_spacing: 60.0, padding: 20.0 }
}

///|
/// Resource limits for security.
pub struct Limits {
  max_nodes : Int
  max_array_size : Int
  max_edges : Int
} derive(Show, Eq)

///|
/// Default limits.
pub fn Limits::default() -> Limits {
  { max_nodes: 1024, max_array_size: 256, max_edges: 4096 }
}

///|
pub let default_node_width : Double = 56.0

///|
pub let default_node_height : Double = 40.0

///|
/// Parse/render error.
pub suberror MoonmaidError {
  MoonmaidError(String)
}

///|
/// Construct a MoonmaidError with the given message.
pub fn MoonmaidError::of(msg : String) -> MoonmaidError {
  MoonmaidError(msg)
}

///|
/// Compute a bounding box that encloses all positioned nodes, padded on all sides.
pub fn compute_bounds(
  nodes : Array[PositionedNode],
  padding : Double,
) -> BoundingBox {
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

///|
/// An atomic action applied during one animation step.
pub(all) enum AnimationAction {
  Highlight(node_id~ : String, color~ : String)
  Unhighlight(node_id~ : String)
  TraverseEdge(from~ : String, to~ : String, color~ : String)
  AddNode(
    node_id~ : String,
    x~ : Double,
    y~ : Double,
    width~ : Double,
    height~ : Double,
    label~ : String
  )
  RemoveNode(node_id~ : String)
  SwapNodes(a~ : String, b~ : String)
  UpdateLabel(node_id~ : String, text~ : String)
  CompareNodes(a~ : String, b~ : String)
  Annotate(text~ : String, x~ : Double, y~ : Double)
} derive(Show, Eq)

///|
/// A single step in an animation: one or more actions with metadata.
pub(all) struct AnimationStep {
  actions : Array[AnimationAction]
  description : String
  duration_ms : Int
} derive(Show, Eq)

///|
/// An ordered sequence of animation steps.
pub(all) struct AnimationTimeline {
  steps : Array[AnimationStep]
} derive(Show, Eq)

///|
/// Sort algorithm variant for animated array diagrams.
pub(all) enum SortAlgorithm {
  Bubble
  Insertion
  Selection
  Quick
} derive(Show, Eq)

///|
/// Animated array diagram definition.
pub(all) struct ArrayAnimDef {
  elements : Array[Int]
  algorithm : SortAlgorithm
} derive(Show, Eq)

///|
/// Direction of a graph or flowchart.
pub(all) enum GraphDirection {
  Directed
  Undirected
  FlowTD
  FlowLR
} derive(Show, Eq)

///|
/// Shape of a node in a flowchart.
pub(all) enum NodeShape {
  Rect
  Diamond
  Rounded
} derive(Show, Eq)

///|
/// A node in a graph or flowchart.
pub(all) struct GraphNodeDef {
  id : String
  label : String
  shape : NodeShape
} derive(Show, Eq)

///|
/// An edge in a graph or flowchart.
pub(all) struct GraphEdgeDef {
  from : String
  to : String
  weight : Int?
  style : String
  label : String
} derive(Show, Eq)

///|
/// A graph or flowchart definition.
pub(all) struct GraphDef {
  direction : GraphDirection
  nodes : Array[GraphNodeDef]
  edges : Array[GraphEdgeDef]
} derive(Show, Eq)
