import parser
import pretty_printer
import scanner
import span
import test_utils

pub fn can_roundtrip_ast_with_pretty_printer_test() {
  let test_cases = [
    #("nil;\n", "literal nil"),
    #("true;\n", "literal true"),
    #("false;\n", "literal false"),
    #("\"foo\";\n", "literal string"),
    #("1;\n", "literal whole number"),
    #("1.01;\n", "literal decimal number"),
    #("bar;\n", "variable"),
    #("condition ? true : false;\n", "ternary"),
    #("a and b;\n", "logical and"),
    #("a or b;\n", "logical or"),
    #("!true;\n", "unary not"),
    #("1 + 2;\n", "binary addition"),
    #("1 - 2;\n", "binary subtraction"),
    #("1 / 2;\n", "binary division"),
    #("1 * 2;\n", "binary multiplication"),
    #("(group);\n", "grouping"),
    #("{\n    block;\n}\n", "block"),
    #("if (true) {\n    then_branch;\n}\n", "if statement, no else"),
    #(
      "if (true) {\n    then_branch;\n} else {\n    else_branch;\n}\n",
      "if statement, with else",
    ),
    #("if (true) true;\n", "if with no block"),
    #("if (true) true; else false;\n", "if else with no blocks"),
    #("var a = 1;\n", "variable declaration"),
    #("var b;\n", "uninitialized variable declaration"),
    #("while (true) for_ever;\n", "while loop"),
    #(
      "var a = 0;
while (a < 10) {
    a = a + 1;
    print a;
}

print a;
",
      "while loop with 2 statements within a block surrounded by statements",
    ),
    #("{\n    var a = 1;\n}\n", "block with declaration"),
    #(
      "var a = 1;\n{\n    a;\n}\n",
      "variable declaration with identifier usage",
    ),
    #(
      "var a = 1;\n{\n    print a;\n}\n",
      "variable declaration followed by print in block",
    ),
    #("var a = 1;\n{}\n", "variable declaration followed by empty block"),
  ]
  use #(source, message) <- test_utils.data_provider(test_cases)
  let tokens = scanner.scan(source).0
  let assert #(statements, []) = parser.parse(tokens)
  assert pretty_printer.pretty_print(statements) == source
    as { "Should roundtrip " <> message }
}

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
