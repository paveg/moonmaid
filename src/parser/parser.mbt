///|
/// Recursive descent parser state.
priv struct Parser {
  tokens : Array[Located]
  mut pos : Int
}

///|
fn Parser::new(tokens : Array[Located]) -> Parser {
  { tokens, pos: 0 }
}

///|
fn Parser::peek(self : Parser) -> Token {
  if self.pos < self.tokens.length() {
    self.tokens[self.pos].token
  } else {
    Eof
  }
}

///|
fn Parser::advance(self : Parser) -> Token {
  let tok = self.peek()
  if self.pos < self.tokens.length() {
    self.pos = self.pos + 1
  }
  tok
}

///|
fn Parser::expect(
  self : Parser,
  expected : Token,
) -> Unit raise @types.MoonmaidError {
  let tok = self.advance()
  if tok != expected {
    raise @types.MoonmaidError::of("expected \{expected} but got \{tok}")
  }
}

///|
/// Parse a comma-separated list of integers inside already-consumed delimiters.
/// Stops when it sees `end_tok`.
fn Parser::parse_int_list(
  self : Parser,
  end_tok : Token,
) -> Array[Int] raise @types.MoonmaidError {
  let result : Array[Int] = []
  if self.peek() == end_tok {
    return result
  }
  match self.advance() {
    IntLit(n) => result.push(n)
    tok => raise @types.MoonmaidError::of("expected integer, got \{tok}")
  }
  while self.peek() == Comma {
    let _ = self.advance() // consume comma
    match self.advance() {
      IntLit(n) => result.push(n)
      tok =>
        raise @types.MoonmaidError::of(
          "expected integer after comma, got \{tok}",
        )
    }
  }
  result
}

///|
/// Parse a highlight expression: highlight(range_or_index, color=X, label=Y)
fn Parser::parse_highlight(
  self : Parser,
) -> @types.Highlight raise @types.MoonmaidError {
  self.expect(LParen)
  // Parse index or range: int | int..int
  let start = match self.advance() {
    IntLit(n) => n
    tok =>
      raise @types.MoonmaidError::of(
        "expected integer in highlight, got \{tok}",
      )
  }
  let end_idx = if self.peek() == DotDot {
    let _ = self.advance() // consume ..
    match self.advance() {
      IntLit(n) => n
      tok =>
        raise @types.MoonmaidError::of("expected integer after .., got \{tok}")
    }
  } else {
    start
  }
  self.expect(Comma)
  // Parse color=X
  match self.advance() {
    Ident("color") => ()
    tok =>
      raise @types.MoonmaidError::of("expected 'color' keyword, got \{tok}")
  }
  self.expect(Eq)
  let color = match self.advance() {
    Ident(s) => s
    StringLit(s) => s
    tok => raise @types.MoonmaidError::of("expected color value, got \{tok}")
  }
  self.expect(Comma)
  // Parse label=Y
  match self.advance() {
    Ident("label") => ()
    tok =>
      raise @types.MoonmaidError::of("expected 'label' keyword, got \{tok}")
  }
  self.expect(Eq)
  let label = match self.advance() {
    StringLit(s) => s
    Ident(s) => s
    tok => raise @types.MoonmaidError::of("expected label value, got \{tok}")
  }
  self.expect(RParen)
  { start, end: end_idx, color, label }
}

///|
/// Parse array body: { [int, ...] highlight(...) ... }
fn Parser::parse_array_body(
  self : Parser,
  limits : @types.Limits,
) -> @types.ArrayDef raise @types.MoonmaidError {
  self.expect(LBrace)
  self.expect(LBracket)
  let elements = self.parse_int_list(RBracket)
  self.expect(RBracket)
  if elements.length() > limits.max_array_size {
    raise @types.MoonmaidError::of(
      "array size \{elements.length()} exceeds limit \{limits.max_array_size}",
    )
  }
  let highlights : Array[@types.Highlight] = []
  while self.peek() == TkHighlight {
    let _ = self.advance() // consume 'highlight'
    let h = self.parse_highlight()
    highlights.push(h)
  }
  self.expect(RBrace)
  { elements, highlights }
}

///|
/// Parse animated array body: { [int, ...] sort: <algo> }
fn Parser::parse_array_anim_body(
  self : Parser,
  limits : @types.Limits,
) -> @types.ArrayAnimDef raise @types.MoonmaidError {
  self.expect(LBrace)
  self.expect(LBracket)
  let elements = self.parse_int_list(RBracket)
  self.expect(RBracket)
  if elements.length() > limits.max_array_size {
    raise @types.MoonmaidError::of(
      "array size \{elements.length()} exceeds limit \{limits.max_array_size}",
    )
  }
  // Expect: sort: <algorithm>
  match self.advance() {
    TkSort => ()
    tok =>
      raise @types.MoonmaidError::of(
        "expected 'sort' keyword in animated array, got \{tok}",
      )
  }
  self.expect(Colon)
  let algorithm = match self.advance() {
    TkBubble => @types.SortAlgorithm::Bubble
    TkInsertion => @types.SortAlgorithm::Insertion
    TkSelection => @types.SortAlgorithm::Selection
    TkQuick => @types.SortAlgorithm::Quick
    tok => raise @types.MoonmaidError::of("unknown sort algorithm: \{tok}")
  }
  self.expect(RBrace)
  { elements, algorithm }
}

///|
/// Parse a diagram with explicit resource limits.
pub fn parse_with_limits(
  input : String,
  limits : @types.Limits,
) -> @types.Diagram raise @types.MoonmaidError {
  let tokens = lex(input)
  let parser = Parser::new(tokens)
  let diagram = match parser.advance() {
    TkArray =>
      if parser.peek() == At {
        let _ = parser.advance() // consume @
        match parser.advance() {
          TkAnimate => {
            let def = parser.parse_array_anim_body(limits)
            @types.Diagram::AnimatedArrayDiagram(def)
          }
          tok =>
            raise @types.MoonmaidError::of(
              "array does not support @\{tok} directive",
            )
        }
      } else {
        let def = parser.parse_array_body(limits)
        @types.Diagram::ArrayDiagram(def)
      }
    TkTree => {
      // Consume the tree kind (e.g. bst) before checking for directives
      let kind = match parser.advance() {
        TkBST => @types.TreeKind::BST
        tok =>
          raise @types.MoonmaidError::of("expected tree kind (bst), got \{tok}")
      }
      // Check for optional @animate directive between kind and body
      let animated = if parser.peek() == At {
        let _ = parser.advance() // consume @
        match parser.advance() {
          TkAnimate => true
          tok =>
            raise @types.MoonmaidError::of("unknown directive @\{tok} for tree")
        }
      } else {
        false
      }
      // Parse the body { insert(...) }
      parser.expect(LBrace)
      parser.expect(TkInsert)
      parser.expect(LParen)
      let operations = parser.parse_int_list(RParen)
      parser.expect(RParen)
      if operations.length() > limits.max_nodes {
        raise @types.MoonmaidError::of(
          "node count \{operations.length()} exceeds limit \{limits.max_nodes}",
        )
      }
      parser.expect(RBrace)
      let def : @types.TreeDef = { kind, operations }
      if animated {
        @types.Diagram::AnimatedTreeDiagram(def)
      } else {
        @types.Diagram::TreeDiagram(def)
      }
    }
    TkGraph => {
      let dir = match parser.advance() {
        TkDirected => @types.GraphDirection::Directed
        TkUndirected => @types.GraphDirection::Undirected
        tok =>
          raise @types.MoonmaidError::of(
            "expected 'directed' or 'undirected', got \{tok}",
          )
      }
      if parser.peek() == At {
        let _ = parser.advance()
        let tok = parser.advance()
        raise @types.MoonmaidError::of(
          "graph does not support @\{tok} directive",
        )
      }
      let def = parser.parse_graph_body(dir, limits)
      @types.Diagram::GraphDiagram(def)
    }
    TkFlowchart => {
      let dir = match parser.advance() {
        Ident("TD") => @types.GraphDirection::FlowTD
        Ident("LR") => @types.GraphDirection::FlowLR
        tok =>
          raise @types.MoonmaidError::of(
            "expected 'TD' or 'LR' after flowchart, got \{tok}",
          )
      }
      if parser.peek() == At {
        let _ = parser.advance()
        let tok = parser.advance()
        raise @types.MoonmaidError::of(
          "flowchart does not support @\{tok} directive",
        )
      }
      let def = parser.parse_flowchart_body(dir, limits)
      @types.Diagram::GraphDiagram(def)
    }
    tok => raise @types.MoonmaidError::of("unknown diagram type: \{tok}")
  }
  // Ensure no trailing tokens
  match parser.peek() {
    Eof => ()
    tok =>
      raise @types.MoonmaidError::of("unexpected token after diagram: \{tok}")
  }
  diagram
}

///|
/// Parse a graph node reference: Ident optionally followed by ( StringLit ) for label.
fn Parser::parse_graph_node_ref(
  self : Parser,
) -> (String, String) raise @types.MoonmaidError {
  let id = match self.advance() {
    Ident(name) => name
    tok =>
      raise @types.MoonmaidError::of("expected node identifier, got \{tok}")
  }
  let label = if self.peek() == LParen {
    let _ = self.advance() // consume (
    let s = match self.advance() {
      StringLit(s) => s
      tok =>
        raise @types.MoonmaidError::of(
          "expected string label in (), got \{tok}",
        )
    }
    self.expect(RParen)
    s
  } else {
    id
  }
  (id, label)
}

///|
/// Parse optional edge attributes: [weight=INT, style=IDENT]
fn Parser::parse_edge_attrs(
  self : Parser,
) -> (Int?, String) raise @types.MoonmaidError {
  if self.peek() != LBracket {
    return (None, "solid")
  }
  let _ = self.advance() // consume [
  let mut weight : Int? = None
  let mut style = "solid"
  // Parse comma-separated key=value pairs
  let mut first = true
  while self.peek() != RBracket {
    if not(first) {
      self.expect(Comma)
    }
    first = false
    match self.advance() {
      Ident("weight") => {
        self.expect(Eq)
        match self.advance() {
          IntLit(n) => weight = Some(n)
          tok =>
            raise @types.MoonmaidError::of(
              "expected integer for weight, got \{tok}",
            )
        }
      }
      Ident("style") => {
        self.expect(Eq)
        match self.advance() {
          Ident(s) => style = s
          tok =>
            raise @types.MoonmaidError::of(
              "expected identifier for style, got \{tok}",
            )
        }
      }
      tok =>
        raise @types.MoonmaidError::of(
          "expected 'weight' or 'style' in edge attrs, got \{tok}",
        )
    }
  }
  self.expect(RBracket)
  (weight, style)
}

///|
/// Parse a graph body: { edge_chain ; edge_chain ; ... }
/// Edge chain: node_ref -> node_ref [attrs] -> node_ref [attrs] ...
fn Parser::parse_graph_body(
  self : Parser,
  direction : @types.GraphDirection,
  limits : @types.Limits,
) -> @types.GraphDef raise @types.MoonmaidError {
  self.expect(LBrace)
  let edges : Array[@types.GraphEdgeDef] = []
  let node_map : Map[String, @types.GraphNodeDef] = Map::new()
  // Helper to register a node (labeled version wins)
  fn register_node(
    node_map : Map[String, @types.GraphNodeDef],
    id : String,
    label : String,
  ) -> Unit {
    match node_map.get(id) {
      Some(existing) =>
        // Labeled version wins over id-as-label
        if existing.label == existing.id && label != id {
          node_map[id] = { id, label, shape: @types.NodeShape::Rect }
        }
      None => node_map[id] = { id, label, shape: @types.NodeShape::Rect }
    }
  }
  while self.peek() != RBrace && self.peek() != Eof {
    let (first_id, first_label) = self.parse_graph_node_ref()
    register_node(node_map, first_id, first_label)
    let mut prev_id = first_id
    while self.peek() == Arrow {
      let _ = self.advance() // consume ->
      let (next_id, next_label) = self.parse_graph_node_ref()
      register_node(node_map, next_id, next_label)
      let (weight, style) = self.parse_edge_attrs()
      edges.push({ from: prev_id, to: next_id, weight, style, label: "" })
      if edges.length() > limits.max_edges {
        raise @types.MoonmaidError::of(
          "edge count \{edges.length()} exceeds limit \{limits.max_edges}",
        )
      }
      prev_id = next_id
    }
  }
  self.expect(RBrace)
  let nodes : Array[@types.GraphNodeDef] = []
  node_map.each(fn(_k, v) { nodes.push(v) })
  { direction, nodes, edges }
}

///|
/// Parse a flowchart node reference with shape detection:
/// A["label"] -> Rect, A{"label"} -> Diamond, A("label") -> Rounded, A -> Rect with id as label
fn Parser::parse_flowchart_node_ref(
  self : Parser,
) -> (String, String, @types.NodeShape) raise @types.MoonmaidError {
  let id = match self.advance() {
    Ident(name) => name
    tok =>
      raise @types.MoonmaidError::of("expected node identifier, got \{tok}")
  }
  match self.peek() {
    LBracket => {
      let _ = self.advance()
      let label = match self.advance() {
        StringLit(s) => s
        tok =>
          raise @types.MoonmaidError::of(
            "expected string label in [], got \{tok}",
          )
      }
      self.expect(RBracket)
      (id, label, @types.NodeShape::Rect)
    }
    LBrace => {
      let _ = self.advance()
      let label = match self.advance() {
        StringLit(s) => s
        tok =>
          raise @types.MoonmaidError::of(
            "expected string label in {}, got \{tok}",
          )
      }
      self.expect(RBrace)
      (id, label, @types.NodeShape::Diamond)
    }
    LParen => {
      let _ = self.advance()
      let label = match self.advance() {
        StringLit(s) => s
        tok =>
          raise @types.MoonmaidError::of(
            "expected string label in (), got \{tok}",
          )
      }
      self.expect(RParen)
      (id, label, @types.NodeShape::Rounded)
    }
    _ => (id, id, @types.NodeShape::Rect)
  }
}

///|
/// Parse a flowchart body: { edge_chain ; edge_chain ; ... }
fn Parser::parse_flowchart_body(
  self : Parser,
  direction : @types.GraphDirection,
  limits : @types.Limits,
) -> @types.GraphDef raise @types.MoonmaidError {
  self.expect(LBrace)
  let edges : Array[@types.GraphEdgeDef] = []
  let node_map : Map[String, @types.GraphNodeDef] = Map::new()
  fn register_fc_node(
    node_map : Map[String, @types.GraphNodeDef],
    id : String,
    label : String,
    shape : @types.NodeShape,
  ) -> Unit {
    match node_map.get(id) {
      Some(existing) =>
        // Labeled version wins over id-as-label
        if existing.label == existing.id && label != id {
          node_map[id] = { id, label, shape }
        }
      None => node_map[id] = { id, label, shape }
    }
  }
  while self.peek() != RBrace && self.peek() != Eof {
    let (first_id, first_label, first_shape) = self.parse_flowchart_node_ref()
    register_fc_node(node_map, first_id, first_label, first_shape)
    let mut prev_id = first_id
    while self.peek() == Arrow {
      let _ = self.advance() // consume ->
      // Check for edge label: ->|label|
      let edge_label = if self.peek() == Pipe {
        let _ = self.advance() // consume |
        let label = match self.advance() {
          Ident(s) => s
          StringLit(s) => s
          tok =>
            raise @types.MoonmaidError::of(
              "expected edge label after |, got \{tok}",
            )
        }
        self.expect(Pipe)
        label
      } else {
        ""
      }
      let (next_id, next_label, next_shape) = self.parse_flowchart_node_ref()
      register_fc_node(node_map, next_id, next_label, next_shape)
      edges.push({
        from: prev_id,
        to: next_id,
        weight: None,
        style: "solid",
        label: edge_label,
      })
      if edges.length() > limits.max_edges {
        raise @types.MoonmaidError::of(
          "edge count \{edges.length()} exceeds limit \{limits.max_edges}",
        )
      }
      prev_id = next_id
    }
  }
  self.expect(RBrace)
  let nodes : Array[@types.GraphNodeDef] = []
  node_map.each(fn(_k, v) { nodes.push(v) })
  { direction, nodes, edges }
}

///|
/// Parse a diagram string using default resource limits.
pub fn parse(input : String) -> @types.Diagram raise @types.MoonmaidError {
  parse_with_limits(input, @types.Limits::default())
}
