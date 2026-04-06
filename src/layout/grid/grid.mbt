///|
/// Cell dimensions for array elements.
let cell_width : Double = 52.0

///|
let cell_height : Double = 52.0

///|
/// Gap between element cell bottom and index label top.
let idx_gap : Double = 4.0

///|
/// Height of the index label node.
let idx_height : Double = 20.0

///|
/// Layout an array definition as a horizontal grid.
///
/// Each element becomes a square cell of 40x40, positioned left-to-right
/// with `node_spacing` gaps. Below each cell is an index label node.
/// No edges are generated for arrays.
pub fn layout(
  def : @types.ArrayDef,
  config : @types.LayoutConfig,
) -> @types.PositionedGraph {
  let n = def.elements.length()
  let nodes : Array[@types.PositionedNode] = Array::make(n * 2, {
    id: "",
    x: 0.0,
    y: 0.0,
    width: 0.0,
    height: 0.0,
    label: "",
  })
  let elem_y = config.padding
  let idx_y = config.padding + cell_height + idx_gap
  for i = 0; i < n; i = i + 1 {
    let x = config.padding + i.to_double() * (cell_width + config.node_spacing)
    nodes[i] = {
      id: "elem_\{i}",
      x,
      y: elem_y,
      width: cell_width,
      height: cell_height,
      label: def.elements[i].to_string(),
    }
    nodes[n + i] = {
      id: "idx_\{i}",
      x,
      y: idx_y,
      width: cell_width,
      height: idx_height,
      label: i.to_string(),
    }
  }
  // Extra horizontal margin to prevent highlight labels from extending beyond SVG bounds.
  // Extra vertical margin for highlight label text rendered below the index row.
  let label_margin = 40.0
  let label_row_height = 30.0
  let raw_bounds = @types.compute_bounds(nodes, config.padding)
  let bounds : @types.BoundingBox = {
    x: raw_bounds.x,
    y: raw_bounds.y,
    width: raw_bounds.width + label_margin * 2.0,
    height: raw_bounds.height + label_row_height,
  }
  { nodes, edges: [], bounds }
}
