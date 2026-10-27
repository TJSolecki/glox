import birdie
import errors.{type GloxError}
import gleam/string
import parser
import scanner

pub fn format_unexpected_eof_error_test() {
  errors.error_message(
    errors.UnexpectedEof(3, 1),
    string.repeat("\n", times: 2),
  )
  |> birdie.snap(title: "Unexpected Eof points to the end of the file")
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

pub fn format_error_message_should_handle_invalid_syntax_error_for_wrong_or_test() {
  let source = "true || false;"
  source
  |> scan_source_for_single_error
  |> errors.error_message(source)
  |> birdie.snap(
    title: "Illegal syntax error message for wrong logical or should point to `||`",
  )
}

pub fn format_error_message_should_handle_invalid_syntax_error_for_wrong_and_test() {
  let source = "true && true;"
  source
  |> scan_source_for_single_error
  |> errors.error_message(source)
  |> birdie.snap(
    title: "Illegal syntax error message for wrong logical and should point to `&&`",
  )
}

pub fn format_error_message_should_handle_invalid_syntax_error_for_bitwise_or_test() {
  let source = "1 | 0;"
  source
  |> scan_source_for_single_error
  |> errors.error_message(source)
  |> birdie.snap(
    title: "Illegal syntax error message for bitwise or and should point to `|`",
  )
}

pub fn format_error_message_should_handle_invalid_syntax_error_for_bitwise_and_test() {
  let source = "1 & 1;"
  source
  |> scan_source_for_single_error
  |> errors.error_message(source)
  |> birdie.snap(
    title: "Illegal syntax error message for bitwise and and should point to `&`",
  )
}

pub fn format_error_message_should_point_to_unclosed_left_brace_test() {
  "{}{}{{}"
  |> parse_source_for_single_error_message
  |> birdie.snap(
    title: "MissingRightBrace error message should point to unclosed left brace",
  )
}

pub fn format_error_message_should_point_to_unclosed_left_paren_test() {
  "()()(()"
  |> parse_source_for_single_error_message
  |> birdie.snap(
    title: "MissingRightParen error message should point to unclosed left paren",
  )
}

fn scan_source_for_single_error(source: String) -> GloxError {
  let assert #(_, [error]) = scanner.scan(source)
  error |> errors.from_scan_error
}

fn parse_source_for_single_error_message(source: String) -> String {
  let assert #(tokens, []) = scanner.scan(source)
  let assert #(_, [error]) = parser.parse(tokens)
  error |> errors.from_parse_error(source) |> errors.error_message(source)
}
