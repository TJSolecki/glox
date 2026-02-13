import parser
import scanner
import span

pub fn parse_unexpected_expression_error_test() {
  let source = "1+;"
  let tokens = scanner.scan(source).0
  let assert #([], [parse_error]) = parser.parse(tokens)
  assert parse_error == parser.ExpectExpression(1, 3)
}

pub fn parse_unsupported_unary_operator_error_test() {
  let source = "+1;"
  let tokens = scanner.scan(source).0
  let assert #([_], [parse_error]) = parser.parse(tokens)
  assert parse_error
    == parser.UnsupportedUnaryOperator(parser.Plus, span.point(1, 1))
}

pub fn parse_missing_right_paren_error_test() {
  let source = "(1 + 2 == 3 * 4;"
  let tokens = scanner.scan(source).0
  let assert #([], [parse_error]) = parser.parse(tokens)
  assert parse_error == parser.MissingRightParen(1, 1)
}

pub fn parse_missing_colon_expression_error_test() {
  let source = "1?2;"
  let tokens = scanner.scan(source).0
  let assert #([], [parse_error]) = parser.parse(tokens)
  assert parse_error == parser.MissingColon(1, 2)
}

pub fn parse_unexpected_eof_test() {
  let assert #([], [parse_error]) = parser.parse([])
  assert parse_error == parser.UnexpectedEof
}

pub fn parse_lox_number_can_parse_whole_number_test() {
  assert parser.parse_lox_number("10") == 10.0
}

pub fn parse_lox_number_can_parse_decimal_number_test() {
  assert parser.parse_lox_number("45.6") == 45.6
}
