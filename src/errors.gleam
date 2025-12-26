import gleam/int
import gleam/list
import gleam/string
import scanner.{type ScanError}

pub fn error_message(scan_error: ScanError, source: String) {
  let lines = string.split(source, on: "\n")
  let assert Ok(code_line) =
    list.take(lines, line_number(scan_error)) |> list.last

  let line = line_number(scan_error) |> int.to_string
  let column = column_number(scan_error) |> int.to_string
  let additional_padding_left = string.length(line) - 1
  let description = error_description(scan_error)
  let pointer =
    string.repeat(
      " ",
      times: additional_padding_left + column_number(scan_error) - 1,
    )
    <> "^ "
    <> description
  let message =
    format_error_message(
      title: error_title(scan_error),
      line: line,
      column: column,
      code_line: code_line,
      pointer: pointer,
    )
  message
}

fn error_title(scan_error: ScanError) -> String {
  case scan_error {
    scanner.UnexpectedGrapheme(..) -> "Unexpected character"
    scanner.UnterminatedString(..) -> "Unterminated string"
  }
}

fn error_description(scan_error: ScanError) -> String {
  case scan_error {
    scanner.UnexpectedGrapheme(grapheme, ..) ->
      "I wasn't expecting a \"" <> grapheme <> "\" here."
    scanner.UnterminatedString(..) -> "This string was never closed."
  }
}

fn line_number(scan_error: ScanError) {
  case scan_error {
    scanner.UnexpectedGrapheme(_, line, ..) -> line
    scanner.UnterminatedString(line, ..) -> line
  }
}

fn column_number(scan_error: ScanError) {
  case scan_error {
    scanner.UnexpectedGrapheme(_, _, column) -> column
    scanner.UnterminatedString(_, column) -> column
  }
}

fn format_error_message(
  title error_title: String,
  line line_str: String,
  column column_str: String,
  code_line code: String,
  pointer point: String,
) -> String {
  "error: " <> error_title <> "
┌─ " <> line_str <> ":" <> column_str <> "
|
" <> line_str <> " | " <> code <> "
|   " <> point
}
