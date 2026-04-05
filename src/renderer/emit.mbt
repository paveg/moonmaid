///|
/// Format a Double for SVG attribute values.
/// Trims unnecessary trailing zeros for cleaner output.
fn fmt_double(v : Double) -> String {
  // Convert to string; use integer form when fractional part is zero
  let rounded = v.to_int()
  if rounded.to_double() == v {
    rounded.to_string()
  } else {
    v.to_string()
  }
}

///|
/// Convert a points array to SVG points attribute string.
fn fmt_points(points : Array[(Double, Double)]) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < points.length(); i = i + 1 {
    if i > 0 {
      buf.write_char(' ')
    }
    let (x, y) = points[i]
    buf.write_string(fmt_double(x))
    buf.write_char(',')
    buf.write_string(fmt_double(y))
  }
  buf.to_string()
}

///|
/// Emit children into buffer.
fn emit_children(buf : StringBuilder, children : Array[SvgNode]) -> Unit {
  for i = 0; i < children.length(); i = i + 1 {
    buf.write_string(emit(children[i]))
  }
}

///|
/// Recursively convert SvgNode tree to SVG string.
/// All text content and attribute values go through escape_xml.
pub fn emit(node : SvgNode) -> String {
  let buf = StringBuilder::new()
  match node {
    Svg(width~, height~, children~) => {
      buf.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"")
      buf.write_string(fmt_double(width))
      buf.write_string("\" height=\"")
      buf.write_string(fmt_double(height))
      buf.write_string("\" viewBox=\"0 0 ")
      buf.write_string(fmt_double(width))
      buf.write_char(' ')
      buf.write_string(fmt_double(height))
      buf.write_string("\"><defs>")
      buf.write_string(shadow_filter_def)
      buf.write_string("</defs>")
      emit_children(buf, children)
      buf.write_string("</svg>")
    }
    Rect(x~, y~, width~, height~, rx~, fill~, stroke~, stroke_width~, filter~) => {
      buf.write_string("<rect x=\"")
      buf.write_string(fmt_double(x))
      buf.write_string("\" y=\"")
      buf.write_string(fmt_double(y))
      buf.write_string("\" width=\"")
      buf.write_string(fmt_double(width))
      buf.write_string("\" height=\"")
      buf.write_string(fmt_double(height))
      buf.write_string("\" rx=\"")
      buf.write_string(fmt_double(rx))
      buf.write_string("\" fill=\"")
      buf.write_string(escape_xml(fill))
      buf.write_string("\" stroke=\"")
      buf.write_string(escape_xml(stroke))
      buf.write_string("\" stroke-width=\"")
      buf.write_string(fmt_double(stroke_width))
      buf.write_string("\"")
      if filter.length() > 0 {
        buf.write_string(" filter=\"url(#")
        buf.write_string(escape_xml(filter))
        buf.write_string(")\"")
      }
      buf.write_string("/>")
    }
    Text(x~, y~, content~, font_size~, fill~, anchor~, font_family~) => {
      buf.write_string("<text x=\"")
      buf.write_string(fmt_double(x))
      buf.write_string("\" y=\"")
      buf.write_string(fmt_double(y))
      buf.write_string("\" font-size=\"")
      buf.write_string(fmt_double(font_size))
      buf.write_string("\" fill=\"")
      buf.write_string(escape_xml(fill))
      buf.write_string("\" text-anchor=\"")
      buf.write_string(escape_xml(anchor))
      buf.write_string("\" dominant-baseline=\"middle\" font-family=\"")
      buf.write_string(escape_xml(font_family))
      buf.write_string("\">")
      buf.write_string(escape_xml(content))
      buf.write_string("</text>")
    }
    Defs(children~) => {
      buf.write_string("<defs>")
      emit_children(buf, children)
      buf.write_string("</defs>")
    }
    Marker(id~, children~) => {
      buf.write_string("<marker id=\"")
      buf.write_string(escape_xml(id))
      buf.write_string(
        "\" viewBox=\"0 0 8 8\" markerWidth=\"6\" markerHeight=\"6\" refX=\"8\" refY=\"4\" orient=\"auto\">",
      )
      emit_children(buf, children)
      buf.write_string("</marker>")
    }
    Path(d~, fill~, stroke~, stroke_width~, marker_end~, dash_array~) => {
      buf.write_string("<path d=\"")
      buf.write_string(escape_xml(d))
      buf.write_string("\" fill=\"")
      buf.write_string(escape_xml(fill))
      buf.write_string("\" stroke=\"")
      buf.write_string(escape_xml(stroke))
      buf.write_string("\"")
      if stroke_width > 0.0 {
        buf.write_string(" stroke-width=\"")
        buf.write_string(fmt_double(stroke_width))
        buf.write_string("\"")
      }
      if marker_end.length() > 0 {
        buf.write_string(" marker-end=\"url(#")
        buf.write_string(escape_xml(marker_end))
        buf.write_string(")\"")
      }
      if dash_array.length() > 0 {
        buf.write_string(" stroke-dasharray=\"")
        buf.write_string(escape_xml(dash_array))
        buf.write_string("\"")
      }
      buf.write_string("/>")
    }
    Polyline(points~, stroke~, stroke_width~, fill~, marker_end~, dash_array~) => {
      buf.write_string("<polyline points=\"")
      buf.write_string(fmt_points(points))
      buf.write_string("\" stroke=\"")
      buf.write_string(escape_xml(stroke))
      buf.write_string("\" stroke-width=\"")
      buf.write_string(fmt_double(stroke_width))
      buf.write_string("\" fill=\"")
      buf.write_string(escape_xml(fill))
      buf.write_string("\"")
      if marker_end.length() > 0 {
        buf.write_string(" marker-end=\"url(#")
        buf.write_string(escape_xml(marker_end))
        buf.write_string(")\"")
      }
      if dash_array.length() > 0 {
        buf.write_string(" stroke-dasharray=\"")
        buf.write_string(escape_xml(dash_array))
        buf.write_string("\"")
      }
      buf.write_string("/>")
    }
    Polygon(points~, fill~, stroke~, stroke_width~, filter~) => {
      buf.write_string("<polygon points=\"")
      buf.write_string(fmt_points(points))
      buf.write_string("\" fill=\"")
      buf.write_string(escape_xml(fill))
      buf.write_string("\" stroke=\"")
      buf.write_string(escape_xml(stroke))
      buf.write_string("\" stroke-width=\"")
      buf.write_string(fmt_double(stroke_width))
      buf.write_string("\"")
      if filter.length() > 0 {
        buf.write_string(" filter=\"url(#")
        buf.write_string(escape_xml(filter))
        buf.write_string(")\"")
      }
      buf.write_string("/>")
    }
  }
  buf.to_string()
}
