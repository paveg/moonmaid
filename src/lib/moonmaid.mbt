///|
/// Public render entry point exported to WASM.
/// Returns an SVG string, or an error SVG if parsing or rendering fails.
pub fn render(input : String) -> String {
  let result : Result[String, String] = Ok(render_result(input)) catch {
    @types.MoonmaidError(msg) => Err(msg)
  }
  match result {
    Ok(svg) => svg
    Err(msg) =>
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"400\" height=\"40\"><text x=\"10\" y=\"25\" fill=\"#991b1b\" font-size=\"14\">" +
      @renderer.escape_xml(msg) +
      "</text></svg>"
  }
}

///|
fn render_result(input : String) -> String raise @types.MoonmaidError {
  let max_input_size = 65536 // 64 KiB
  if input.length() > max_input_size {
    raise @types.MoonmaidError::of("Input too large (max: 65536 characters)")
  }
  let diagram = @parser.parse(input)
  let config = @types.LayoutConfig::default()
  match diagram {
    ArrayDiagram(def) => {
      let graph = @grid.layout(def, config)
      @renderer.emit(@renderer.render_array(graph, def))
    }
    TreeDiagram(def) => {
      let graph = @tree.layout(def, config)
      @renderer.emit(@renderer.render_tree(graph))
    }
    AnimatedTreeDiagram(def) => {
      let graph = @tree.layout(def, config)
      let timeline = @animation.generate_bst_animation(def, config)
      @renderer.render_animated(graph, timeline)
    }
    AnimatedArrayDiagram(def) => {
      let array_def : @types.ArrayDef = {
        elements: def.elements,
        highlights: [],
      }
      let graph = @grid.layout(array_def, config)
      let timeline = @animation.generate_sort_animation(def, config)
      @renderer.render_animated(graph, timeline)
    }
    GraphDiagram(def) => {
      let graph = @dagre.layout_with_dagre(def, config)
      @renderer.emit(@renderer.render_graph(graph, def))
    }
  }
}
