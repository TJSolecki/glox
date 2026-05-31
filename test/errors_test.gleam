import birdie
import errors
import gleam/string
import parser

pub fn from_unexpected_eof_test() {
  let actual_glox_error =
    errors.from_parse_error(parser.UnexpectedEof, string.repeat("\n", times: 2))
  assert actual_glox_error == errors.UnexpectedEof(3, 1)
}

pub fn format_error_message_points_to_correct_unexpected_grapheme_test() {
  errors.error_message(
    errors.UnexpectedGrapheme(grapheme: "@", line: 10, column: 5),
    string.repeat("\n", times: 8) <> "let @ foo = \"bar\"",
  )
  |> birdie.snap(
    title: "Unexpected grapheme points to the right char on double digit line numbers",
  )
}

pub fn format_error_message_points_to_correct_open_string_test() {
  errors.error_message(
    errors.UnterminatedString(line: 1, column: 11),
    "let foo = \"bar baz",
  )
  |> birdie.snap(
    title: "UnterminatedString error message points to correct opening quote character",
  )
}

pub fn format_error_message_should_handle_first_char_unterminated_string_test() {
  errors.error_message(errors.UnterminatedString(line: 1, column: 1), "\"")
  |> birdie.snap(
    title: "Error message format should handle the first character being an unterminated string",
  )
}
