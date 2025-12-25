pub type TokenType {
  // Single-character tokens.
  LeftParen
  RightParen
  LeftBrace
  RightBrace
  Comma
  Dot
  Minus
  Plus
  Semicolon
  Slash
  Star

  // One or two character tokens.
  Bang
  BangEqual
  Equal
  EqualEqual
  Greater
  GreaterEqual
  Less
  LessEqual

  // Literals.
  Identifier(value: String)
  String(value: String)
  Number(value: String)

  // Keywords
  And
  Class
  Else
  BooleanFalse
  Fun
  For
  If
  Nil
  Or
  Print
  Return
  Super
  This
  BooleanTrue
  Var
  While

  Eof
}
