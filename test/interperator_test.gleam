import interperater
import parser
import scanner
import test_utils.{data_provider}

pub fn evaluate_bool_test() {
  assert interperater.evaluate(parser.LiteralBool(True))
    == Ok(interperater.LiteralBool(True))
}

pub fn evaluate_string_test() {
  assert interperater.evaluate(parser.LiteralString("foo"))
    == Ok(interperater.LiteralString("foo"))
}

pub fn evaluate_number_test() {
  assert interperater.evaluate(parser.LiteralNumber(67.0))
    == Ok(interperater.LiteralNumber(67.0))
}

pub fn evaluate_nil_test() {
  assert interperater.evaluate(parser.LiteralNil) == Ok(interperater.LiteralNil)
}

pub fn evaluate_expression_test() {
  let test_cases = [
    #("-1", Ok(interperater.LiteralNumber(-1.0)), "should negate numbers"),
    #(
      "--1.01",
      Ok(interperater.LiteralNumber(1.01)),
      "should double negate numbers",
    ),
    #("!true", Ok(interperater.LiteralBool(False)), "should ! booleans"),
    #("!false", Ok(interperater.LiteralBool(True)), "should ! booleans"),
    #(
      "true ? \"left\" : \"right\"",
      Ok(interperater.LiteralString("left")),
      "ternary chooses left branch on true condition",
    ),
    #(
      "false ? \"left\" : \"right\"",
      Ok(interperater.LiteralString("right")),
      "ternary chooses right branch on false condition",
    ),
    #("1,2", Ok(interperater.LiteralNumber(2.0)), "comma returns right operand"),
    #("1+2", Ok(interperater.LiteralNumber(3.0)), "should add numbers on +"),
    #(
      "1-2",
      Ok(interperater.LiteralNumber(-1.0)),
      "should subtract numbers on -",
    ),
    #(
      "4*4",
      Ok(interperater.LiteralNumber(16.0)),
      "should multiply numbers on *",
    ),
    #("4/4", Ok(interperater.LiteralNumber(1.0)), "should divide numbers on /"),
    #(
      "4==4",
      Ok(interperater.LiteralBool(True)),
      "should compare identical numbers",
    ),
    #(
      "4!=4",
      Ok(interperater.LiteralBool(False)),
      "identical numbers should return false for !=",
    ),
  ]
  use #(source, expected, message) <- data_provider(test_cases)
  let tokens = scanner.scan(source).0
  let assert Ok(expression) = parser.parse(tokens)
  assert interperater.evaluate(expression) == expected as message
}
