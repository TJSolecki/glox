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
  QuestionMark
  Colon

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
  False
  Fun
  For
  If
  Nil
  Or
  Print
  Return
  Super
  This
  True
  Var
  While

  Eof
}

pub type Token {
  Token(token_type: TokenType, line: Int, column: Int)
}

pub fn lexeme(token_type: TokenType) -> String {
  case token_type {
    Eof -> ""
    LeftParen -> "("
    RightParen -> ")"
    LeftBrace -> "{"
    RightBrace -> "}"
    Comma -> ","
    Dot -> "."
    Semicolon -> ";"
    Plus -> "+"
    Minus -> "-"
    Star -> "*"
    QuestionMark -> "?"
    Colon -> ":"
    Slash -> "/"
    Bang -> "!"
    BangEqual -> "!="
    Equal -> "="
    EqualEqual -> "=="
    Greater -> ">"
    GreaterEqual -> ">="
    Less -> "<"
    LessEqual -> "<="
    And -> "and"
    Class -> "class"
    Else -> "else"
    False -> "false"
    Fun -> "fun"
    For -> "for"
    If -> "if"
    Nil -> "nil"
    Or -> "or"
    Print -> "print"
    Return -> "return"
    Super -> "super"
    This -> "this"
    True -> "true"
    Var -> "var"
    While -> "while"
    Identifier(value) -> value
    String(value) -> value
    Number(value) -> value
  }
}
