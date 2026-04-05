///|
/// Public render entry point exported to WASM.
/// Returns an SVG string, or an error SVG if parsing or rendering fails.
pub fn render(input : String) -> String {
  let result : Result[String, Unit] = Ok(render_result(input)) catch {
    _ => Err(())
  }
  match result {
    Ok(svg) => svg
    Err(_) => {
      let msg = "Parse or render error"
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"400\" height=\"40\"><text x=\"10\" y=\"25\" fill=\"#cf222e\" font-size=\"14\">" +
      @renderer.escape_xml(msg) +
      "</text></svg>"
    }
  }
}

///|
fn render_result(input : String) -> String raise @types.MoonmaidError {
  let diagram = @parser.parse(input)
  let config = @types.LayoutConfig::default()
  let svg_tree = match diagram {
    ArrayDiagram(def) => {
      let graph = @grid.layout(def, config)
      @renderer.render_array(graph, def)
    }
    TreeDiagram(def) => {
      let graph = @tree.layout(def, config)
      @renderer.render_tree(graph)
    }
  }
  @renderer.emit(svg_tree)
}
