import gleam/option.{None}
import interperater
import parser
import scanner
import span
import test_utils.{data_provider}

pub fn evaluate_bool_test() {
  assert interperater.evaluate(parser.LiteralBool(True, span.point(0, 0)))
    == Ok(interperater.LiteralBool(True))
}

pub fn evaluate_string_test() {
  assert interperater.evaluate(parser.LiteralString("foo", span.point(0, 0)))
    == Ok(interperater.LiteralString("foo"))
}

pub fn evaluate_number_test() {
  assert interperater.evaluate(parser.LiteralNumber(67.0, span.point(0, 0)))
    == Ok(interperater.LiteralNumber(67.0))
}

pub fn evaluate_nil_test() {
  assert interperater.evaluate(parser.LiteralNil(span.point(0, 0)))
    == Ok(interperater.LiteralNil)
}

pub fn evaluate_expression_test() {
  let test_cases = [
    #("-1", #(["-1"], None), "should negate numbers"),
    #("--1.01", #(["1.01"], None), "should double negate numbers"),
    #("!true", #(["false"], None), "should ! booleans"),
    #("!false", #(["true"], None), "should ! booleans"),
    #(
      "true ? \"left\" : \"right\"",
      #(["left"], None),
      "ternary chooses left branch on true condition",
    ),
    #(
      "false ? \"left\" : \"right\"",
      #(["right"], None),
      "ternary chooses right branch on false condition",
    ),
    #("1,2", #(["2"], None), "comma returns right operand"),
    #("1+2", #(["3"], None), "should add numbers on +"),
    #("\"foo\"+\"bar\"", #(["foobar"], None), "should add strings on +"),
    #("1-2", #(["-1"], None), "should subtract numbers on -"),
    #("4*4", #(["16"], None), "should multiply numbers on *"),
    #("4/4", #(["1"], None), "should divide numbers on /"),
    #(
      "4==4",
      #(["true"], None),
      "equals equals should return true when comparing identical numbers",
    ),
    #(
      "4==3",
      #(["false"], None),
      "equals equals should return false when comparing different numbers",
    ),
    #(
      "4!=4",
      #(["false"], None),
      "not equals should return false when comparing identical numbers",
    ),
    #(
      "4!=3",
      #(["true"], None),
      "not equals should return true when comparing different numbers",
    ),
    #(
      "1<2",
      #(["true"], None),
      "less than should return true when the left hand number is less than the right hand number",
    ),
    #(
      "2<2",
      #(["false"], None),
      "less than should return false when the left hand number is equal to the right hand number",
    ),
    #(
      "3<2",
      #(["false"], None),
      "less than should return false when the left hand number is greater than the right hand number",
    ),
    #(
      "1>2",
      #(["false"], None),
      "greater than should return false when the left hand number is less than the right hand number",
    ),
    #(
      "2>2",
      #(["false"], None),
      "greater than should return false when the left hand number is equal to the right hand number",
    ),
    #(
      "3>2",
      #(["true"], None),
      "greater than should return false when the left hand number is greater than the right hand number",
    ),
    #(
      "1<=2",
      #(["true"], None),
      "less than or equals hould return true when the left hand number is less than the right hand number",
    ),
    #(
      "2<=2",
      #(["true"], None),
      "less than or equals should return true when the left hand number is equal to the right hand number",
    ),
    #(
      "3<=2",
      #(["false"], None),
      "less than or equals should return false when the left hand number is greater than the right hand number",
    ),
    #(
      "1>=2",
      #(["false"], None),
      "greater than or equals should return false when the left hand number is less than the right hand number",
    ),
    #(
      "2>=2",
      #(["true"], None),
      "greater than or equals should return true when the left hand number is equal to the right hand number",
    ),
    #(
      "3>=2",
      #(["true"], None),
      "greater than or equals should return false when the left hand number is greater than the right hand number",
    ),
  ]
  use #(source, expected, message) <- data_provider(test_cases)
  let tokens = scanner.scan("print " <> source <> ";").0
  let #(statements, _) = parser.parse(tokens)
  let actual = interperater.interperate(statements)
  assert actual == expected as message
}
