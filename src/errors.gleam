import gleam/int
import gleam/list
import gleam/result
import gleam/string
import interperater.{type Literal, type RuntimeError}
import invalid_token.{type InvalidToken}
import parser.{type InvalidUnaryToken, type ParseError}
import scanner.{type ScanError}
import span.{type Span}
import token.{type Token}

pub type GloxError {
  UnterminatedString(line: Int, column: Int)
  UnexpectedGrapheme(grapheme: String, line: Int, column: Int)
  MissingRightParen(line: Int, column: Int)
  ExpectExpression(line: Int, column: Int)
  MissingColon(line: Int, column: Int)
  UnexpectedEof(line: Int, column: Int)
  UnsupportedUnaryOperator(invalid_unary_token: InvalidUnaryToken, span: Span)
  UnsupportedNegation(minus: Token, literal: Literal)
  UnsupportedOperation(left: Literal, operator: Token, right: Literal)
  InvalidSyntax(invalid_token: InvalidToken, span: Span)
}

pub fn from_scan_error(scan_error: ScanError) -> GloxError {
  case scan_error {
    scanner.UnterminatedString(line, column) -> UnterminatedString(line, column)
    scanner.UnexpectedGrapheme(grapheme, line, column) ->
      UnexpectedGrapheme(grapheme, line, column)
    scanner.InvalidSyntax(invalid_token, span) ->
      InvalidSyntax(invalid_token, span)
  }
}

pub fn from_parse_error(parse_error: ParseError, source: String) -> GloxError {
  case parse_error {
    parser.MissingRightParen(line, column) -> MissingRightParen(line, column)
    parser.ExpectExpression(line, column) -> ExpectExpression(line, column)
    parser.MissingColon(line, column) -> MissingColon(line, column)
    parser.UnsupportedUnaryOperator(invalid_unary_token, span) ->
      UnsupportedUnaryOperator(invalid_unary_token, span)
    parser.UnexpectedEof -> {
      let lines = string.split(source, on: "\n")
      let final_line = list.last(lines)
      UnexpectedEof(
        line: int.max(list.length(lines), 1),
        column: result.map(final_line, string.length)
          |> result.unwrap(1)
          |> int.max(1),
      )
    }
  }
}

pub fn from_runtime_error(runtime_error: RuntimeError) -> GloxError {
  case runtime_error {
    interperater.UnsupportedNegation(minus, literal) ->
      UnsupportedNegation(minus, literal)
    interperater.UnsupportedOperation(left, operator, right) ->
      UnsupportedOperation(left, operator, right)
  }
}

pub fn error_message(error: GloxError, source: String) {
  let lines = string.split(source, on: "\n")
  let span = get_span(error)
  let assert Ok(code_line) = list.take(lines, span.start_line) |> list.last

  let line = span.start_line |> int.to_string
  let column = span.start_column |> int.to_string
  let additional_padding_left = string.length(line) - 1
  let description = error_description(error)
  let pointer =
    string.repeat(" ", times: additional_padding_left + span.start_column - 1)
    <> string.repeat("^", times: span.end_column - span.start_column + 1)
  let message =
    format_error_message(
      title: error_title(error),
      line: line,
      column: column,
      code_line: code_line,
      pointer: pointer,
      description: description,
    )
  message
}

fn error_title(scan_error: GloxError) -> String {
  case scan_error {
    UnexpectedGrapheme(..) -> "Unexpected character"
    UnterminatedString(..) -> "Unterminated string"
    ExpectExpression(..) -> "Missing expression"
    MissingRightParen(..) -> "Missing ')'"
    MissingColon(..) -> "Expected ':' before ';'"
    UnexpectedEof(..) -> "Unexpected end of file"
    UnsupportedUnaryOperator(..) -> "Missing left operand for `+`"
    UnsupportedOperation(left, operator, right) ->
      "Unsupported operation `"
      <> literal_type_name(left)
      <> "` "
      <> token.lexeme(operator.token_type)
      <> " `"
      <> literal_type_name(right)
      <> "`"
    UnsupportedNegation(_, literal) ->
      "Illegal `" <> literal_type_name(literal) <> "` negation"
    InvalidSyntax(invalid_token: invalid_token.AndAnd, ..) ->
      "Wrong logical 'and'"
    InvalidSyntax(invalid_token: invalid_token.OrOr, ..) -> "Wrong logical 'or'"
    InvalidSyntax(invalid_token: invalid_token.BitwiseOr, ..) ->
      "Unsupported operation '|'"
    InvalidSyntax(invalid_token: invalid_token.BitwiseAnd, ..) ->
      "Unsupported operation '&'"
  }
}

fn literal_type_name(literal: Literal) -> String {
  case literal {
    interperater.LiteralString(..) -> "string"
    interperater.LiteralNumber(..) -> "number"
    interperater.LiteralBool(..) -> "bool"
    interperater.LiteralNil -> "nil"
  }
}

fn error_description(error: GloxError) -> String {
  case error {
    UnexpectedGrapheme(grapheme, ..) ->
      "We weren't expecting a \"" <> grapheme <> "\" here."
    UnterminatedString(..) -> "This string was never closed."
    ExpectExpression(..) -> "We were expecting an expression here."
    MissingRightParen(..) -> "This parentheses was never closed."
    MissingColon(..) -> "This ternary has no ':'."
    UnexpectedEof(..) -> "We didn't expect to end here."
    UnsupportedUnaryOperator(..) ->
      "Lox does not support the unary `+` operation."
    UnsupportedOperation(left, operator, right) ->
      "Lox does not support the `"
      <> token.lexeme(operator.token_type)
      <> "` operation between `"
      <> literal_type_name(left)
      <> "`s and `"
      <> literal_type_name(right)
      <> "`s."
    UnsupportedNegation(_, literal) ->
      "We cannot negate `" <> literal_type_name(literal) <> "`s within Lox."
    InvalidSyntax(invalid_token: invalid_token.AndAnd, ..) ->
      "Lox uses the keyword 'and', not '&&'."
    InvalidSyntax(invalid_token: invalid_token.OrOr, ..) ->
      "Lox uses the keyword 'or', not '||'"
    InvalidSyntax(invalid_token: invalid_token.BitwiseOr, ..) ->
      "Lox does not support the bitwise or operation."
    InvalidSyntax(invalid_token: invalid_token.BitwiseAnd, ..) ->
      "Lox does not support the bitwise and operation."
  }
}

fn get_span(error: GloxError) -> Span {
  case error {
    UnexpectedGrapheme(line: line, column: column, ..) ->
      span.point(line, column)
    UnterminatedString(line: line, column: column) -> span.point(line, column)
    ExpectExpression(line: line, column: column) -> span.point(line, column)
    MissingRightParen(line: line, column: column) -> span.point(line, column)
    MissingColon(line: line, column: column) -> span.point(line, column)
    UnexpectedEof(line: line, column: column) -> span.point(line, column)
    UnsupportedUnaryOperator(span: span, ..) -> span
    UnsupportedOperation(_, operator, ..) -> span.from_token(operator)
    UnsupportedNegation(minus, ..) -> span.from_token(minus)
    InvalidSyntax(span: span, ..) -> span
  }
}

fn format_error_message(
  title error_title: String,
  line line_str: String,
  column column_str: String,
  code_line code: String,
  pointer point: String,
  description desc: String,
) -> String {
  "error: " <> error_title <> "
┌─ " <> line_str <> ":" <> column_str <> "
|
" <> line_str <> " | " <> code <> "
|   " <> point <> "

" <> desc
}
