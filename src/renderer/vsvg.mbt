///|
/// Virtual SVG Tree — intermediate representation for SVG output.
pub(all) enum SvgNode {
  Svg(width~ : Double, height~ : Double, children~ : Array[SvgNode])
  Rect(
    x~ : Double,
    y~ : Double,
    width~ : Double,
    height~ : Double,
    rx~ : Double,
    fill~ : String,
    stroke~ : String,
    stroke_width~ : Double,
    filter~ : String
  )
  Text(
    x~ : Double,
    y~ : Double,
    content~ : String,
    font_size~ : Double,
    fill~ : String,
    anchor~ : String,
    font_family~ : String
  )
  Defs(children~ : Array[SvgNode])
  Marker(id~ : String, children~ : Array[SvgNode])
  Path(d~ : String, fill~ : String, stroke~ : String)
  Polyline(
    points~ : Array[(Double, Double)],
    stroke~ : String,
    stroke_width~ : Double,
    fill~ : String,
    marker_end~ : String,
    dash_array~ : String
  )
  Polygon(
    points~ : Array[(Double, Double)],
    fill~ : String,
    stroke~ : String,
    stroke_width~ : Double,
    filter~ : String
  )
}
