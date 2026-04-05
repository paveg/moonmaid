///|
/// Internal lexer state.
priv struct Lexer {
  input : String
  len : Int
  mut pos : Int
  mut line : Int
  mut col : Int
}

///|
fn Lexer::new(input : String) -> Lexer {
  { input, len: input.length(), pos: 0, line: 1, col: 1 }
}

///|
fn Lexer::current_char(self : Lexer) -> Char? {
  if self.pos < self.len {
    Some(Int::unsafe_to_char(self.input[self.pos].to_int()))
  } else {
    None
  }
}

///|
fn Lexer::advance(self : Lexer) -> Unit {
  if self.pos < self.len {
    let c = Int::unsafe_to_char(self.input[self.pos].to_int())
    self.pos = self.pos + 1
    if c == '\n' {
      self.line = self.line + 1
      self.col = 1
    } else {
      self.col = self.col + 1
    }
  }
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
fn is_alnum(c : Char) -> Bool {
  is_alpha(c) || is_digit(c)
}

///|
fn Lexer::lex_int(self : Lexer) -> Int {
  let mut n = 0
  while self.pos < self.len {
    let c = Int::unsafe_to_char(self.input[self.pos].to_int())
    if is_digit(c) {
      n = n * 10 + (c.to_int() - '0'.to_int())
      self.advance()
    } else {
      break
    }
  }
  n
}

///|
fn Lexer::lex_ident(self : Lexer) -> String {
  let buf = StringBuilder::new()
  while self.pos < self.len {
    let c = Int::unsafe_to_char(self.input[self.pos].to_int())
    if is_alnum(c) {
      buf.write_char(c)
      self.advance()
    } else {
      break
    }
  }
  buf.to_string()
}

///|
fn keyword_token(s : String) -> Token? {
  match s {
    "array" => Some(TkArray)
    "tree" => Some(TkTree)
    "bst" => Some(TkBST)
    "insert" => Some(TkInsert)
    "highlight" => Some(TkHighlight)
    _ => None
  }
}

///|
fn Lexer::lex_string(self : Lexer) -> String raise @types.MoonmaidError {
  self.advance() // consume opening quote
  let buf = StringBuilder::new()
  while true {
    match self.current_char() {
      None => raise @types.MoonmaidError::of("unterminated string literal")
      Some('"') => {
        self.advance()
        break
      }
      Some('\\') => {
        self.advance()
        match self.current_char() {
          None => raise @types.MoonmaidError::of("unterminated escape sequence")
          Some('n') => buf.write_char('\n')
          Some('t') => buf.write_char('\t')
          Some('r') => buf.write_char('\r')
          Some('\\') => buf.write_char('\\')
          Some('"') => buf.write_char('"')
          Some(c) => {
            buf.write_char('\\')
            buf.write_char(c)
          }
        }
        self.advance()
      }
      Some(c) => {
        buf.write_char(c)
        self.advance()
      }
    }
  }
  buf.to_string()
}

///|
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while self.pos < self.len {
    let c = Int::unsafe_to_char(self.input[self.pos].to_int())
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      self.advance()
    } else {
      break
    }
  }
}

///|
fn Lexer::next_token(self : Lexer) -> Located raise @types.MoonmaidError {
  self.skip_whitespace()
  let start_line = self.line
  let start_col = self.col
  let tok = match self.current_char() {
    None => Eof
    Some('{') => {
      self.advance()
      LBrace
    }
    Some('}') => {
      self.advance()
      RBrace
    }
    Some('[') => {
      self.advance()
      LBracket
    }
    Some(']') => {
      self.advance()
      RBracket
    }
    Some('(') => {
      self.advance()
      LParen
    }
    Some(')') => {
      self.advance()
      RParen
    }
    Some(',') => {
      self.advance()
      Comma
    }
    Some('=') => {
      self.advance()
      Eq
    }
    Some('.') => {
      self.advance()
      match self.current_char() {
        Some('.') => {
          self.advance()
          DotDot
        }
        _ => raise @types.MoonmaidError::of("expected '..' but got single '.'")
      }
    }
    Some('-') => {
      self.advance()
      match self.current_char() {
        Some('>') => {
          self.advance()
          Arrow
        }
        _ => raise @types.MoonmaidError::of("expected '->' but got single '-'")
      }
    }
    Some('"') => {
      let s = self.lex_string()
      StringLit(s)
    }
    Some(c) if is_digit(c) => IntLit(self.lex_int())
    Some(c) if is_alpha(c) => {
      let word = self.lex_ident()
      match keyword_token(word) {
        Some(kw) => kw
        None => Ident(word)
      }
    }
    Some(c) => raise @types.MoonmaidError::of("unexpected character: \{c}")
  }
  { token: tok, line: start_line, col: start_col }
}

///| Lex the entire input string into a sequence of located tokens.

///|
/// Raises MoonmaidError on invalid input.
pub fn lex(input : String) -> Array[Located] raise @types.MoonmaidError {
  let lexer = Lexer::new(input)
  let tokens : Array[Located] = []
  let mut running = true
  while running {
    let tok = lexer.next_token()
    tokens.push(tok)
    if tok.token == Eof {
      running = false
    }
  }
  tokens
}
