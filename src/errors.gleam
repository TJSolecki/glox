import gleam/int
import gleam/list
import gleam/result
import gleam/string
import parser.{type ParseError}
import scanner.{type ScanError}

pub type GloxError {
  UnterminatedString(line: Int, column: Int)
  UnexpectedGrapheme(grapheme: String, line: Int, column: Int)
  MissingRightParen(line: Int, column: Int)
  ExpectExpression(line: Int, column: Int)
  MissingColon(line: Int, column: Int)
  UnexpectedEof(line: Int, column: Int)
}

pub fn from_scan_error(scan_error: ScanError) -> GloxError {
  case scan_error {
    scanner.UnterminatedString(line, column) -> UnterminatedString(line, column)
    scanner.UnexpectedGrapheme(grapheme, line, column) ->
      UnexpectedGrapheme(grapheme, line, column)
  }
}

pub fn from_parse_error(parse_error: ParseError, source: String) -> GloxError {
  case parse_error {
    parser.MissingRightParen(line, column) -> MissingRightParen(line, column)
    parser.ExpectExpression(line, column) -> ExpectExpression(line, column)
    parser.MissingColon(line, column) -> MissingColon(line, column)
    parser.UnexpectedEof -> {
      let lines = string.split(source, on: "\n")
      let final_line = list.last(lines)
      UnexpectedEof(
        line: int.max(list.length(lines), 1),
        column: result.map(final_line, string.length)
          |> result.unwrap(1)
          |> int.max(1),
      )
    }
  }
}

pub fn error_message(error: GloxError, source: String) {
  let lines = string.split(source, on: "\n")
  let assert Ok(code_line) = list.take(lines, line_number(error)) |> list.last

  let line = line_number(error) |> int.to_string
  let column = column_number(error) |> int.to_string
  let additional_padding_left = string.length(line) - 1
  let description = error_description(error)
  let pointer =
    string.repeat(
      " ",
      times: additional_padding_left + column_number(error) - 1,
    )
    <> "^ "
    <> description
  let message =
    format_error_message(
      title: error_title(error),
      line: line,
      column: column,
      code_line: code_line,
      pointer: pointer,
    )
  message
}

fn error_title(scan_error: GloxError) -> String {
  case scan_error {
    UnexpectedGrapheme(..) -> "Unexpected character"
    UnterminatedString(..) -> "Unterminated string"
    ExpectExpression(..) -> "Missing expression"
    MissingRightParen(..) -> "Missing ')'"
    MissingColon(..) -> "Expected ':' before ';'"
    UnexpectedEof(..) -> "Unexpected end of file"
  }
}

fn error_description(error: GloxError) -> String {
  case error {
    UnexpectedGrapheme(grapheme, ..) ->
      "We weren't expecting a \"" <> grapheme <> "\" here."
    UnterminatedString(..) -> "This string was never closed."
    ExpectExpression(..) -> "We were expecting an expression here."
    MissingRightParen(..) -> "This parentheses was never closed."
    MissingColon(..) -> "This ternary has no ':'."
    UnexpectedEof(..) -> "We didn't expect to end here."
  }
}

fn line_number(error: GloxError) -> Int {
  case error {
    UnexpectedGrapheme(line: line, ..) -> line
    UnterminatedString(line: line, ..) -> line
    ExpectExpression(line: line, ..) -> line
    MissingRightParen(line: line, ..) -> line
    MissingColon(line: line, ..) -> line
    UnexpectedEof(line: line, ..) -> line
  }
}

fn column_number(error: GloxError) {
  case error {
    UnexpectedGrapheme(column: column, ..) -> column
    UnterminatedString(column: column, ..) -> column
    ExpectExpression(column: column, ..) -> column
    MissingRightParen(column: column, ..) -> column
    MissingColon(column: column, ..) -> column
    UnexpectedEof(column: column, ..) -> column
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
