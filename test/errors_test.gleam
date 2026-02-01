import errors
import parser

pub fn from_unexpected_eof_test() {
  let actual_glox_error =
    errors.from_parse_error(
      parser.UnexpectedEof,
      "

",
    )
  assert actual_glox_error == errors.UnexpectedEof(3, 1)
}

pub fn format_error_message_points_to_correct_unexpected_grapheme_test() {
  let actual =
    errors.error_message(
      errors.UnexpectedGrapheme(grapheme: "@", line: 10, column: 5),
      "








let @ foo = \"bar\"",
    )
  let expected =
    "error: Unexpected character
┌─ 10:5
|
10 | let @ foo = \"bar\"
|        ^

We weren't expecting a \"@\" here."
  assert actual == expected
}

pub fn format_error_message_points_to_correct_open_string_test() {
  let actual =
    errors.error_message(
      errors.UnterminatedString(line: 1, column: 11),
      "let foo = \"bar baz",
    )
  let expected =
    "error: Unterminated string
┌─ 1:11
|
1 | let foo = \"bar baz
|             ^

This string was never closed."
  assert actual == expected
}

pub fn format_error_message_should_handle_first_char_unterminated_string_test() {
  let actual =
    errors.error_message(errors.UnterminatedString(line: 1, column: 1), "\"")
  let expected =
    "error: Unterminated string
┌─ 1:1
|
1 | \"
|   ^

This string was never closed."
  assert actual == expected
}
