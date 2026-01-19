import parser
import scanner
import token

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
