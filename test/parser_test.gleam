import gleam/option.{Some}
import parser.{
  Block, ExpressionStatement, LiteralNumber, PrintStatement, Variable,
  VariableDeclaration,
}
import scanner
import span.{Span}
import token.{Identifier, Token}

pub fn parse_unexpected_expression_error_test() {
  let source = "1+;"
  let tokens = scanner.scan(source).0
  let assert #([], [parse_error]) = parser.parse(tokens)
  assert parse_error == parser.ExpectExpression(1, 3)
}

pub fn parse_unsupported_unary_operator_error_test() {
  let source = "+1;"
  let tokens = scanner.scan(source).0
  let assert #([], [parse_error]) = parser.parse(tokens)
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

pub fn can_parse_empty_block_test() {
  let source = "var a = 1; {}"
  let tokens = scanner.scan(source).0
  assert #(
      [
        parser.VariableDeclaration(
          Token(Identifier("a"), 1, 5),
          Some(LiteralNumber(1.0, Span(1, 9, 1, 9))),
        ),
        Block([]),
      ],
      [],
    )
    == parser.parse(tokens)
}

pub fn can_parse_block_with_print_test() {
  let source = "var a = 1; {print a;}"
  let tokens = scanner.scan(source).0
  assert #(
      [
        VariableDeclaration(
          Token(Identifier("a"), 1, 5),
          Some(LiteralNumber(1.0, Span(1, 9, 1, 9))),
        ),
        Block([
          PrintStatement(Variable(
            Token(Identifier("a"), 1, 19),
            Span(1, 19, 1, 19),
          )),
        ]),
      ],
      [],
    )
    == parser.parse(tokens)
}

pub fn can_parse_block_with_expression_statement_test() {
  let source = "var a = 1; {a;}"
  let tokens = scanner.scan(source).0
  assert #(
      [
        VariableDeclaration(
          Token(Identifier("a"), 1, 5),
          Some(LiteralNumber(1.0, Span(1, 9, 1, 9))),
        ),
        Block([
          ExpressionStatement(Variable(
            Token(Identifier("a"), 1, 13),
            Span(1, 13, 1, 13),
          )),
        ]),
      ],
      [],
    )
    == parser.parse(tokens)
}

pub fn can_parse_block_with_declaration_test() {
  let source = "{var a = 1;}"
  let tokens = scanner.scan(source).0
  assert #(
      [
        Block([
          VariableDeclaration(
            Token(Identifier("a"), 1, 6),
            Some(LiteralNumber(1.0, Span(1, 10, 1, 10))),
          ),
        ]),
      ],
      [],
    )
    == parser.parse(tokens)
}
