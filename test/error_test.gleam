import errors
import scanner

pub fn format_error_message_points_to_correct_unexpected_grapheme_test() {
  let actual =
    errors.error_message(
      scanner.UnexpectedGrapheme(grapheme: "@", line: 10, column: 5),
      "








let @ foo = \"bar\"",
    )
  let expected =
    "error: Unexpected character
┌─ 10:5
|
10 | let @ foo = \"bar\"
|        ^ I wasn't expecting a \"@\" here."
  assert actual == expected
}

pub fn format_error_message_points_to_correct_open_string_test() {
  let actual =
    errors.error_message(
      scanner.UnterminatedString(line: 1, column: 11),
      "let foo = \"bar baz",
    )
  let expected =
    "error: Unterminated string
┌─ 1:11
|
1 | let foo = \"bar baz
|             ^ This string was never closed."
  assert actual == expected
}
