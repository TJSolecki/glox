import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import span.{type Span}
import token.{type Token, type TokenType}

/// A parser for the following lox grammer
///
/// program        → statement* EOF ;
///
/// statement      → exprStatement
///                | printStatement ;
///
/// exprStatement  → expression ";" ;
/// printStatement → "print" expression ";" ;
///
/// expression     → comma ;
/// comma          → ternary ( "," ternary )*
/// ternary        → equality
///                | ( equality "?" ternary ":" ternary ) ;
/// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
/// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
/// term           → factor ( ( "-" | "+" ) factor )* ;
/// factor         → unary ( ( "/" | "*" ) unary )* ;
/// unary          → ( "!" | "-" ) unary
///                | primary ;
/// primary        → NUMBER | STRING | "true" | "false" | "nil"
///                | "(" expression ")" ;
pub type Program =
  List(Statement)

pub type Statement {
  ExpressionStatement(expression: Expression)
  PrintStatement(expression: Expression)
}

pub type Expression {
  Grouping(expression: Expression, span: Span)
  Unary(token: Token, expression: Expression, span: Span)
  Binary(
    left_expression: Expression,
    operator: Token,
    right_expression: Expression,
    span: Span,
  )
  Ternary(
    clause: Expression,
    true_expresssion: Expression,
    false_expression: Expression,
    span: Span,
  )
  LiteralString(value: String, span: Span)
  LiteralNumber(value: Float, span: Span)
  LiteralBool(value: Bool, span: Span)
  LiteralNil(span: Span)
}

pub type ParseError {
  MissingRightParen(line: Int, column: Int)
  ExpectExpression(line: Int, column: Int)
  MissingColon(line: Int, column: Int)
  MissingSemicolon(span: Span)
  UnsupportedUnaryOperator(invalid_unary_token: InvalidUnaryToken, span: Span)
  UnexpectedEof
}

pub type InvalidUnaryToken {
  Plus
}

type ExpressionParser {
  ExpressionParser(
    tokens: List(Token),
    expression: Result(Expression, ParseError),
  )
}

type StatementParser {
  StatementParser(tokens: List(Token), statement: Result(Statement, ParseError))
}

pub fn parse(tokens: List(Token)) -> #(List(Statement), List(ParseError)) {
  tokens
  |> parser_loop([])
  |> result.partition
}

fn parser_loop(
  tokens: List(Token),
  statements: List(Result(Statement, ParseError)),
) -> List(Result(Statement, ParseError)) {
  let StatementParser(rest_tokens, statement) = statement(tokens)
  case rest_tokens {
    [token.Token(token_type: token_type, ..), ..] if token_type != token.Eof ->
      parser_loop(rest_tokens, list.prepend(statements, statement))
    _ -> list.prepend(statements, statement)
  }
}

fn statement(tokens: List(Token)) -> StatementParser {
  case tokens {
    [token.Token(token_type: token.Print, ..), ..rest] -> print_statement(rest)
    _ -> expression_statement(tokens)
  }
}

fn print_statement(tokens: List(Token)) -> StatementParser {
  statement_helper(tokens, PrintStatement)
}

fn expression_statement(tokens: List(Token)) -> StatementParser {
  statement_helper(tokens, ExpressionStatement)
}

fn statement_helper(
  tokens: List(Token),
  to_statement: fn(Expression) -> Statement,
) -> StatementParser {
  use #(rest, expression) <- unwrap_expression_to_statement(expression(tokens))
  // TODO: replace with some sport of consume method specific to StatementParser
  case rest {
    [token.Token(token_type: token.Semicolon, ..), ..rest] ->
      StatementParser(rest, Ok(to_statement(expression)))
    _ -> {
      let expression_span = get_span(expression)
      StatementParser(
        rest,
        Error(
          MissingSemicolon(span.point(
            expression_span.end_line,
            expression_span.end_column + 1,
          )),
        ),
      )
    }
  }
}

fn unwrap_expression_to_statement(
  parser: ExpressionParser,
  handle_ok: fn(#(List(Token), Expression)) -> StatementParser,
) -> StatementParser {
  case parser.expression {
    Ok(expression) -> handle_ok(#(parser.tokens, expression))
    Error(parser_error) -> StatementParser(parser.tokens, Error(parser_error))
  }
}

/// expression → comma ;
fn expression(tokens: List(Token)) -> ExpressionParser {
  comma(tokens)
}

/// comma → ternary ( ',' ternary )*
fn comma(tokens: List(Token)) -> ExpressionParser {
  ternary(tokens)
  |> match_zero_or_more(matching: [token.Comma], using: ternary)
}

/// ternary → equality
///         | ( equality '?' ternary ':' ternary ) ;
fn ternary(tokens: List(Token)) -> ExpressionParser {
  use #(rest, equality_expression) <- try_unwrap_parser(equality(tokens))
  let equality = ExpressionParser(rest, Ok(equality_expression))
  use #(token, rest) <- try_advance(equality)
  case token.token_type {
    token.QuestionMark -> {
      use #(rest, true_clause) <- try_unwrap_parser(
        ternary(rest)
        |> consume(token.Colon, MissingColon(token.line, token.column)),
      )
      use #(rest, false_clause) <- try_unwrap_parser(ternary(rest))
      ExpressionParser(
        rest,
        Ok(Ternary(
          equality_expression,
          true_clause,
          false_clause,
          span.add(get_span(equality_expression), get_span(false_clause)),
        )),
      )
    }
    _ -> equality
  }
}

/// equality → comparison ( ( "!=" | "==" ) comparison )* ;
fn equality(tokens: List(Token)) -> ExpressionParser {
  comparison(tokens)
  |> match_zero_or_more(
    matching: [token.BangEqual, token.EqualEqual],
    using: comparison,
  )
}

/// comparison → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
fn comparison(tokens: List(Token)) -> ExpressionParser {
  term(tokens)
  |> match_zero_or_more(
    matching: [token.Greater, token.GreaterEqual, token.Less, token.LessEqual],
    using: term,
  )
}

/// term → factor ( ( "-" | "+" ) factor )* ;
fn term(tokens: List(Token)) -> ExpressionParser {
  factor(tokens)
  |> match_zero_or_more(matching: [token.Minus, token.Plus], using: factor)
}

/// factor → unary ( ( "/" | "*" ) unary )* ;
fn factor(tokens: List(Token)) -> ExpressionParser {
  unary(tokens)
  |> match_zero_or_more(matching: [token.Slash, token.Star], using: unary)
}

/// unary → ( "!" | "-" ) unary
///       | primary
fn unary(tokens: List(Token)) -> ExpressionParser {
  case tokens {
    [unary_operator, ..rest]
      if unary_operator.token_type == token.Bang
      || unary_operator.token_type == token.Minus
    -> {
      use #(rest, expression) <- try_unwrap_parser(unary(rest))
      ExpressionParser(
        rest,
        Ok(Unary(
          unary_operator,
          expression,
          span.add(span.from_token(unary_operator), get_span(expression)),
        )),
      )
    }
    [invalid_unary_operator, ..rest]
      if invalid_unary_operator.token_type == token.Plus
    -> {
      ExpressionParser(
        rest,
        Error(UnsupportedUnaryOperator(
          Plus,
          span.point(invalid_unary_operator.line, invalid_unary_operator.column),
        )),
      )
    }
    _ -> primary(tokens)
  }
}

/// primary → NUMBER | STRING | "true" | "false" | "nil"
///         | "(" expression ")" ;
fn primary(tokens: List(Token)) -> ExpressionParser {
  case tokens {
    [token, ..rest] ->
      case token.token_type {
        token.False ->
          ExpressionParser(rest, Ok(LiteralBool(False, span.from_token(token))))
        token.True ->
          ExpressionParser(rest, Ok(LiteralBool(True, span.from_token(token))))
        token.Nil ->
          ExpressionParser(rest, Ok(LiteralNil(span.from_token(token))))
        token.String(value) ->
          ExpressionParser(
            rest,
            Ok(LiteralString(value, span.from_token(token))),
          )
        token.Number(value) ->
          ExpressionParser(
            rest,
            Ok(LiteralNumber(parse_lox_number(value), span.from_token(token))),
          )
        token.LeftParen -> {
          let parser =
            expression(rest)
            |> consume(
              token.RightParen,
              MissingRightParen(token.line, token.column),
            )
          let right_paren =
            list.first(rest) |> result.lazy_unwrap(fn() { panic })
          use #(rest, expression) <- try_unwrap_parser(parser)
          ExpressionParser(
            rest,
            Ok(Grouping(
              expression,
              span.add(
                span.point(token.line, token.column),
                span.point(right_paren.line, right_paren.column),
              ),
            )),
          )
        }
        _ ->
          ExpressionParser(
            rest,
            Error(ExpectExpression(token.line, token.column)),
          )
      }
    [] -> ExpressionParser([], Error(UnexpectedEof))
  }
}

fn consume(
  parser: ExpressionParser,
  token_type: TokenType,
  parse_error: ParseError,
) -> ExpressionParser {
  case parser.tokens {
    [token, ..rest] if token.token_type == token_type ->
      ExpressionParser(rest, parser.expression)
    [_, ..rest] -> ExpressionParser(rest, Error(parse_error))
    [] -> ExpressionParser([], Error(parse_error))
  }
}

fn match_zero_or_more(
  with start: ExpressionParser,
  matching token_types: List(TokenType),
  using parse_rule: fn(List(Token)) -> ExpressionParser,
) -> ExpressionParser {
  use #(_, left_expression) <- try_unwrap_parser(start)
  use #(token, rest) <- try_advance(start)
  case list.contains(token_types, token.token_type) {
    False -> start
    True -> {
      let ExpressionParser(rest, right_expression) = parse_rule(rest)
      ExpressionParser(
        rest,
        result.map(right_expression, fn(expression) {
          Binary(
            left_expression,
            operator: token,
            right_expression: expression,
            span: span.add(get_span(left_expression), get_span(expression)),
          )
        }),
      )
      |> match_zero_or_more(matching: token_types, using: parse_rule)
    }
  }
}

fn get_span(expression: Expression) -> Span {
  case expression {
    Grouping(span: span, ..) -> span
    Ternary(span: span, ..) -> span
    Binary(span: span, ..) -> span
    Unary(span: span, ..) -> span
    LiteralNumber(span: span, ..) -> span
    LiteralString(span: span, ..) -> span
    LiteralBool(span: span, ..) -> span
    LiteralNil(span: span) -> span
  }
}

fn try_unwrap_parser(
  parser: ExpressionParser,
  handle_ok: fn(#(List(Token), Expression)) -> ExpressionParser,
) -> ExpressionParser {
  case parser {
    ExpressionParser(expression: Error(_), ..) -> parser
    ExpressionParser(tokens, Ok(expression)) -> handle_ok(#(tokens, expression))
  }
}

fn try_advance(
  parser: ExpressionParser,
  next: fn(#(Token, List(Token))) -> ExpressionParser,
) -> ExpressionParser {
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
    Grouping(group_expression, ..) ->
      "(group " <> pretty_print(group_expression) <> ")"
    Unary(token, unary_expression, ..) ->
      "("
      <> token.lexeme(token.token_type)
      <> " "
      <> pretty_print(unary_expression)
      <> ")"
    Binary(left_expression, operator, right_expression, ..) ->
      "("
      <> token.lexeme(operator.token_type)
      <> " "
      <> pretty_print(left_expression)
      <> " "
      <> pretty_print(right_expression)
      <> ")"
    Ternary(clause, true_expression, false_expression, ..) ->
      "("
      <> pretty_print(clause)
      <> " ? "
      <> pretty_print(true_expression)
      <> " : "
      <> pretty_print(false_expression)
      <> ")"
    LiteralString(value, ..) -> value
    LiteralNumber(value, ..) -> {
      case value == float.floor(value) {
        True -> float.truncate(value) |> int.to_string
        False -> float.to_string(value)
      }
    }
    LiteralBool(value, ..) -> bool.to_string(value)
    LiteralNil(..) -> "nil"
  }
}
