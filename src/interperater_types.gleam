import token.{type Token}

pub type Literal {
  LiteralBool(value: Bool)
  LiteralNumber(value: Float)
  LiteralString(value: String)
  LiteralNil
}

pub type RuntimeError {
  UnsupportedNegation(minus: Token, literal: Literal)
  UnsupportedOperation(left: Literal, operator: Token, right: Literal)
  UndefinedVariable(name: Token)
}
