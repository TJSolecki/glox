import gleam/list
import gleam/result
import gleam/string
import token.{type Token, type TokenType}

type Scanner {
  Scanner(graphemes: List(String), line: Int, column: Int)
}

pub type ScanError {
  UnterminatedString(line: Int, column: Int)
  UnexpectedGrapheme(grapheme: String, line: Int, column: Int)
}

pub fn scan(source: String) -> #(List(Token), List(ScanError)) {
  source
  |> new
  |> iterate
  |> result.partition
}

fn new(source: String) -> Scanner {
  Scanner(graphemes: string.to_graphemes(source), line: 1, column: 1)
}

fn iterate(scanner: Scanner) -> List(Result(Token, ScanError)) {
  iterate_inner(scanner, []).1
}

fn iterate_inner(
  scanner: Scanner,
  tokens: List(Result(Token, ScanError)),
) -> #(Scanner, List(Result(Token, ScanError))) {
  let #(new_scanner, token) = scan_next_token(scanner)
  case token {
    Ok(token) ->
      case token.token_type == token.Eof {
        True -> #(new_scanner, list.prepend(tokens, Ok(token)))
        False -> iterate_inner(new_scanner, list.prepend(tokens, Ok(token)))
      }
    Error(error) ->
      iterate_inner(new_scanner, list.prepend(tokens, Error(error)))
  }
}

fn scan_next_token(scanner: Scanner) -> #(Scanner, Result(Token, ScanError)) {
  case scanner.graphemes {
    [] -> #(scanner, token(scanner, token.Eof))
    [" ", ..rest] -> advance(scanner, rest) |> scan_next_token
    ["\t", ..rest] -> advance(scanner, rest) |> scan_next_token
    ["\r\n", ..rest] | ["\n", ..rest] ->
      add_line(scanner, rest) |> scan_next_token
    ["(", ..rest] -> advance_with_token(scanner, rest, token.LeftParen)
    [")", ..rest] -> advance_with_token(scanner, rest, token.RightParen)
    ["{", ..rest] -> advance_with_token(scanner, rest, token.LeftBrace)
    ["}", ..rest] -> advance_with_token(scanner, rest, token.RightBrace)
    [",", ..rest] -> advance_with_token(scanner, rest, token.Comma)
    [".", ..rest] -> advance_with_token(scanner, rest, token.Dot)
    ["-", ..rest] -> advance_with_token(scanner, rest, token.Minus)
    ["+", ..rest] -> advance_with_token(scanner, rest, token.Plus)
    [";", ..rest] -> advance_with_token(scanner, rest, token.Semicolon)
    ["*", ..rest] -> advance_with_token(scanner, rest, token.Star)
    ["!", "=", ..rest] -> advance_with_token(scanner, rest, token.BangEqual)
    ["!", ..rest] -> advance_with_token(scanner, rest, token.Bang)
    ["=", "=", ..rest] -> advance_with_token(scanner, rest, token.EqualEqual)
    ["=", ..rest] -> advance_with_token(scanner, rest, token.Equal)
    ["<", "=", ..rest] -> advance_with_token(scanner, rest, token.LessEqual)
    ["<", ..rest] -> advance_with_token(scanner, rest, token.Less)
    [">", "=", ..rest] -> advance_with_token(scanner, rest, token.GreaterEqual)
    [">", ..rest] -> advance_with_token(scanner, rest, token.Greater)
    ["/", "/", ..rest] ->
      advance(scanner, rest) |> advance_until_new_line |> scan_next_token
    ["/", ..rest] -> advance_with_token(scanner, rest, token.Slash)
    ["\"", ..rest] -> advance(scanner, rest) |> eat_string
    [grapheme, ..rest] -> #(
      advance(scanner, rest),
      Error(UnexpectedGrapheme(
        grapheme,
        line: scanner.line,
        column: scanner.column,
      )),
    )
  }
}

fn advance_with_token(
  scanner: Scanner,
  graphemes: List(String),
  token_type: TokenType,
) {
  let lexeme_length = token.lexeme(token_type) |> string.length()
  #(
    Scanner(
      graphemes,
      column: scanner.column + lexeme_length,
      line: scanner.line,
    ),
    token(scanner, token_type),
  )
}

fn advance(scanner: Scanner, graphemes: List(String)) {
  Scanner(graphemes, column: scanner.column + 1, line: scanner.line)
}

fn add_line(scanner: Scanner, graphemes: List(String)) -> Scanner {
  Scanner(graphemes, column: 1, line: scanner.line + 1)
}

fn token(scanner: Scanner, token_type: TokenType) -> Result(Token, ScanError) {
  Ok(token.Token(token_type, line: scanner.line, column: scanner.column))
}

fn advance_until_new_line(scanner: Scanner) -> Scanner {
  case scanner.graphemes {
    [] -> advance(scanner, [])
    ["\n", ..rest] | ["\r\n", ..rest] ->
      Scanner(graphemes: rest, line: scanner.line + 1, column: 1)
    [_, ..rest] -> advance(scanner, rest) |> advance_until_new_line()
  }
}

fn eat_string(scanner: Scanner) -> #(Scanner, Result(Token, ScanError)) {
  case eat_string_inner(scanner, "") {
    #(new_scanner, Ok(value)) -> #(
      new_scanner,
      Ok(token.Token(
        token_type: token.String(value),
        line: scanner.line,
        column: scanner.column - 1,
      )),
    )
    #(new_scanner, Error(_)) -> #(
      new_scanner,
      Error(UnterminatedString(line: scanner.line, column: scanner.column - 1)),
    )
  }
}

fn eat_string_inner(
  scanner: Scanner,
  string: String,
) -> #(Scanner, Result(String, Nil)) {
  case scanner.graphemes {
    [] -> #(scanner, Error(Nil))
    ["\"", ..rest] -> #(advance(scanner, rest), Ok(string))
    ["\n", ..rest] | ["\r\n", ..rest] ->
      eat_string_inner(add_line(scanner, rest), string <> "\n")
    [grapheme, ..rest] ->
      eat_string_inner(advance(scanner, rest), string <> grapheme)
  }
}
