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
/// Parse tree body: bst { insert(int, ...) }
fn Parser::parse_tree_body(
  self : Parser,
  limits : @types.Limits,
) -> @types.TreeDef raise @types.MoonmaidError {
  let kind = match self.advance() {
    TkBST => @types.TreeKind::BST
    tok =>
      raise @types.MoonmaidError::of("expected tree kind (bst), got \{tok}")
  }
  self.expect(LBrace)
  self.expect(TkInsert)
  self.expect(LParen)
  let operations = self.parse_int_list(RParen)
  self.expect(RParen)
  if operations.length() > limits.max_nodes {
    raise @types.MoonmaidError::of(
      "node count \{operations.length()} exceeds limit \{limits.max_nodes}",
    )
  }
  self.expect(RBrace)
  { kind, operations }
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
    TkArray => {
      let def = parser.parse_array_body(limits)
      @types.Diagram::ArrayDiagram(def)
    }
    TkTree => {
      let def = parser.parse_tree_body(limits)
      @types.Diagram::TreeDiagram(def)
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
/// Parse a diagram string using default resource limits.
pub fn parse(input : String) -> @types.Diagram raise @types.MoonmaidError {
  parse_with_limits(input, @types.Limits::default())
}
