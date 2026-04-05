///|
/// AST node types produced by the parser.
pub(all) enum Diagram {
  ArrayDiagram(ArrayDef)
  TreeDiagram(TreeDef)
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
} derive(Show, Eq)

///|
/// Default limits.
pub fn Limits::default() -> Limits {
  { max_nodes: 1024, max_array_size: 256 }
}

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
