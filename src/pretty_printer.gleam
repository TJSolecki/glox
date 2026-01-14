import gleam/bool
import gleam/float
import gleam/int
import token.{type Token}

pub type Expression {
  Grouping(expression: Expression)
  Unary(token: Token, expression: Expression)
  Binary(
    left_expression: Expression,
    operator: Token,
    right_expression: Expression,
  )
  LiteralString(value: String)
  LiteralNumber(value: Float)
  LiteralBool(value: Bool)
  LiteralNil
}

pub fn pretty_print(expression: Expression) -> String {
  case expression {
    Grouping(group_expression) ->
      "(group " <> pretty_print(group_expression) <> ")"
    Unary(token, unary_expression) ->
      "("
      <> token.lexeme(token.token_type)
      <> " "
      <> pretty_print(unary_expression)
      <> ")"
    Binary(left_expression, operator, right_expression) ->
      "("
      <> token.lexeme(operator.token_type)
      <> " "
      <> pretty_print(left_expression)
      <> " "
      <> pretty_print(right_expression)
      <> ")"
    LiteralString(value) -> value
    LiteralNumber(value) -> {
      case value == float.floor(value) {
        True -> float.truncate(value) |> int.to_string
        False -> float.to_string(value)
      }
    }
    LiteralBool(value) -> bool.to_string(value)
    LiteralNil -> "nil"
  }
}
