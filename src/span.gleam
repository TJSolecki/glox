import gleam/int
import gleam/string
import token.{type Token}

pub type Span {
  Span(start_line: Int, start_column: Int, end_line: Int, end_column: Int)
}

pub fn line(on line: Int, start start_column: Int, end end_column: Int) -> Span {
  Span(line, start_column, line, end_column)
}

pub fn point(line: Int, column: Int) -> Span {
  Span(line, column, line, column)
}

pub fn from_token(token: Token) -> Span {
  line(
    on: token.line,
    start: token.column,
    end: token.column + { token.lexeme(token.token_type) |> string.length } - 1,
  )
}

pub fn add(span_one: Span, span_two: Span) -> Span {
  Span(
    start_line: int.min(span_one.start_line, span_two.start_line),
    start_column: int.min(span_one.start_column, span_two.start_column),
    end_line: int.max(span_one.end_line, span_two.end_line),
    end_column: int.max(span_one.end_column, span_two.end_column),
  )
}
