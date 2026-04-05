test "lex array diagram" {
  let input = "array { [3, 1, 4] }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkArray, @parser.Token::LBrace,
    @parser.Token::LBracket, @parser.Token::IntLit(3), @parser.Token::Comma,
    @parser.Token::IntLit(1), @parser.Token::Comma, @parser.Token::IntLit(4), @parser.Token::RBracket,
    @parser.Token::RBrace, @parser.Token::Eof,
  ])
}

test "lex tree bst diagram" {
  let input = "tree bst { insert(5, 3, 7) }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkTree, @parser.Token::TkBST, @parser.Token::LBrace,
    @parser.Token::TkInsert, @parser.Token::LParen, @parser.Token::IntLit(5), @parser.Token::Comma,
    @parser.Token::IntLit(3), @parser.Token::Comma, @parser.Token::IntLit(7), @parser.Token::RParen,
    @parser.Token::RBrace, @parser.Token::Eof,
  ])
}

test "lex highlight with string and range" {
  let input = "highlight(0..2, color=blue, label=\"sorted\")"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkHighlight, @parser.Token::LParen,
    @parser.Token::IntLit(0), @parser.Token::DotDot, @parser.Token::IntLit(2), @parser.Token::Comma,
    @parser.Token::Ident("color"), @parser.Token::Eq, @parser.Token::Ident("blue"), @parser.Token::Comma,
    @parser.Token::Ident("label"), @parser.Token::Eq, @parser.Token::StringLit("sorted"),
    @parser.Token::RParen, @parser.Token::Eof,
  ])
}

test "lex error on invalid character" {
  let result : Result[Array[@parser.Located], Unit] = try {
    Ok(@parser.lex("array { $ }"))
  } catch {
    _ => Err(())
  }
  assert_eq(result, Err(()))
}
