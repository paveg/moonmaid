///|
/// Token types for the moonmaid DSL lexer.
pub(all) enum Token {
  // Keywords
  TkArray
  TkTree
  TkBST
  TkInsert
  TkHighlight
  TkAnimate
  TkSort
  TkBubble
  TkInsertion
  TkSelection
  TkQuick
  // Literals
  IntLit(Int)
  StringLit(String)
  Ident(String)
  At // @
  // Symbols
  LBrace // {
  RBrace // }
  LBracket // [
  RBracket // ]
  LParen // (
  RParen // )
  Comma // ,
  DotDot // ..
  Eq // =
  Arrow // ->
  Colon // :
  // Special
  Eof
} derive(Show, Eq)

///|
/// Token with source position for error reporting.
pub(all) struct Located {
  token : Token
  line : Int
  col : Int
} derive(Show, Eq)
