import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import token.{type Token, type TokenType}

/// A parser for the following lox grammer
///
/// expression     → equality ;
/// ternary        → equality
///                | ( equality '?' ternary ':' ternary ) ;
/// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
/// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
/// term           → factor ( ( "-" | "+" ) factor )* ;
/// factor         → unary ( ( "/" | "*" ) unary )* ;
/// unary          → ( "!" | "-" ) unary
///                | primary ;
/// primary        → NUMBER | STRING | "true" | "false" | "nil"
///                | "(" expression ")" ;
pub type Expression {
  Grouping(expression: Expression)
  Unary(token: Token, expression: Expression)
  Binary(
    left_expression: Expression,
    operator: Token,
    right_expression: Expression,
  )
  Ternary(
    clause: Expression,
    true_expresssion: Expression,
    false_expression: Expression,
  )
  LiteralString(value: String)
  LiteralNumber(value: Float)
  LiteralBool(value: Bool)
  LiteralNil
}

pub type ParseError {
  MissingRightParen(line: Int, column: Int)
  ExpectExpression(line: Int, column: Int)
  MissingColon(line: Int, column: Int)
}

type Parser {
  Parser(tokens: List(Token), expression: Result(Expression, ParseError))
}

pub fn parse(tokens: List(Token)) -> Result(Expression, ParseError) {
  expression(tokens).expression
}

/// expression → equality ;
fn expression(tokens: List(Token)) -> Parser {
  ternary(tokens)
}

/// ternary → equality
///         | ( equality '?' ternary ':' ternary ) ;
fn ternary(tokens: List(Token)) -> Parser {
  use #(rest, equality_expression) <- try_unwrap_parser(equality(tokens))
  let equality = Parser(rest, Ok(equality_expression))
  use #(token, rest) <- try_advance(equality)
  case token.token_type {
    token.QuestionMark -> {
      use #(rest, true_clause) <- try_unwrap_parser(
        ternary(rest)
        |> consume(token.Colon, MissingColon(token.line, token.column)),
      )
      use #(rest, false_clause) <- try_unwrap_parser(ternary(rest))
      Parser(rest, Ok(Ternary(equality_expression, true_clause, false_clause)))
    }
    _ -> equality
  }
}

/// equality → comparison ( ( "!=" | "==" ) comparison )* ;
fn equality(tokens: List(Token)) -> Parser {
  comparison(tokens)
  |> match_zero_or_more(
    matching: [token.BangEqual, token.EqualEqual],
    using: comparison,
  )
}

/// comparison → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
fn comparison(tokens: List(Token)) -> Parser {
  term(tokens)
  |> match_zero_or_more(
    matching: [token.Greater, token.GreaterEqual, token.Less, token.LessEqual],
    using: term,
  )
}

/// term → factor ( ( "-" | "+" ) factor )* ;
fn term(tokens: List(Token)) -> Parser {
  factor(tokens)
  |> match_zero_or_more(matching: [token.Minus, token.Plus], using: factor)
}

/// factor → unary ( ( "/" | "*" ) unary )* ;
fn factor(tokens: List(Token)) -> Parser {
  unary(tokens)
  |> match_zero_or_more(matching: [token.Slash, token.Star], using: unary)
}

/// unary → ( "!" | "-" ) unary
///       | primary
fn unary(tokens: List(Token)) -> Parser {
  case tokens {
    [current, ..rest]
      if current.token_type == token.Bang || current.token_type == token.Minus
    -> {
      use #(rest, expression) <- try_unwrap_parser(unary(rest))
      Parser(rest, Ok(Unary(current, expression)))
    }
    _ -> primary(tokens)
  }
}

/// primary → NUMBER | STRING | "true" | "false" | "nil"
///         | "(" expression ")" ;
fn primary(tokens: List(Token)) -> Parser {
  case tokens {
    [token, ..rest] ->
      case token.token_type {
        token.False -> Parser(rest, Ok(LiteralBool(False)))
        token.True -> Parser(rest, Ok(LiteralBool(True)))
        token.Nil -> Parser(rest, Ok(LiteralNil))
        token.String(value) -> Parser(rest, Ok(LiteralString(value)))
        token.Number(value) ->
          Parser(rest, Ok(LiteralNumber(parse_lox_number(value))))
        token.LeftParen -> {
          let parser =
            expression(rest)
            |> consume(
              token.RightParen,
              MissingRightParen(token.line, token.column),
            )
          use #(rest, expression) <- try_unwrap_parser(parser)
          Parser(rest, Ok(Grouping(expression)))
        }
        _ -> Parser(rest, Error(ExpectExpression(token.line, token.column)))
      }
    _ -> panic
  }
}

fn consume(
  parser: Parser,
  token_type: TokenType,
  parse_error: ParseError,
) -> Parser {
  case parser.tokens {
    [token, ..rest] if token.token_type == token_type ->
      Parser(rest, parser.expression)
    [_, ..rest] -> Parser(rest, Error(parse_error))
    _ -> Parser(parser.tokens, Error(parse_error))
  }
}

fn match_zero_or_more(
  with start: Parser,
  matching token_types: List(TokenType),
  using parse_rule: fn(List(Token)) -> Parser,
) -> Parser {
  use #(_, left_expression) <- try_unwrap_parser(start)
  use #(token, rest) <- try_advance(start)
  case list.contains(token_types, token.token_type) {
    False -> start
    True -> {
      let Parser(rest, right_expression) = parse_rule(rest)
      Parser(
        rest,
        result.map(right_expression, Binary(
          left_expression,
          operator: token,
          right_expression: _,
        )),
      )
      |> match_zero_or_more(matching: token_types, using: parse_rule)
    }
  }
}

fn try_unwrap_parser(
  parser: Parser,
  handle_ok: fn(#(List(Token), Expression)) -> Parser,
) -> Parser {
  case parser {
    Parser(expression: Error(_), ..) -> parser
    Parser(tokens, Ok(expression)) -> handle_ok(#(tokens, expression))
  }
}

fn try_advance(
  parser: Parser,
  next: fn(#(Token, List(Token))) -> Parser,
) -> Parser {
  case parser.tokens {
    [] -> parser
    [token, ..rest] -> next(#(token, rest))
  }
}

/// Converts strings of whole or deciamal numbers to a Float
pub fn parse_lox_number(value: String) -> Float {
  case int.parse(value) {
    Ok(number) -> int.to_float(number)
    Error(_) -> float.parse(value) |> result.lazy_unwrap(fn() { panic })
  }
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
    Ternary(clause, true_expression, false_expression) ->
      "("
      <> pretty_print(clause)
      <> " ? "
      <> pretty_print(true_expression)
      <> " : "
      <> pretty_print(false_expression)
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
