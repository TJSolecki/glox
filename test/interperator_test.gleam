import environment
import interperater.{InterperateResult}
import interperater_types.{LiteralBool, LiteralNil, LiteralNumber, LiteralString}
import parser
import scanner
import span
import test_utils.{data_provider}

pub fn evaluate_bool_test() {
  assert interperater.evaluate(
      parser.LiteralBool(True, span.point(0, 0)),
      environment.new(),
    ).0
    == Ok(LiteralBool(True))
}

pub fn evaluate_string_test() {
  assert interperater.evaluate(
      parser.LiteralString("foo", span.point(0, 0)),
      environment.new(),
    ).0
    == Ok(LiteralString("foo"))
}

pub fn evaluate_number_test() {
  assert interperater.evaluate(
      parser.LiteralNumber(67.0, span.point(0, 0)),
      environment.new(),
    ).0
    == Ok(LiteralNumber(67.0))
}

pub fn evaluate_nil_test() {
  assert interperater.evaluate(
      parser.LiteralNil(span.point(0, 0)),
      environment.new(),
    ).0
    == Ok(LiteralNil)
}

pub fn evaluate_expression_test() {
  let test_cases = [
    #("-1", ["-1"], "should negate numbers"),
    #("--1.01", ["1.01"], "should double negate numbers"),
    #("!true", ["false"], "should ! booleans"),
    #("!false", ["true"], "should ! booleans"),
    #(
      "true ? \"left\" : \"right\"",
      ["left"],
      "ternary chooses left branch on true condition",
    ),
    #(
      "false ? \"left\" : \"right\"",
      ["right"],
      "ternary chooses right branch on false condition",
    ),
    #("1,2", ["2"], "comma returns right operand"),
    #("1+2", ["3"], "should add numbers on +"),
    #("\"foo\"+\"bar\"", ["foobar"], "should add strings on +"),
    #("1-2", ["-1"], "should subtract numbers on -"),
    #("4*4", ["16"], "should multiply numbers on *"),
    #("4/4", ["1"], "should divide numbers on /"),
    #(
      "4==4",
      ["true"],
      "equals equals should return true when comparing identical numbers",
    ),
    #(
      "4==3",
      ["false"],
      "equals equals should return false when comparing different numbers",
    ),
    #(
      "4!=4",
      ["false"],
      "not equals should return false when comparing identical numbers",
    ),
    #(
      "4!=3",
      ["true"],
      "not equals should return true when comparing different numbers",
    ),
    #(
      "1<2",
      ["true"],
      "less than should return true when the left hand number is less than the right hand number",
    ),
    #(
      "2<2",
      ["false"],
      "less than should return false when the left hand number is equal to the right hand number",
    ),
    #(
      "3<2",
      ["false"],
      "less than should return false when the left hand number is greater than the right hand number",
    ),
    #(
      "1>2",
      ["false"],
      "greater than should return false when the left hand number is less than the right hand number",
    ),
    #(
      "2>2",
      ["false"],
      "greater than should return false when the left hand number is equal to the right hand number",
    ),
    #(
      "3>2",
      ["true"],
      "greater than should return false when the left hand number is greater than the right hand number",
    ),
    #(
      "1<=2",
      ["true"],
      "less than or equals hould return true when the left hand number is less than the right hand number",
    ),
    #(
      "2<=2",
      ["true"],
      "less than or equals should return true when the left hand number is equal to the right hand number",
    ),
    #(
      "3<=2",
      ["false"],
      "less than or equals should return false when the left hand number is greater than the right hand number",
    ),
    #(
      "1>=2",
      ["false"],
      "greater than or equals should return false when the left hand number is less than the right hand number",
    ),
    #(
      "2>=2",
      ["true"],
      "greater than or equals should return true when the left hand number is equal to the right hand number",
    ),
    #(
      "3>=2",
      ["true"],
      "greater than or equals should return false when the left hand number is greater than the right hand number",
    ),
  ]
  use #(source, expected_logs, message) <- data_provider(test_cases)
  let tokens = scanner.scan("print " <> source <> ";").0
  let #(statements, _) = parser.parse(tokens)
  let InterperateResult(logs: actual_logs, ..) =
    interperater.interperate(statements, environment.new())
  assert actual_logs == expected_logs as message
}
