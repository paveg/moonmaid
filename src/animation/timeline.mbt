///|
/// Escape special characters for JSON string values.
/// Escapes: " \ \n \r \t
fn json_escape(input : String) -> String {
  let buf = StringBuilder::new()
  let len = input.length()
  for i = 0; i < len; i = i + 1 {
    let c = Int::unsafe_to_char(input[i].to_int())
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Serialize an AnimationAction to JSON object string.
fn action_to_json(action : @types.AnimationAction) -> String {
  let buf = StringBuilder::new()
  match action {
    Highlight(node_id~, color~) => {
      buf.write_string("{\"type\":\"Highlight\",\"node_id\":\"")
      buf.write_string(json_escape(node_id))
      buf.write_string("\",\"color\":\"")
      buf.write_string(json_escape(color))
      buf.write_string("\"}")
    }
    Unhighlight(node_id~) => {
      buf.write_string("{\"type\":\"Unhighlight\",\"node_id\":\"")
      buf.write_string(json_escape(node_id))
      buf.write_string("\"}")
    }
    TraverseEdge(from~, to~, color~) => {
      buf.write_string("{\"type\":\"TraverseEdge\",\"from\":\"")
      buf.write_string(json_escape(from))
      buf.write_string("\",\"to\":\"")
      buf.write_string(json_escape(to))
      buf.write_string("\",\"color\":\"")
      buf.write_string(json_escape(color))
      buf.write_string("\"}")
    }
    AddNode(node_id~, x~, y~, width~, height~, label~) => {
      buf.write_string("{\"type\":\"AddNode\",\"node_id\":\"")
      buf.write_string(json_escape(node_id))
      buf.write_string("\",\"x\":")
      buf.write_string(x.to_string())
      buf.write_string(",\"y\":")
      buf.write_string(y.to_string())
      buf.write_string(",\"width\":")
      buf.write_string(width.to_string())
      buf.write_string(",\"height\":")
      buf.write_string(height.to_string())
      buf.write_string(",\"label\":\"")
      buf.write_string(json_escape(label))
      buf.write_string("\"}")
    }
    RemoveNode(node_id~) => {
      buf.write_string("{\"type\":\"RemoveNode\",\"node_id\":\"")
      buf.write_string(json_escape(node_id))
      buf.write_string("\"}")
    }
    SwapNodes(a~, b~) => {
      buf.write_string("{\"type\":\"SwapNodes\",\"a\":\"")
      buf.write_string(json_escape(a))
      buf.write_string("\",\"b\":\"")
      buf.write_string(json_escape(b))
      buf.write_string("\"}")
    }
    UpdateLabel(node_id~, text~) => {
      buf.write_string("{\"type\":\"UpdateLabel\",\"node_id\":\"")
      buf.write_string(json_escape(node_id))
      buf.write_string("\",\"text\":\"")
      buf.write_string(json_escape(text))
      buf.write_string("\"}")
    }
    CompareNodes(a~, b~) => {
      buf.write_string("{\"type\":\"CompareNodes\",\"a\":\"")
      buf.write_string(json_escape(a))
      buf.write_string("\",\"b\":\"")
      buf.write_string(json_escape(b))
      buf.write_string("\"}")
    }
    Annotate(text~, x~, y~) => {
      buf.write_string("{\"type\":\"Annotate\",\"text\":\"")
      buf.write_string(json_escape(text))
      buf.write_string("\",\"x\":")
      buf.write_string(x.to_string())
      buf.write_string(",\"y\":")
      buf.write_string(y.to_string())
      buf.write_string("}")
    }
  }
  buf.to_string()
}

///|
/// Serialize an AnimationTimeline to a JSON string.
pub fn timeline_to_json(timeline : @types.AnimationTimeline) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\"steps\":[")
  for i = 0; i < timeline.steps.length(); i = i + 1 {
    if i > 0 {
      buf.write_char(',')
    }
    let step = timeline.steps[i]
    buf.write_string("{\"actions\":[")
    for j = 0; j < step.actions.length(); j = j + 1 {
      if j > 0 {
        buf.write_char(',')
      }
      buf.write_string(action_to_json(step.actions[j]))
    }
    buf.write_string("],\"description\":\"")
    buf.write_string(json_escape(step.description))
    buf.write_string("\",\"duration_ms\":")
    buf.write_string(step.duration_ms.to_string())
    buf.write_char('}')
  }
  buf.write_string("]}")
  buf.to_string()
}
