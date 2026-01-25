import parser
import scanner
import token

pub fn parse_unexpected_expression_error_test() {
  let source = "1+"
  let tokens = scanner.scan(source).0
  let assert Error(parse_error) = parser.parse(tokens)
  assert parse_error == parser.ExpectExpression(1, 3)
}

pub fn parse_missing_right_paren_error_test() {
  let source = "(1 + 2 == 3 * 4"
  let tokens = scanner.scan(source).0
  let assert Error(parse_error) = parser.parse(tokens)
  assert parse_error == parser.MissingRightParen(1, 1)
}

pub fn parse_missing_colon_expression_error_test() {
  let source = "1?2"
  let tokens = scanner.scan(source).0
  let assert Error(parse_error) = parser.parse(tokens)
  assert parse_error == parser.MissingColon(1, 2)
}

pub fn parse_unexpected_eof_test() {
  let assert Error(parse_error) = parser.parse([])
  assert parse_error == parser.UnexpectedEof
}

pub fn parse_comma_test() {
  let source = "1,2,3,4"
  let tokens = scanner.scan(source).0
  let assert Ok(actual_ast) = parser.parse(tokens)
  let expected_ast =
    parser.Binary(
      parser.Binary(
        parser.Binary(
          parser.LiteralNumber(1.0),
          token.Token(token.Comma, 1, 2),
          parser.LiteralNumber(2.0),
        ),
        token.Token(token.Comma, 1, 4),
        parser.LiteralNumber(3.0),
      ),
      token.Token(token.Comma, 1, 6),
      parser.LiteralNumber(4.0),
    )

  assert actual_ast == expected_ast
}

pub fn parse_ternary_test() {
  let source = "1?2?3:4:5?6:7"
  let tokens = scanner.scan(source).0
  let assert Ok(actual_ast) = parser.parse(tokens)
  let expected_ast =
    parser.Ternary(
      parser.LiteralNumber(1.0),
      parser.Ternary(
        parser.LiteralNumber(2.0),
        parser.LiteralNumber(3.0),
        parser.LiteralNumber(4.0),
      ),
      parser.Ternary(
        parser.LiteralNumber(5.0),
        parser.LiteralNumber(6.0),
        parser.LiteralNumber(7.0),
      ),
    )

  assert actual_ast == expected_ast
}

pub fn parse_unary_multiplication_group_test() {
  let source = "-123 * (45.67)"
  let tokens = scanner.scan(source).0
  let assert Ok(actual_ast) = parser.parse(tokens)
  let expected_ast =
    parser.Binary(
      parser.Unary(token.Token(token.Minus, 1, 1), parser.LiteralNumber(123.0)),
      token.Token(token.Star, 1, 6),
      parser.Grouping(parser.LiteralNumber(45.67)),
    )

  assert actual_ast == expected_ast
}

pub fn parse_comparision_test() {
  let source = "1 <= 1.1 == true != nil"
  let tokens = scanner.scan(source).0
  let assert Ok(actual_ast) = parser.parse(tokens)
  let expected_ast =
    parser.Binary(
      parser.Binary(
        parser.Binary(
          parser.LiteralNumber(1.0),
          token.Token(token.LessEqual, 1, 3),
          parser.LiteralNumber(1.1),
        ),
        token.Token(token.EqualEqual, 1, 10),
        parser.LiteralBool(True),
      ),
      token.Token(token.BangEqual, 1, 18),
      parser.LiteralNil,
    )

  assert actual_ast == expected_ast
}

pub fn parse_lox_number_can_parse_whole_number_test() {
  assert parser.parse_lox_number("10") == 10.0
}

pub fn parse_lox_number_can_parse_decimal_number_test() {
  assert parser.parse_lox_number("45.6") == 45.6
}
