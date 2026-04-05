///|
test "lex array diagram" {
  let input = "array { [3, 1, 4] }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkArray,
    @parser.Token::LBrace,
    @parser.Token::LBracket,
    @parser.Token::IntLit(3),
    @parser.Token::Comma,
    @parser.Token::IntLit(1),
    @parser.Token::Comma,
    @parser.Token::IntLit(4),
    @parser.Token::RBracket,
    @parser.Token::RBrace,
    @parser.Token::Eof,
  ])
}

///|
test "lex tree bst diagram" {
  let input = "tree bst { insert(5, 3, 7) }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkTree,
    @parser.Token::TkBST,
    @parser.Token::LBrace,
    @parser.Token::TkInsert,
    @parser.Token::LParen,
    @parser.Token::IntLit(5),
    @parser.Token::Comma,
    @parser.Token::IntLit(3),
    @parser.Token::Comma,
    @parser.Token::IntLit(7),
    @parser.Token::RParen,
    @parser.Token::RBrace,
    @parser.Token::Eof,
  ])
}

///|
test "lex highlight with string and range" {
  let input = "highlight(0..2, color=blue, label=\"sorted\")"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkHighlight,
    @parser.Token::LParen,
    @parser.Token::IntLit(0),
    @parser.Token::DotDot,
    @parser.Token::IntLit(2),
    @parser.Token::Comma,
    @parser.Token::Ident("color"),
    @parser.Token::Eq,
    @parser.Token::Ident("blue"),
    @parser.Token::Comma,
    @parser.Token::Ident("label"),
    @parser.Token::Eq,
    @parser.Token::StringLit("sorted"),
    @parser.Token::RParen,
    @parser.Token::Eof,
  ])
}

///|
test "lex error on invalid character" {
  let result : Result[Array[@parser.Located], Unit] = Ok(
    @parser.lex("array { $ }"),
  ) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "lex empty input" {
  let tokens = @parser.lex("")
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [@parser.Token::Eof])
}

///|
test "lex whitespace only" {
  let tokens = @parser.lex("  \n\t  ")
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [@parser.Token::Eof])
}

///|
test "lex string escape sequences" {
  let tokens = @parser.lex("\"hello\\nworld\"")
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::StringLit("hello\nworld"),
    @parser.Token::Eof,
  ])
}

///|
test "lex unterminated string raises error" {
  let result : Result[Array[@parser.Located], Unit] = Ok(@parser.lex("\"hello")) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "lex single dot raises error" {
  let result : Result[Array[@parser.Located], Unit] = Ok(@parser.lex(".")) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "lex arrow incomplete raises error" {
  let result : Result[Array[@parser.Located], Unit] = Ok(@parser.lex("-")) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "lex integer zero" {
  let tokens = @parser.lex("0")
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [@parser.Token::IntLit(0), @parser.Token::Eof])
}

///|
test "lex adjacent tokens without whitespace" {
  let tokens = @parser.lex("(3)")
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::LParen,
    @parser.Token::IntLit(3),
    @parser.Token::RParen,
    @parser.Token::Eof,
  ])
}

///|
test "lex tree bst @animate diagram" {
  let input = "tree bst @animate { insert(5) }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkTree,
    @parser.Token::TkBST,
    @parser.Token::At,
    @parser.Token::TkAnimate,
    @parser.Token::LBrace,
    @parser.Token::TkInsert,
    @parser.Token::LParen,
    @parser.Token::IntLit(5),
    @parser.Token::RParen,
    @parser.Token::RBrace,
    @parser.Token::Eof,
  ])
}

///|
test "lex @ alone produces At and Eof" {
  let tokens = @parser.lex("@")
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [@parser.Token::At, @parser.Token::Eof])
}

///|
/// Boundary: max valid integer (999999) is accepted.
test "lex integer at max boundary 999999" {
  let tokens = @parser.lex("999999")
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [@parser.Token::IntLit(999999), @parser.Token::Eof])
}

///|
/// Boundary: integer just over max (1000000) raises error.
test "lex integer over max boundary 1000000 raises error" {
  let result : Result[Array[@parser.Located], Unit] = Ok(@parser.lex("1000000")) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}

///|
test "lex array @animate with sort bubble" {
  let input = "array @animate { [3, 1] sort: bubble }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkArray,
    @parser.Token::At,
    @parser.Token::TkAnimate,
    @parser.Token::LBrace,
    @parser.Token::LBracket,
    @parser.Token::IntLit(3),
    @parser.Token::Comma,
    @parser.Token::IntLit(1),
    @parser.Token::RBracket,
    @parser.Token::TkSort,
    @parser.Token::Colon,
    @parser.Token::TkBubble,
    @parser.Token::RBrace,
    @parser.Token::Eof,
  ])
}

///|
test "lex all sort algorithm keywords" {
  let bubble = @parser.lex("bubble")
  assert_eq(bubble[0].token, @parser.Token::TkBubble)
  let insertion = @parser.lex("insertion")
  assert_eq(insertion[0].token, @parser.Token::TkInsertion)
  let selection = @parser.lex("selection")
  assert_eq(selection[0].token, @parser.Token::TkSelection)
  let quick = @parser.lex("quick")
  assert_eq(quick[0].token, @parser.Token::TkQuick)
  let sort = @parser.lex("sort")
  assert_eq(sort[0].token, @parser.Token::TkSort)
}

///|
/// Boundary: very large integer raises error.
test "lex very large integer raises error" {
  let result : Result[Array[@parser.Located], Unit] = Ok(
    @parser.lex("99999999999999"),
  ) catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}
