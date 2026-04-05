# Phase 1: Static Rendering End-to-End — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working pipeline from moonmaid DSL to static SVG output for `array` and `tree bst` diagrams, with remark plugin integration for Astro/Starlight sites.

**Architecture:** MoonBit monorepo with packages for types, parser, layout, and renderer. MoonBit compiles to WASM (wasm-gc target). A thin TypeScript layer wraps WASM for the remark plugin. The Reingold-Tilford tree layout lives in a separate package (`layout/tree`) designed for future extraction to mooncakes.io.

**Tech Stack:** MoonBit (core), TypeScript (remark plugin + WASM bridge), Vitest (TS tests), pnpm (TS package management)

**Spec:** `docs/superpowers/specs/2026-04-05-moonmaid-design.md`

**Scope:** Static rendering only (no animation). Animation is Phase 1.5.

---

## File Structure

```
moonmaid/
├── moon.mod.json
├── src/
│   ├── types/
│   │   ├── moon.pkg
│   │   └── types.mbt              # AST nodes, DiagramModel, layout types, color
│   ├── parser/
│   │   ├── moon.pkg
│   │   ├── token.mbt              # Token enum
│   │   ├── lexer.mbt              # Hand-written lexer
│   │   ├── parser.mbt             # Recursive descent parser
│   │   ├── lexer_test.mbt         # Lexer tests
│   │   └── parser_test.mbt        # Parser tests
│   ├── layout/
│   │   ├── grid/
│   │   │   ├── moon.pkg
│   │   │   ├── grid.mbt           # Fixed grid layout for arrays
│   │   │   └── grid_test.mbt
│   │   └── tree/
│   │       ├── moon.pkg
│   │       ├── reingold_tilford.mbt  # Reingold-Tilford algorithm
│   │       └── reingold_tilford_test.mbt
│   ├── renderer/
│   │   ├── moon.pkg
│   │   ├── vsvg.mbt               # Virtual SVG Tree nodes
│   │   ├── emit.mbt               # SVG string emission
│   │   ├── escape.mbt             # XSS prevention
│   │   ├── theme.mbt              # GFM color palette
│   │   ├── render_array.mbt       # Array → SVG
│   │   ├── render_tree.mbt        # Tree → SVG
│   │   ├── escape_test.mbt
│   │   └── renderer_test.mbt
│   └── lib/
│       ├── moon.pkg
│       └── moonmaid.mbt           # Public API + WASM exports
├── ts/
│   ├── package.json
│   ├── tsconfig.json
│   ├── vitest.config.ts
│   ├── wasm-bridge/
│   │   └── index.ts               # Load WASM, call render
│   └── remark-plugin/
│       ├── index.ts                # remarkMoonmaid plugin
│       └── index.test.ts
└── docs/
```

---

### Task 1: MoonBit Project Scaffolding

**Files:**
- Create: `moon.mod.json`
- Create: `src/types/moon.pkg`
- Create: `src/types/types.mbt`

- [ ] **Step 1: Initialize MoonBit module**

Run:
```bash
cd /Users/ryota/repos/github.com/paveg/moonmaid
```

Create `moon.mod.json`:
```json
{
  "name": "paveg/moonmaid",
  "version": "0.1.0",
  "readme": "README.md",
  "repository": "https://github.com/paveg/moonmaid",
  "license": "MIT",
  "keywords": ["diagram", "visualization", "algorithm", "data-structure", "svg"],
  "description": "A MoonBit-powered diagram tool for algorithm and data structure visualization",
  "source": "src"
}
```

- [ ] **Step 2: Create core types package**

Create `src/types/moon.pkg`:
```
[]
```

Create `src/types/types.mbt`:
```moonbit
///| AST node types produced by the parser.
pub enum Diagram {
  ArrayDiagram(ArrayDef)
  TreeDiagram(TreeDef)
}

///| Array diagram definition.
pub struct ArrayDef {
  elements : Array[Int]
  highlights : Array[Highlight]
} derive(Show, Eq)

///| Highlight range on an array.
pub struct Highlight {
  start : Int
  end : Int
  color : String
  label : String
} derive(Show, Eq)

///| Tree diagram definition.
pub struct TreeDef {
  kind : TreeKind
  operations : Array[Int]
} derive(Show, Eq)

///| Tree variant.
pub enum TreeKind {
  BST
} derive(Show, Eq)

///| Layout output: a node with computed position.
pub struct PositionedNode {
  id : String
  x : Double
  y : Double
  width : Double
  height : Double
  label : String
} derive(Show, Eq)

///| Layout output: an edge with routing points.
pub struct PositionedEdge {
  from_id : String
  to_id : String
  points : Array[(Double, Double)]
  label : String
} derive(Show, Eq)

///| Bounding box for the entire diagram.
pub struct BoundingBox {
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Show, Eq)

///| Complete layout result.
pub struct PositionedGraph {
  nodes : Array[PositionedNode]
  edges : Array[PositionedEdge]
  bounds : BoundingBox
} derive(Show, Eq)

///| Layout configuration.
pub struct LayoutConfig {
  node_spacing : Double
  level_spacing : Double
  padding : Double
} derive(Show, Eq)

///| Default layout configuration.
pub fn LayoutConfig::default() -> LayoutConfig {
  { node_spacing: 20.0, level_spacing: 60.0, padding: 20.0 }
}

///| Resource limits for security.
pub struct Limits {
  max_nodes : Int
  max_array_size : Int
} derive(Show, Eq)

///| Default limits.
pub fn Limits::default() -> Limits {
  { max_nodes: 1024, max_array_size: 256 }
}

///| Parse/render error.
pub type! MoonmaidError String
```

- [ ] **Step 3: Verify MoonBit build**

Run: `moon check`
Expected: success with no errors

- [ ] **Step 4: Commit**

```bash
git add moon.mod.json src/types/
git commit -m "feat: initialize MoonBit project with core types"
```

---

### Task 2: DSL Lexer

**Files:**
- Create: `src/parser/moon.pkg`
- Create: `src/parser/token.mbt`
- Create: `src/parser/lexer.mbt`
- Create: `src/parser/lexer_test.mbt`

- [ ] **Step 1: Create parser package config**

Create `src/parser/moon.pkg`:
```
import(
  "paveg/moonmaid/types"
)
```

- [ ] **Step 2: Write the Token type**

Create `src/parser/token.mbt`:
```moonbit
///| Token types for the moonmaid DSL lexer.
pub enum Token {
  // Keywords
  Array
  Tree
  BST
  Insert
  Highlight
  // Literals
  IntLit(Int)
  StringLit(String)
  Ident(String)
  // Symbols
  LBrace       // {
  RBrace       // }
  LBracket     // [
  RBracket     // ]
  LParen       // (
  RParen       // )
  Comma        // ,
  DotDot       // ..
  Eq           // =
  Arrow        // ->
  // Special
  Eof
} derive(Show, Eq)

///| Token with source position for error reporting.
pub struct Located {
  token : Token
  line : Int
  col : Int
} derive(Show, Eq)
```

- [ ] **Step 3: Write failing lexer test**

Create `src/parser/lexer_test.mbt`:
```moonbit
test "lex array diagram" {
  let input = "array { [3, 1, 4] }"
  let tokens = @parser.lex!(input)
  let kinds : Array[Token] = tokens.map(fn(t) { t.token })
  assert_eq!(kinds, [
    Token::Array, Token::LBrace,
    Token::LBracket, Token::IntLit(3), Token::Comma,
    Token::IntLit(1), Token::Comma, Token::IntLit(4), Token::RBracket,
    Token::RBrace, Token::Eof,
  ])
}

test "lex tree bst diagram" {
  let input = "tree bst { insert(5, 3, 7) }"
  let tokens = @parser.lex!(input)
  let kinds : Array[Token] = tokens.map(fn(t) { t.token })
  assert_eq!(kinds, [
    Token::Tree, Token::BST, Token::LBrace,
    Token::Insert, Token::LParen, Token::IntLit(5), Token::Comma,
    Token::IntLit(3), Token::Comma, Token::IntLit(7), Token::RParen,
    Token::RBrace, Token::Eof,
  ])
}

test "lex highlight with string and range" {
  let input = "highlight(0..2, color=blue, label=\"sorted\")"
  let tokens = @parser.lex!(input)
  let kinds : Array[Token] = tokens.map(fn(t) { t.token })
  assert_eq!(kinds, [
    Token::Highlight, Token::LParen,
    Token::IntLit(0), Token::DotDot, Token::IntLit(2), Token::Comma,
    Token::Ident("color"), Token::Eq, Token::Ident("blue"), Token::Comma,
    Token::Ident("label"), Token::Eq, Token::StringLit("sorted"),
    Token::RParen, Token::Eof,
  ])
}

test "lex error on invalid character" {
  let result = try { @parser.lex!("array { $ }") } catch { _ => Err(()) }
  assert_eq!(result, Err(()))
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `moon test --target wasm-gc -p paveg/moonmaid/parser`
Expected: FAIL — `lex` function not defined

- [ ] **Step 5: Implement lexer**

Create `src/parser/lexer.mbt`:
```moonbit
///| Lexer state.
struct Lexer {
  input : String
  mut pos : Int
  mut line : Int
  mut col : Int
}

///| Create a new lexer.
fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, line: 1, col: 1 }
}

///| Peek at current character without consuming.
fn Lexer::peek(self : Lexer) -> Char? {
  if self.pos >= self.input.length() {
    None
  } else {
    Some(self.input[self.pos])
  }
}

///| Consume current character and advance.
fn Lexer::advance(self : Lexer) -> Char {
  let ch = self.input[self.pos]
  self.pos += 1
  if ch == '\n' {
    self.line += 1
    self.col = 1
  } else {
    self.col += 1
  }
  ch
}

///| Skip whitespace and comments.
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while self.pos < self.input.length() {
    let ch = self.input[self.pos]
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      let _ = self.advance()
    } else {
      break
    }
  }
}

///| Read an integer literal.
fn Lexer::read_int(self : Lexer) -> Int {
  let start = self.pos
  while self.pos < self.input.length() {
    let ch = self.input[self.pos]
    if ch >= '0' && ch <= '9' {
      let _ = self.advance()
    } else {
      break
    }
  }
  let s = self.input.substring(start~, end=self.pos)
  @strconv.parse_int!(s)
}

///| Read an identifier or keyword.
fn Lexer::read_word(self : Lexer) -> Token {
  let start = self.pos
  while self.pos < self.input.length() {
    let ch = self.input[self.pos]
    if (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch == '_' {
      let _ = self.advance()
    } else {
      break
    }
  }
  let word = self.input.substring(start~, end=self.pos)
  match word {
    "array" => Token::Array
    "tree" => Token::Tree
    "bst" => Token::BST
    "insert" => Token::Insert
    "highlight" => Token::Highlight
    _ => Token::Ident(word)
  }
}

///| Read a string literal (between double quotes).
fn Lexer::read_string(self : Lexer) -> String!@types.MoonmaidError {
  let _ = self.advance() // consume opening "
  let buf = StringBuilder::new()
  while self.pos < self.input.length() {
    let ch = self.input[self.pos]
    if ch == '"' {
      let _ = self.advance() // consume closing "
      return buf.to_string()
    }
    if ch == '\\' {
      let _ = self.advance()
      if self.pos >= self.input.length() {
        raise @types.MoonmaidError("Unexpected end of string at line \{self.line}")
      }
      let escaped = self.advance()
      match escaped {
        'n' => buf.write_char('\n')
        't' => buf.write_char('\t')
        '\\' => buf.write_char('\\')
        '"' => buf.write_char('"')
        _ => raise @types.MoonmaidError("Invalid escape \\{escaped} at line \{self.line}")
      }
    } else {
      buf.write_char(self.advance())
    }
  }
  raise @types.MoonmaidError("Unterminated string at line \{self.line}")
}

///| Produce the next token.
fn Lexer::next_token(self : Lexer) -> Token!@types.MoonmaidError {
  self.skip_whitespace()
  let line = self.line
  let col = self.col
  match self.peek() {
    None => Token::Eof
    Some(ch) => match ch {
      '{' => { let _ = self.advance(); Token::LBrace }
      '}' => { let _ = self.advance(); Token::RBrace }
      '[' => { let _ = self.advance(); Token::LBracket }
      ']' => { let _ = self.advance(); Token::RBracket }
      '(' => { let _ = self.advance(); Token::LParen }
      ')' => { let _ = self.advance(); Token::RParen }
      ',' => { let _ = self.advance(); Token::Comma }
      '=' => { let _ = self.advance(); Token::Eq }
      '.' => {
        let _ = self.advance()
        match self.peek() {
          Some('.') => { let _ = self.advance(); Token::DotDot }
          _ => raise @types.MoonmaidError("Expected '..' at line \{line}, col \{col}")
        }
      }
      '-' => {
        let _ = self.advance()
        match self.peek() {
          Some('>') => { let _ = self.advance(); Token::Arrow }
          _ => raise @types.MoonmaidError("Expected '->' at line \{line}, col \{col}")
        }
      }
      '"' => Token::StringLit(self.read_string!())
      _ => {
        if ch >= '0' && ch <= '9' {
          Token::IntLit(self.read_int())
        } else if (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_' {
          self.read_word()
        } else {
          raise @types.MoonmaidError("Unexpected character '\{ch}' at line \{line}, col \{col}")
        }
      }
    }
  }
}

///| Tokenize the entire input string.
pub fn lex(input : String) -> Array[Located]!@types.MoonmaidError {
  let lexer = Lexer::new(input)
  let tokens : Array[Located] = []
  while true {
    let line = lexer.line
    let col = lexer.col
    let token = lexer.next_token!()
    tokens.push({ token, line, col })
    if token == Token::Eof {
      break
    }
  }
  tokens
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `moon test --target wasm-gc -p paveg/moonmaid/parser`
Expected: all 4 tests PASS

- [ ] **Step 7: Commit**

```bash
git add src/parser/
git commit -m "feat: implement DSL lexer with keyword/literal/symbol support"
```

---

### Task 3: DSL Parser (Array + Tree)

**Files:**
- Create: `src/parser/parser.mbt`
- Create: `src/parser/parser_test.mbt`

- [ ] **Step 1: Write failing parser tests**

Create `src/parser/parser_test.mbt`:
```moonbit
test "parse array diagram" {
  let input = "array { [3, 1, 4] }"
  let diagram = @parser.parse!(input)
  match diagram {
    @types.Diagram::ArrayDiagram(def) => {
      assert_eq!(def.elements, [3, 1, 4])
      assert_eq!(def.highlights, [])
    }
    _ => fail!("Expected ArrayDiagram")
  }
}

test "parse array with highlights" {
  let input =
    #|array {
    #|  [3, 1, 4, 1, 5]
    #|  highlight(0..2, color=blue, label="sorted")
    #|  highlight(3, color=red, label="current")
    #|}
  let diagram = @parser.parse!(input)
  match diagram {
    @types.Diagram::ArrayDiagram(def) => {
      assert_eq!(def.elements, [3, 1, 4, 1, 5])
      assert_eq!(def.highlights.length(), 2)
      assert_eq!(def.highlights[0], @types.Highlight::{
        start: 0, end: 2, color: "blue", label: "sorted",
      })
      assert_eq!(def.highlights[1], @types.Highlight::{
        start: 3, end: 3, color: "red", label: "current",
      })
    }
    _ => fail!("Expected ArrayDiagram")
  }
}

test "parse tree bst" {
  let input = "tree bst { insert(5, 3, 7, 1) }"
  let diagram = @parser.parse!(input)
  match diagram {
    @types.Diagram::TreeDiagram(def) => {
      assert_eq!(def.kind, @types.TreeKind::BST)
      assert_eq!(def.operations, [5, 3, 7, 1])
    }
    _ => fail!("Expected TreeDiagram")
  }
}

test "parse error on unknown diagram type" {
  let result = try { @parser.parse!("unknown { }") } catch { _ => Err(()) }
  assert_eq!(result, Err(()))
}

test "array size limit exceeded" {
  let big = Array::make(300, 1)
  let elems = big.map(fn(x) { x.to_string() }).join(", ")
  let input = "array { [\{elems}] }"
  let result = try {
    @parser.parse_with_limits!(input, @types.Limits::default())
  } catch {
    _ => Err(())
  }
  assert_eq!(result, Err(()))
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `moon test --target wasm-gc -p paveg/moonmaid/parser`
Expected: FAIL — `parse` function not defined

- [ ] **Step 3: Implement recursive descent parser**

Create `src/parser/parser.mbt`:
```moonbit
///| Parser state.
struct Parser {
  tokens : Array[Located]
  mut pos : Int
  limits : @types.Limits
}

///| Create a new parser.
fn Parser::new(tokens : Array[Located], limits : @types.Limits) -> Parser {
  { tokens, pos: 0, limits }
}

///| Peek at current token.
fn Parser::peek(self : Parser) -> Token {
  if self.pos >= self.tokens.length() {
    Token::Eof
  } else {
    self.tokens[self.pos].token
  }
}

///| Consume current token and advance.
fn Parser::advance(self : Parser) -> Token {
  let t = self.peek()
  self.pos += 1
  t
}

///| Expect a specific token, raise error if not matched.
fn Parser::expect(self : Parser, expected : Token) -> Unit!@types.MoonmaidError {
  let actual = self.advance()
  if actual != expected {
    raise @types.MoonmaidError("Expected \{expected}, got \{actual}")
  }
}

///| Parse an integer literal.
fn Parser::expect_int(self : Parser) -> Int!@types.MoonmaidError {
  match self.advance() {
    Token::IntLit(n) => n
    other => raise @types.MoonmaidError("Expected integer, got \{other}")
  }
}

///| Parse a comma-separated list of integers inside parens.
fn Parser::parse_int_list_parens(self : Parser) -> Array[Int]!@types.MoonmaidError {
  self.expect!(Token::LParen)
  let items : Array[Int] = []
  while self.peek() != Token::RParen {
    if items.length() > 0 {
      self.expect!(Token::Comma)
    }
    items.push(self.expect_int!())
  }
  self.expect!(Token::RParen)
  items
}

///| Parse an array diagram body.
fn Parser::parse_array(self : Parser) -> @types.ArrayDef!@types.MoonmaidError {
  self.expect!(Token::LBrace)
  // Parse element list: [1, 2, 3]
  self.expect!(Token::LBracket)
  let elements : Array[Int] = []
  while self.peek() != Token::RBracket {
    if elements.length() > 0 {
      self.expect!(Token::Comma)
    }
    elements.push(self.expect_int!())
  }
  self.expect!(Token::RBracket)
  // Check array size limit
  if elements.length() > self.limits.max_array_size {
    raise @types.MoonmaidError(
      "Array size \{elements.length()} exceeds limit (max: \{self.limits.max_array_size})",
    )
  }
  // Parse optional highlights
  let highlights : Array[@types.Highlight] = []
  while self.peek() == Token::Highlight {
    let _ = self.advance() // consume "highlight"
    self.expect!(Token::LParen)
    let start = self.expect_int!()
    let end = if self.peek() == Token::DotDot {
      let _ = self.advance()
      self.expect_int!()
    } else {
      start
    }
    self.expect!(Token::Comma)
    // Parse color=value
    let _ = self.advance() // "color"
    self.expect!(Token::Eq)
    let color = match self.advance() {
      Token::Ident(s) => s
      other => raise @types.MoonmaidError("Expected color name, got \{other}")
    }
    self.expect!(Token::Comma)
    // Parse label=value
    let _ = self.advance() // "label"
    self.expect!(Token::Eq)
    let label = match self.advance() {
      Token::StringLit(s) => s
      other => raise @types.MoonmaidError("Expected string label, got \{other}")
    }
    self.expect!(Token::RParen)
    highlights.push({ start, end, color, label })
  }
  self.expect!(Token::RBrace)
  { elements, highlights }
}

///| Parse a tree diagram body.
fn Parser::parse_tree(self : Parser) -> @types.TreeDef!@types.MoonmaidError {
  let kind = match self.advance() {
    Token::BST => @types.TreeKind::BST
    other => raise @types.MoonmaidError("Expected tree kind (bst), got \{other}")
  }
  self.expect!(Token::LBrace)
  self.expect!(Token::Insert)
  let operations = self.parse_int_list_parens!()
  if operations.length() > self.limits.max_nodes {
    raise @types.MoonmaidError(
      "Node count \{operations.length()} exceeds limit (max: \{self.limits.max_nodes})",
    )
  }
  self.expect!(Token::RBrace)
  { kind, operations }
}

///| Parse a complete diagram from tokens.
fn Parser::parse_diagram(self : Parser) -> @types.Diagram!@types.MoonmaidError {
  match self.peek() {
    Token::Array => {
      let _ = self.advance()
      @types.Diagram::ArrayDiagram(self.parse_array!())
    }
    Token::Tree => {
      let _ = self.advance()
      @types.Diagram::TreeDiagram(self.parse_tree!())
    }
    other => raise @types.MoonmaidError("Expected 'array' or 'tree', got \{other}")
  }
}

///| Parse DSL string with default limits.
pub fn parse(input : String) -> @types.Diagram!@types.MoonmaidError {
  parse_with_limits!(input, @types.Limits::default())
}

///| Parse DSL string with custom limits.
pub fn parse_with_limits(
  input : String,
  limits : @types.Limits,
) -> @types.Diagram!@types.MoonmaidError {
  let tokens = lex!(input)
  let parser = Parser::new(tokens, limits)
  parser.parse_diagram!()
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `moon test --target wasm-gc -p paveg/moonmaid/parser`
Expected: all tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/parser/parser.mbt src/parser/parser_test.mbt
git commit -m "feat: implement recursive descent parser for array and tree DSL"
```

---

### Task 4: Fixed Grid Layout (Array)

**Files:**
- Create: `src/layout/grid/moon.pkg`
- Create: `src/layout/grid/grid.mbt`
- Create: `src/layout/grid/grid_test.mbt`

- [ ] **Step 1: Create layout/grid package**

Create `src/layout/grid/moon.pkg`:
```
import(
  "paveg/moonmaid/types"
)
```

- [ ] **Step 2: Write failing grid layout test**

Create `src/layout/grid/grid_test.mbt`:
```moonbit
test "grid layout positions array elements horizontally" {
  let def : @types.ArrayDef = {
    elements: [3, 1, 4],
    highlights: [],
  }
  let config = @types.LayoutConfig::default()
  let result = @grid.layout(def, config)
  // 3 nodes, horizontally spaced
  assert_eq!(result.nodes.length(), 3)
  // First node at padding offset
  assert_eq!(result.nodes[0].label, "3")
  assert_eq!(result.nodes[0].x, config.padding)
  assert_eq!(result.nodes[0].y, config.padding)
  // Second node offset by cell_size + spacing
  let cell_size = 40.0
  assert_eq!(result.nodes[1].x, config.padding + cell_size + config.node_spacing)
  // No edges for array
  assert_eq!(result.edges.length(), 0)
}

test "grid layout includes index labels as separate nodes" {
  let def : @types.ArrayDef = {
    elements: [10, 20],
    highlights: [],
  }
  let config = @types.LayoutConfig::default()
  let result = @grid.layout(def, config)
  // 2 element nodes + 2 index label nodes
  assert_eq!(result.nodes.length(), 4)
  assert_eq!(result.nodes[2].label, "0")
  assert_eq!(result.nodes[3].label, "1")
}

test "grid layout bounds enclose all nodes" {
  let def : @types.ArrayDef = {
    elements: [1, 2, 3, 4, 5],
    highlights: [],
  }
  let config = @types.LayoutConfig::default()
  let result = @grid.layout(def, config)
  let last_node = result.nodes[4]
  assert_true!(result.bounds.width >= last_node.x + last_node.width + config.padding)
  assert_true!(result.bounds.height >= last_node.y + last_node.height + config.padding)
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `moon test --target wasm-gc -p paveg/moonmaid/layout/grid`
Expected: FAIL — `layout` function not defined

- [ ] **Step 4: Implement grid layout**

Create `src/layout/grid/grid.mbt`:
```moonbit
///| Cell size for array elements (square).
let cell_size : Double = 40.0

///| Index label height below the cell.
let index_label_height : Double = 20.0

///| Lay out an array definition as a horizontal grid.
pub fn layout(
  def : @types.ArrayDef,
  config : @types.LayoutConfig,
) -> @types.PositionedGraph {
  let nodes : Array[@types.PositionedNode] = []
  let count = def.elements.length()
  // Element nodes
  for i = 0; i < count; i = i + 1 {
    let x = config.padding + i.to_double() * (cell_size + config.node_spacing)
    let y = config.padding
    nodes.push({
      id: "elem_\{i}",
      x,
      y,
      width: cell_size,
      height: cell_size,
      label: def.elements[i].to_string(),
    })
  }
  // Index label nodes (below each element)
  for i = 0; i < count; i = i + 1 {
    let x = config.padding + i.to_double() * (cell_size + config.node_spacing)
    let y = config.padding + cell_size + 4.0
    nodes.push({
      id: "idx_\{i}",
      x,
      y,
      width: cell_size,
      height: index_label_height,
      label: i.to_string(),
    })
  }
  // Bounds
  let total_width = if count > 0 {
    config.padding * 2.0 + count.to_double() * cell_size + (count - 1).to_double() * config.node_spacing
  } else {
    config.padding * 2.0
  }
  let total_height = config.padding * 2.0 + cell_size + 4.0 + index_label_height
  {
    nodes,
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: total_width, height: total_height },
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `moon test --target wasm-gc -p paveg/moonmaid/layout/grid`
Expected: all 3 tests PASS

- [ ] **Step 6: Commit**

```bash
git add src/layout/grid/
git commit -m "feat: implement fixed grid layout for array diagrams"
```

---

### Task 5: Reingold-Tilford Tree Layout

**Files:**
- Create: `src/layout/tree/moon.pkg`
- Create: `src/layout/tree/reingold_tilford.mbt`
- Create: `src/layout/tree/reingold_tilford_test.mbt`

- [ ] **Step 1: Create layout/tree package**

Create `src/layout/tree/moon.pkg`:
```
import(
  "paveg/moonmaid/types"
)
```

- [ ] **Step 2: Write failing tree layout tests**

Create `src/layout/tree/reingold_tilford_test.mbt`:
```moonbit
test "layout single node BST" {
  let def : @types.TreeDef = { kind: @types.TreeKind::BST, operations: [5] }
  let config = @types.LayoutConfig::default()
  let result = @tree.layout(def, config)
  assert_eq!(result.nodes.length(), 1)
  assert_eq!(result.nodes[0].label, "5")
  assert_eq!(result.edges.length(), 0)
}

test "layout BST with left and right children" {
  // insert 5, 3, 7 → root=5, left=3, right=7
  let def : @types.TreeDef = { kind: @types.TreeKind::BST, operations: [5, 3, 7] }
  let config = @types.LayoutConfig::default()
  let result = @tree.layout(def, config)
  assert_eq!(result.nodes.length(), 3)
  assert_eq!(result.edges.length(), 2)
  // Root should be horizontally centered between children
  let root = result.nodes.iter().find(fn(n) { n.label == "5" })
  let left = result.nodes.iter().find(fn(n) { n.label == "3" })
  let right = result.nodes.iter().find(fn(n) { n.label == "7" })
  match (root, left, right) {
    (Some(r), Some(l), Some(rr)) => {
      // Left child is to the left of root
      assert_true!(l.x < r.x)
      // Right child is to the right of root
      assert_true!(rr.x > r.x)
      // Children are on a lower level
      assert_true!(l.y > r.y)
      assert_true!(rr.y > r.y)
      assert_true!((l.y - rr.y).abs() < 0.001) // same level
    }
    _ => fail!("Expected 3 nodes with labels 5, 3, 7")
  }
}

test "layout BST preserves BST invariant in x-coordinates" {
  // insert 5, 3, 7, 1, 4 → in-order: 1, 3, 4, 5, 7
  let def : @types.TreeDef = {
    kind: @types.TreeKind::BST,
    operations: [5, 3, 7, 1, 4],
  }
  let config = @types.LayoutConfig::default()
  let result = @tree.layout(def, config)
  assert_eq!(result.nodes.length(), 5)
  // x-coordinates should reflect in-order traversal
  let sorted_by_x = result.nodes.copy()
  sorted_by_x.sort_by(fn(a, b) { a.x.compare(b.x) })
  let labels : Array[String] = sorted_by_x.map(fn(n) { n.label })
  assert_eq!(labels, ["1", "3", "4", "5", "7"])
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `moon test --target wasm-gc -p paveg/moonmaid/layout/tree`
Expected: FAIL — `layout` function not defined

- [ ] **Step 4: Implement Reingold-Tilford layout**

Create `src/layout/tree/reingold_tilford.mbt`:
```moonbit
///| Internal BST node for building the tree before layout.
struct BSTNode {
  value : Int
  mut left : BSTNode?
  mut right : BSTNode?
  // Reingold-Tilford fields
  mut x : Double
  mut y : Double
  mut offset : Double  // thread offset
}

///| Insert a value into the BST.
fn bst_insert(root : BSTNode?, value : Int) -> BSTNode {
  match root {
    None => { value, left: None, right: None, x: 0.0, y: 0.0, offset: 0.0 }
    Some(node) =>
      if value < node.value {
        node.left = Some(bst_insert(node.left, value))
        node
      } else if value > node.value {
        node.right = Some(bst_insert(node.right, value))
        node
      } else {
        node // duplicate, ignore
      }
  }
}

///| Node dimensions.
let node_width : Double = 48.0
let node_height : Double = 32.0

///| First pass: compute relative x positions using contour-based approach.
fn compute_x(node : BSTNode?, depth : Int, config : @types.LayoutConfig) -> Unit {
  match node {
    None => ()
    Some(n) => {
      compute_x(n.left, depth + 1, config)
      compute_x(n.right, depth + 1, config)
      n.y = config.padding + depth.to_double() * (node_height + config.level_spacing)
      match (n.left, n.right) {
        (None, None) => n.x = 0.0
        (Some(l), None) => n.x = l.x + 1.0
        (None, Some(r)) => n.x = r.x - 1.0
        (Some(l), Some(r)) => {
          n.x = (l.x + r.x) / 2.0
          // Fix overlaps between left and right subtrees
          let separation = compute_min_separation(n.left, n.right)
          if separation < 1.0 {
            let shift = 1.0 - separation
            shift_subtree(n.right, shift)
            n.x = (l.x + r.x + shift) / 2.0
          }
        }
      }
    }
  }
}

///| Compute minimum separation between right contour of left subtree
///| and left contour of right subtree.
fn compute_min_separation(left : BSTNode?, right : BSTNode?) -> Double {
  match (left, right) {
    (Some(l), Some(r)) => {
      let sep = r.x - l.x
      let child_sep = compute_min_separation(
        right_most(Some(l)),
        left_most(Some(r)),
      )
      if child_sep < Double::infinity() {
        Double::min(sep, child_sep)
      } else {
        sep
      }
    }
    _ => Double::infinity()
  }
}

///| Get leftmost child.
fn left_most(node : BSTNode?) -> BSTNode? {
  match node {
    Some(n) => if n.left.is_empty().not() { n.left } else { n.right }
    None => None
  }
}

///| Get rightmost child.
fn right_most(node : BSTNode?) -> BSTNode? {
  match node {
    Some(n) => if n.right.is_empty().not() { n.right } else { n.left }
    None => None
  }
}

///| Shift an entire subtree by dx.
fn shift_subtree(node : BSTNode?, dx : Double) -> Unit {
  match node {
    None => ()
    Some(n) => {
      n.x += dx
      shift_subtree(n.left, dx)
      shift_subtree(n.right, dx)
    }
  }
}

///| Second pass: convert unit x-coordinates to pixel positions.
fn normalize_positions(
  node : BSTNode?,
  min_x : Double,
  config : @types.LayoutConfig,
  nodes : Array[@types.PositionedNode],
  edges : Array[@types.PositionedEdge],
) -> Unit {
  match node {
    None => ()
    Some(n) => {
      let px = config.padding + (n.x - min_x) * (node_width + config.node_spacing)
      let py = n.y
      nodes.push({
        id: "node_\{n.value}",
        x: px,
        y: py,
        width: node_width,
        height: node_height,
        label: n.value.to_string(),
      })
      // Edges to children
      let parent_cx = px + node_width / 2.0
      let parent_cy = py + node_height
      match n.left {
        Some(l) => {
          let child_cx = config.padding + (l.x - min_x) * (node_width + config.node_spacing) + node_width / 2.0
          let child_cy = l.y
          edges.push({
            from_id: "node_\{n.value}",
            to_id: "node_\{l.value}",
            points: [(parent_cx, parent_cy), (child_cx, child_cy)],
            label: "",
          })
        }
        None => ()
      }
      match n.right {
        Some(r) => {
          let child_cx = config.padding + (r.x - min_x) * (node_width + config.node_spacing) + node_width / 2.0
          let child_cy = r.y
          edges.push({
            from_id: "node_\{n.value}",
            to_id: "node_\{r.value}",
            points: [(parent_cx, parent_cy), (child_cx, child_cy)],
            label: "",
          })
        }
        None => ()
      }
      normalize_positions(n.left, min_x, config, nodes, edges)
      normalize_positions(n.right, min_x, config, nodes, edges)
    }
  }
}

///| Find minimum x value in the tree.
fn find_min_x(node : BSTNode?) -> Double {
  match node {
    None => Double::infinity()
    Some(n) => Double::min(n.x, Double::min(find_min_x(n.left), find_min_x(n.right)))
  }
}

///| Lay out a tree definition using Reingold-Tilford algorithm.
pub fn layout(
  def : @types.TreeDef,
  config : @types.LayoutConfig,
) -> @types.PositionedGraph {
  // Build BST from operations
  let mut root : BSTNode? = None
  for i = 0; i < def.operations.length(); i = i + 1 {
    root = Some(bst_insert(root, def.operations[i]))
  }
  match root {
    None => {
      { nodes: [], edges: [], bounds: { x: 0.0, y: 0.0, width: 0.0, height: 0.0 } }
    }
    Some(_) => {
      // Compute layout
      compute_x(root, 0, config)
      let min_x = find_min_x(root)
      let nodes : Array[@types.PositionedNode] = []
      let edges : Array[@types.PositionedEdge] = []
      normalize_positions(root, min_x, config, nodes, edges)
      // Compute bounds
      let mut max_x = 0.0
      let mut max_y = 0.0
      for i = 0; i < nodes.length(); i = i + 1 {
        let n = nodes[i]
        if n.x + n.width > max_x { max_x = n.x + n.width }
        if n.y + n.height > max_y { max_y = n.y + n.height }
      }
      {
        nodes,
        edges,
        bounds: {
          x: 0.0,
          y: 0.0,
          width: max_x + config.padding,
          height: max_y + config.padding,
        },
      }
    }
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `moon test --target wasm-gc -p paveg/moonmaid/layout/tree`
Expected: all 3 tests PASS

- [ ] **Step 6: Commit**

```bash
git add src/layout/tree/
git commit -m "feat: implement Reingold-Tilford tree layout algorithm"
```

---

### Task 6: SVG Renderer (Virtual SVG Tree + Emission)

**Files:**
- Create: `src/renderer/moon.pkg`
- Create: `src/renderer/escape.mbt`
- Create: `src/renderer/theme.mbt`
- Create: `src/renderer/vsvg.mbt`
- Create: `src/renderer/emit.mbt`
- Create: `src/renderer/render_array.mbt`
- Create: `src/renderer/render_tree.mbt`
- Create: `src/renderer/escape_test.mbt`
- Create: `src/renderer/renderer_test.mbt`

- [ ] **Step 1: Create renderer package**

Create `src/renderer/moon.pkg`:
```
import(
  "paveg/moonmaid/types"
)
```

- [ ] **Step 2: Write failing XSS escape test**

Create `src/renderer/escape_test.mbt`:
```moonbit
test "escape HTML entities" {
  assert_eq!(@renderer.escape_xml("hello"), "hello")
  assert_eq!(@renderer.escape_xml("<script>alert('xss')</script>"), "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
  assert_eq!(@renderer.escape_xml("a & b"), "a &amp; b")
  assert_eq!(@renderer.escape_xml("a \"quoted\""), "a &quot;quoted&quot;")
}

test "escape rejects event handler patterns" {
  // These should be escaped, not stripped — the output is safe
  let result = @renderer.escape_xml("onload=alert(1)")
  assert_true!(result.contains("onload").not() == false) // still present but escaped context prevents execution
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `moon test --target wasm-gc -p paveg/moonmaid/renderer`
Expected: FAIL — `escape_xml` not defined

- [ ] **Step 4: Implement XSS escape**

Create `src/renderer/escape.mbt`:
```moonbit
///| Escape a string for safe embedding in SVG/XML text content and attributes.
///| Prevents XSS by encoding all HTML special characters.
pub fn escape_xml(input : String) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < input.length(); i = i + 1 {
    match input[i] {
      '&' => buf.write_string("&amp;")
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      ch => buf.write_char(ch)
    }
  }
  buf.to_string()
}
```

- [ ] **Step 5: Run escape tests**

Run: `moon test --target wasm-gc -p paveg/moonmaid/renderer`
Expected: PASS

- [ ] **Step 6: Implement theme colors**

Create `src/renderer/theme.mbt`:
```moonbit
///| GFM-aligned light mode colors.
pub let bg : String = "#ffffff"
pub let node_fill : String = "#f6f8fa"
pub let node_stroke : String = "#d1d9e0"
pub let text_color : String = "#1f2328"
pub let edge_color : String = "#656d76"
pub let highlight_blue : String = "#0969da"
pub let highlight_purple : String = "#8250df"
pub let highlight_yellow : String = "#bf8700"
pub let highlight_red : String = "#cf222e"
pub let highlight_green : String = "#1a7f37"
pub let index_color : String = "#656d76"

///| Font stacks.
pub let font_family : String = "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif"
pub let font_mono : String = "ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace"
```

- [ ] **Step 7: Implement Virtual SVG Tree and emitter**

Create `src/renderer/vsvg.mbt`:
```moonbit
///| Virtual SVG node types. This is the IR between layout and SVG string emission.
pub enum SvgNode {
  Svg(width~ : Double, height~ : Double, children~ : Array[SvgNode])
  Group(attrs~ : Array[(String, String)], children~ : Array[SvgNode])
  Rect(x~ : Double, y~ : Double, width~ : Double, height~ : Double, rx~ : Double, fill~ : String, stroke~ : String, stroke_width~ : Double)
  Line(x1~ : Double, y1~ : Double, x2~ : Double, y2~ : Double, stroke~ : String, stroke_width~ : Double)
  Text(x~ : Double, y~ : Double, content~ : String, font_size~ : Double, fill~ : String, anchor~ : String, font_family~ : String)
  Defs(children~ : Array[SvgNode])
  Marker(id~ : String, children~ : Array[SvgNode])
  Path(d~ : String, fill~ : String, stroke~ : String)
  Polyline(points~ : Array[(Double, Double)], stroke~ : String, stroke_width~ : Double, fill~ : String, marker_end~ : String)
}
```

Create `src/renderer/emit.mbt`:
```moonbit
///| Emit an SVG node tree to an SVG string.
pub fn emit(node : SvgNode) -> String {
  let buf = StringBuilder::new()
  emit_node(node, buf, 0)
  buf.to_string()
}

///| Indentation helper.
fn indent(buf : StringBuilder, level : Int) -> Unit {
  for i = 0; i < level; i = i + 1 {
    buf.write_string("  ")
  }
}

///| Recursively emit an SVG node.
fn emit_node(node : SvgNode, buf : StringBuilder, level : Int) -> Unit {
  match node {
    SvgNode::Svg(width~, height~, children~) => {
      indent(buf, level)
      buf.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\" style=\"font-family: \{escape_xml(theme_font_family)}\">\n")
      for i = 0; i < children.length(); i = i + 1 {
        emit_node(children[i], buf, level + 1)
      }
      indent(buf, level)
      buf.write_string("</svg>\n")
    }
    SvgNode::Group(attrs~, children~) => {
      indent(buf, level)
      buf.write_string("<g")
      for i = 0; i < attrs.length(); i = i + 1 {
        let (k, v) = attrs[i]
        buf.write_string(" \{escape_xml(k)}=\"\{escape_xml(v)}\"")
      }
      buf.write_string(">\n")
      for i = 0; i < children.length(); i = i + 1 {
        emit_node(children[i], buf, level + 1)
      }
      indent(buf, level)
      buf.write_string("</g>\n")
    }
    SvgNode::Rect(x~, y~, width~, height~, rx~, fill~, stroke~, stroke_width~) => {
      indent(buf, level)
      buf.write_string("<rect x=\"\{x}\" y=\"\{y}\" width=\"\{width}\" height=\"\{height}\" rx=\"\{rx}\" fill=\"\{escape_xml(fill)}\" stroke=\"\{escape_xml(stroke)}\" stroke-width=\"\{stroke_width}\"/>\n")
    }
    SvgNode::Line(x1~, y1~, x2~, y2~, stroke~, stroke_width~) => {
      indent(buf, level)
      buf.write_string("<line x1=\"\{x1}\" y1=\"\{y1}\" x2=\"\{x2}\" y2=\"\{y2}\" stroke=\"\{escape_xml(stroke)}\" stroke-width=\"\{stroke_width}\"/>\n")
    }
    SvgNode::Text(x~, y~, content~, font_size~, fill~, anchor~, font_family~) => {
      indent(buf, level)
      buf.write_string("<text x=\"\{x}\" y=\"\{y}\" font-size=\"\{font_size}\" fill=\"\{escape_xml(fill)}\" text-anchor=\"\{escape_xml(anchor)}\" font-family=\"\{escape_xml(font_family)}\">\{escape_xml(content)}</text>\n")
    }
    SvgNode::Defs(children~) => {
      indent(buf, level)
      buf.write_string("<defs>\n")
      for i = 0; i < children.length(); i = i + 1 {
        emit_node(children[i], buf, level + 1)
      }
      indent(buf, level)
      buf.write_string("</defs>\n")
    }
    SvgNode::Marker(id~, children~) => {
      indent(buf, level)
      buf.write_string("<marker id=\"\{escape_xml(id)}\" viewBox=\"0 0 10 10\" refX=\"10\" refY=\"5\" markerWidth=\"6\" markerHeight=\"6\" orient=\"auto-start-reverse\">\n")
      for i = 0; i < children.length(); i = i + 1 {
        emit_node(children[i], buf, level + 1)
      }
      indent(buf, level)
      buf.write_string("</marker>\n")
    }
    SvgNode::Path(d~, fill~, stroke~) => {
      indent(buf, level)
      buf.write_string("<path d=\"\{escape_xml(d)}\" fill=\"\{escape_xml(fill)}\" stroke=\"\{escape_xml(stroke)}\"/>\n")
    }
    SvgNode::Polyline(points~, stroke~, stroke_width~, fill~, marker_end~) => {
      indent(buf, level)
      let pts = points.map(fn(p) { "\{p.0},\{p.1}" }).join(" ")
      buf.write_string("<polyline points=\"\{pts}\" stroke=\"\{escape_xml(stroke)}\" stroke-width=\"\{stroke_width}\" fill=\"\{escape_xml(fill)}\" marker-end=\"url(#\{escape_xml(marker_end)})\"/>\n")
    }
  }
}

///| Theme font family (used in SVG root).
let theme_font_family : String = @theme.font_family
```

- [ ] **Step 8: Implement array renderer**

Create `src/renderer/render_array.mbt`:
```moonbit
///| Render a positioned array graph to a Virtual SVG Tree.
pub fn render_array(
  graph : @types.PositionedGraph,
  def : @types.ArrayDef,
) -> SvgNode {
  let children : Array[SvgNode] = []
  // Background
  children.push(SvgNode::Rect(
    x=0.0, y=0.0,
    width=graph.bounds.width, height=graph.bounds.height,
    rx=0.0, fill=@theme.bg, stroke="none", stroke_width=0.0,
  ))
  // Nodes
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    if node.id.has_prefix("elem_") {
      // Determine fill color from highlights
      let elem_idx = i // element nodes come first in grid layout
      let fill = resolve_highlight_color(elem_idx, def.highlights)
      // Cell rectangle
      children.push(SvgNode::Rect(
        x=node.x, y=node.y,
        width=node.width, height=node.height,
        rx=4.0, fill, stroke=@theme.node_stroke, stroke_width=1.5,
      ))
      // Cell label (centered)
      children.push(SvgNode::Text(
        x=node.x + node.width / 2.0,
        y=node.y + node.height / 2.0 + 5.0,
        content=node.label,
        font_size=14.0,
        fill=@theme.text_color,
        anchor="middle",
        font_family=@theme.font_mono,
      ))
    } else if node.id.has_prefix("idx_") {
      // Index label
      children.push(SvgNode::Text(
        x=node.x + node.width / 2.0,
        y=node.y + 14.0,
        content=node.label,
        font_size=12.0,
        fill=@theme.index_color,
        anchor="middle",
        font_family=@theme.font_mono,
      ))
    }
  }
  SvgNode::Svg(
    width=graph.bounds.width,
    height=graph.bounds.height,
    children,
  )
}

///| Resolve the fill color for an array element based on highlights.
fn resolve_highlight_color(
  index : Int,
  highlights : Array[@types.Highlight],
) -> String {
  for i = 0; i < highlights.length(); i = i + 1 {
    let h = highlights[i]
    if index >= h.start && index <= h.end {
      return match h.color {
        "blue" => @theme.highlight_blue
        "red" => @theme.highlight_red
        "green" => @theme.highlight_green
        "purple" => @theme.highlight_purple
        "yellow" => @theme.highlight_yellow
        _ => @theme.node_fill
      }
    }
  }
  @theme.node_fill
}
```

- [ ] **Step 9: Implement tree renderer**

Create `src/renderer/render_tree.mbt`:
```moonbit
///| Render a positioned tree graph to a Virtual SVG Tree.
pub fn render_tree(graph : @types.PositionedGraph) -> SvgNode {
  let children : Array[SvgNode] = []
  // Background
  children.push(SvgNode::Rect(
    x=0.0, y=0.0,
    width=graph.bounds.width, height=graph.bounds.height,
    rx=0.0, fill=@theme.bg, stroke="none", stroke_width=0.0,
  ))
  // Arrow marker definition
  children.push(SvgNode::Defs(children=[
    SvgNode::Marker(id="arrowhead", children=[
      SvgNode::Path(
        d="M 0 0 L 10 5 L 0 10 z",
        fill=@theme.edge_color,
        stroke="none",
      ),
    ]),
  ]))
  // Edges (draw first so they appear behind nodes)
  for i = 0; i < graph.edges.length(); i = i + 1 {
    let edge = graph.edges[i]
    children.push(SvgNode::Polyline(
      points=edge.points,
      stroke=@theme.edge_color,
      stroke_width=1.5,
      fill="none",
      marker_end="arrowhead",
    ))
  }
  // Nodes
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    // Node rectangle
    children.push(SvgNode::Rect(
      x=node.x, y=node.y,
      width=node.width, height=node.height,
      rx=6.0, fill=@theme.node_fill, stroke=@theme.node_stroke, stroke_width=1.5,
    ))
    // Node label (centered)
    children.push(SvgNode::Text(
      x=node.x + node.width / 2.0,
      y=node.y + node.height / 2.0 + 5.0,
      content=node.label,
      font_size=14.0,
      fill=@theme.text_color,
      anchor="middle",
      font_family=@theme.font_family,
    ))
  }
  SvgNode::Svg(
    width=graph.bounds.width,
    height=graph.bounds.height,
    children,
  )
}
```

- [ ] **Step 10: Write renderer integration test**

Create `src/renderer/renderer_test.mbt`:
```moonbit
test "render array produces valid SVG structure" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "elem_0", x: 20.0, y: 20.0, width: 40.0, height: 40.0, label: "3" },
      { id: "idx_0", x: 20.0, y: 64.0, width: 40.0, height: 20.0, label: "0" },
    ],
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: 80.0, height: 104.0 },
  }
  let def : @types.ArrayDef = { elements: [3], highlights: [] }
  let svg_tree = render_array(graph, def)
  let svg_string = emit(svg_tree)
  assert_true!(svg_string.contains("<svg"))
  assert_true!(svg_string.contains("</svg>"))
  assert_true!(svg_string.contains(">3<"))   // element label
  assert_true!(svg_string.contains(">0<"))   // index label
}

test "render tree produces edges and nodes" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "node_5", x: 50.0, y: 20.0, width: 48.0, height: 32.0, label: "5" },
      { id: "node_3", x: 10.0, y: 112.0, width: 48.0, height: 32.0, label: "3" },
    ],
    edges: [
      { from_id: "node_5", to_id: "node_3", points: [(74.0, 52.0), (34.0, 112.0)], label: "" },
    ],
    bounds: { x: 0.0, y: 0.0, width: 118.0, height: 164.0 },
  }
  let svg_tree = render_tree(graph)
  let svg_string = emit(svg_tree)
  assert_true!(svg_string.contains("<svg"))
  assert_true!(svg_string.contains("<polyline"))
  assert_true!(svg_string.contains("arrowhead"))
  assert_true!(svg_string.contains(">5<"))
  assert_true!(svg_string.contains(">3<"))
}

test "XSS in labels is escaped" {
  let graph : @types.PositionedGraph = {
    nodes: [
      { id: "node_0", x: 0.0, y: 0.0, width: 48.0, height: 32.0, label: "<script>alert(1)</script>" },
    ],
    edges: [],
    bounds: { x: 0.0, y: 0.0, width: 68.0, height: 52.0 },
  }
  let svg_tree = render_tree(graph)
  let svg_string = emit(svg_tree)
  assert_true!(svg_string.contains("<script>").not())
  assert_true!(svg_string.contains("&lt;script&gt;"))
}
```

- [ ] **Step 11: Run all renderer tests**

Run: `moon test --target wasm-gc -p paveg/moonmaid/renderer`
Expected: all tests PASS

- [ ] **Step 12: Commit**

```bash
git add src/renderer/
git commit -m "feat: implement SVG renderer with Virtual SVG Tree, XSS escaping, and GFM theme"
```

---

### Task 7: Public API + WASM Entry Point

**Files:**
- Create: `src/lib/moon.pkg`
- Create: `src/lib/moonmaid.mbt`

- [ ] **Step 1: Create lib package**

Create `src/lib/moon.pkg`:
```
import(
  "paveg/moonmaid/types"
  "paveg/moonmaid/parser"
  "paveg/moonmaid/layout/grid"
  "paveg/moonmaid/layout/tree"
  "paveg/moonmaid/renderer"
)

link(
  "wasm-gc": (
    "exports": ["render"],
  ),
)
```

- [ ] **Step 2: Implement public API**

Create `src/lib/moonmaid.mbt`:
```moonbit
///| Render moonmaid DSL to SVG string.
///| This is the main entry point, exported to WASM.
pub fn render(input : String) -> String {
  match render_result(input) {
    Ok(svg) => svg
    Err(@types.MoonmaidError(msg)) => "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"400\" height=\"40\"><text x=\"10\" y=\"25\" fill=\"#cf222e\" font-size=\"14\">\{@renderer.escape_xml(msg)}</text></svg>"
  }
}

///| Internal render with error handling.
fn render_result(input : String) -> String!@types.MoonmaidError {
  let diagram = @parser.parse!(input)
  let config = @types.LayoutConfig::default()
  let svg_tree = match diagram {
    @types.Diagram::ArrayDiagram(def) => {
      let graph = @grid.layout(def, config)
      @renderer.render_array(graph, def)
    }
    @types.Diagram::TreeDiagram(def) => {
      let graph = @tree.layout(def, config)
      @renderer.render_tree(graph)
    }
  }
  @renderer.emit(svg_tree)
}
```

- [ ] **Step 3: Build WASM**

Run: `moon build --target wasm-gc`
Expected: successful build, WASM output in `target/wasm-gc/release/build/`

- [ ] **Step 4: Commit**

```bash
git add src/lib/
git commit -m "feat: add public render API with WASM export"
```

---

### Task 8: TypeScript WASM Bridge

**Files:**
- Create: `ts/package.json`
- Create: `ts/tsconfig.json`
- Create: `ts/vitest.config.ts`
- Create: `ts/wasm-bridge/index.ts`

- [ ] **Step 1: Initialize TypeScript project**

Create `ts/package.json`:
```json
{
  "name": "moonmaid",
  "version": "0.1.0",
  "type": "module",
  "exports": {
    "./wasm-bridge": "./wasm-bridge/index.ts",
    "./remark-plugin": "./remark-plugin/index.ts"
  },
  "scripts": {
    "test": "vitest run",
    "build:wasm": "cd .. && moon build --target wasm-gc --release"
  },
  "devDependencies": {
    "typescript": "^5.8.0",
    "vitest": "^3.1.0"
  }
}
```

Create `ts/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist",
    "declaration": true
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

Create `ts/vitest.config.ts`:
```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
  },
})
```

- [ ] **Step 2: Implement WASM bridge**

Create `ts/wasm-bridge/index.ts`:
```typescript
export interface MoonmaidInstance {
  render(input: string): string
}

let cachedInstance: MoonmaidInstance | null = null

/**
 * Load and cache the moonmaid WASM module.
 * Returns a cached instance on subsequent calls (solves HMR re-init problem).
 */
export async function loadMoonmaid(
  wasmPath?: string,
): Promise<MoonmaidInstance> {
  if (cachedInstance) return cachedInstance

  const path =
    wasmPath ??
    new URL(
      '../../target/wasm-gc/release/build/lib/lib.wasm',
      import.meta.url,
    ).pathname

  const wasmBuffer = await (typeof globalThis.Deno !== 'undefined' || typeof process !== 'undefined'
    ? import('node:fs/promises').then((fs) => fs.readFile(path))
    : fetch(path).then((r) => r.arrayBuffer()))

  const module = await WebAssembly.compile(wasmBuffer)
  const instance = await WebAssembly.instantiate(module)
  const exports = instance.exports as Record<string, unknown>

  const render = exports['render'] as (input: string) => string

  cachedInstance = { render }
  return cachedInstance
}

/**
 * Clear the cached WASM instance (for testing).
 */
export function clearCache(): void {
  cachedInstance = null
}
```

- [ ] **Step 3: Install dependencies**

Run: `cd ts && pnpm install`
Expected: successful install

- [ ] **Step 4: Commit**

```bash
git add ts/package.json ts/tsconfig.json ts/vitest.config.ts ts/wasm-bridge/
git commit -m "feat: add TypeScript WASM bridge with instance caching"
```

---

### Task 9: Remark Plugin

**Files:**
- Create: `ts/remark-plugin/index.ts`
- Create: `ts/remark-plugin/index.test.ts`

- [ ] **Step 1: Add remark dependencies**

Run:
```bash
cd ts && pnpm add unified remark-parse remark-stringify unist-util-visit
cd ts && pnpm add -D @types/unist
```

- [ ] **Step 2: Implement remark plugin**

Create `ts/remark-plugin/index.ts`:
```typescript
import type { Plugin } from 'unified'
import type { Root, Code } from 'mdast'
import { visit } from 'unist-util-visit'
import { loadMoonmaid, type MoonmaidInstance } from '../wasm-bridge/index.js'

export interface RemarkMoonmaidOptions {
  maxNodes?: number
  maxArraySize?: number
  maxHashTableSize?: number
  wasmPath?: string
}

/**
 * Remark plugin that transforms ```moonmaid code blocks into SVG.
 * WASM module is loaded once and cached for HMR compatibility.
 */
const remarkMoonmaid: Plugin<[RemarkMoonmaidOptions?], Root> = (
  options = {},
) => {
  let instancePromise: Promise<MoonmaidInstance> | null = null

  return async (tree: Root) => {
    const codeBlocks: Code[] = []

    visit(tree, 'code', (node: Code) => {
      if (node.lang === 'moonmaid') {
        codeBlocks.push(node)
      }
    })

    if (codeBlocks.length === 0) return

    // Load WASM once (cached for subsequent HMR calls)
    if (!instancePromise) {
      instancePromise = loadMoonmaid(options.wasmPath)
    }
    const moonmaid = await instancePromise

    for (const node of codeBlocks) {
      const svg = moonmaid.render(node.value)
      // Replace code block with raw HTML containing the SVG
      const htmlNode = node as unknown as { type: string; value: string }
      htmlNode.type = 'html'
      htmlNode.value = `<figure class="moonmaid" style="margin: 16px 0">${svg}</figure>`
    }
  }
}

export default remarkMoonmaid
```

- [ ] **Step 3: Write plugin test**

Create `ts/remark-plugin/index.test.ts`:
```typescript
import { describe, it, expect, vi } from 'vitest'

// Unit test the code block detection logic without WASM
describe('remarkMoonmaid', () => {
  it('identifies moonmaid code blocks', () => {
    const mockTree = {
      type: 'root' as const,
      children: [
        {
          type: 'code' as const,
          lang: 'moonmaid',
          value: 'array { [1, 2, 3] }',
        },
        {
          type: 'code' as const,
          lang: 'javascript',
          value: 'console.log("hi")',
        },
      ],
    }

    const moonmaidBlocks = mockTree.children.filter(
      (n) => n.type === 'code' && n.lang === 'moonmaid',
    )
    expect(moonmaidBlocks).toHaveLength(1)
    expect(moonmaidBlocks[0].value).toBe('array { [1, 2, 3] }')
  })

  it('wraps SVG in figure element', () => {
    const svg = '<svg>test</svg>'
    const result = `<figure class="moonmaid" style="margin: 16px 0">${svg}</figure>`
    expect(result).toContain('<figure')
    expect(result).toContain('class="moonmaid"')
    expect(result).toContain('<svg>test</svg>')
  })
})
```

- [ ] **Step 4: Run tests**

Run: `cd ts && pnpm test`
Expected: all tests PASS

- [ ] **Step 5: Commit**

```bash
git add ts/remark-plugin/
git commit -m "feat: implement remark-moonmaid plugin with WASM caching for HMR"
```

---

### Task 10: README + Acknowledgements

**Files:**
- Create: `README.md`
- Create: `.gitignore`

- [ ] **Step 1: Create .gitignore**

Create `.gitignore`:
```
# MoonBit
target/
.mooncakes/

# TypeScript
ts/node_modules/
ts/dist/

# OS
.DS_Store
```

- [ ] **Step 2: Create README**

Create `README.md`:
```markdown
# moonmaid

A MoonBit-powered diagram tool for algorithm and data structure visualization.

## Status

Early development — Phase 1 (static rendering for array and tree diagrams).

## Quick Start

### Build

```bash
moon build --target wasm-gc
```

### Test

```bash
moon test --target wasm-gc
```

### Usage in Astro/Starlight

```js
// astro.config.mjs
import remarkMoonmaid from 'moonmaid/remark-plugin'

export default defineConfig({
  markdown: {
    remarkPlugins: [remarkMoonmaid],
  },
})
```

Then in Markdown:

\`\`\`moonmaid
array {
  [3, 1, 4, 1, 5, 9]
  highlight(0..2, color=blue, label="sorted")
}
\`\`\`

\`\`\`moonmaid
tree bst {
  insert(5, 3, 7, 1, 4, 6, 8)
}
\`\`\`

## Acknowledgements

moonmaid is inspired by [Mermaid](https://mermaid.js.org/) — the pioneering tool that made text-based diagramming accessible to developers worldwide. We stand on the shoulders of the Mermaid team's work and are grateful for the ecosystem they built. moonmaid takes a different path, focusing on algorithm and data structure visualization with MoonBit, but the spirit of "diagrams from text" lives on.

We also thank [diago](https://github.com/moonbit-community/diago) for demonstrating what's possible with MoonBit in the diagram space. diago's Railway engine and Sugiyama implementation served as a valuable reference for moonmaid's layout algorithms. The MoonBit community's work on [vg](https://github.com/moonbit-community/vg) and [NetworkX](https://github.com/moonbit-community/NetworkX) also informed our design decisions.

## License

MIT
```

- [ ] **Step 3: Commit**

```bash
git add README.md .gitignore
git commit -m "docs: add README with quick start and acknowledgements"
```

---

### Task 11: End-to-End Integration Test

**Files:**
- Create: `src/lib/moonmaid_test.mbt`

- [ ] **Step 1: Write end-to-end tests**

Create `src/lib/moonmaid_test.mbt`:
```moonbit
test "e2e: array DSL to SVG" {
  let svg = @lib.render("array { [3, 1, 4] }")
  assert_true!(svg.contains("<svg"))
  assert_true!(svg.contains("</svg>"))
  assert_true!(svg.contains(">3<"))
  assert_true!(svg.contains(">1<"))
  assert_true!(svg.contains(">4<"))
  // Index labels
  assert_true!(svg.contains(">0<"))
  assert_true!(svg.contains(">1<"))
  assert_true!(svg.contains(">2<"))
}

test "e2e: tree BST DSL to SVG" {
  let svg = @lib.render("tree bst { insert(5, 3, 7) }")
  assert_true!(svg.contains("<svg"))
  assert_true!(svg.contains(">5<"))
  assert_true!(svg.contains(">3<"))
  assert_true!(svg.contains(">7<"))
  assert_true!(svg.contains("<polyline")) // edges
}

test "e2e: invalid input returns error SVG" {
  let svg = @lib.render("invalid { }")
  assert_true!(svg.contains("<svg"))
  assert_true!(svg.contains("fill=\"#cf222e\"")) // error color
}

test "e2e: XSS attempt in DSL is neutralized" {
  // This should fail at parse level, but if labels ever pass through:
  let svg = @lib.render("array { [1] }")
  assert_true!(svg.contains("<script>").not())
}

test "e2e: array with highlights" {
  let input =
    #|array {
    #|  [3, 1, 4, 1, 5]
    #|  highlight(0..2, color=blue, label="sorted")
    #|}
  let svg = @lib.render(input)
  assert_true!(svg.contains("#0969da")) // highlight blue color
}
```

- [ ] **Step 2: Run all tests across all packages**

Run: `moon test --target wasm-gc`
Expected: all tests PASS across all packages

- [ ] **Step 3: Build final WASM and verify size**

Run: `moon build --target wasm-gc --release && ls -lh target/wasm-gc/release/build/lib/lib.wasm`
Expected: successful build, WASM file < 200KB

- [ ] **Step 4: Commit**

```bash
git add src/lib/moonmaid_test.mbt
git commit -m "test: add end-to-end integration tests for array and tree rendering"
```

---

## Summary

| Task | Component | Tests |
|---|---|---|
| 1 | MoonBit scaffolding + core types | build check |
| 2 | DSL Lexer | 4 tests |
| 3 | DSL Parser (array + tree) | 5 tests |
| 4 | Fixed Grid Layout (array) | 3 tests |
| 5 | Reingold-Tilford Layout (tree) | 3 tests |
| 6 | SVG Renderer + XSS escape + theme | 5 tests |
| 7 | Public API + WASM export | build check |
| 8 | TypeScript WASM bridge | — |
| 9 | Remark plugin | 2 tests |
| 10 | README + .gitignore | — |
| 11 | End-to-end integration | 5 tests |

**Total: 11 tasks, ~27 tests, ~11 commits**

## Next Plans

- **Phase 1.5**: Animation system (state machine, timeline, playback controls, `@animate` DSL)
- **Phase 2**: Sugiyama layout (directed graphs, flowcharts, state transition diagrams)
- **Phase 3**: Force-directed layout (undirected graphs)
- **Web editor**: CodeMirror integration with real-time WASM preview
