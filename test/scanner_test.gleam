import scanner
import token

pub fn scanner_single_char_test() {
  let actual = scanner.scan("(")
  let expected = #(
    [
      token.Token(token_type: token.LeftParen, line: 1, column: 1),
      token.Token(token_type: token.Eof, line: 1, column: 2),
    ],
    [],
  )

  assert actual == expected
}

pub fn scanner_double_chars_test() {
  let actual = scanner.scan("() != ==")
  let expected = #(
    [
      token.Token(token_type: token.LeftParen, line: 1, column: 1),
      token.Token(token_type: token.RightParen, line: 1, column: 2),
      token.Token(token_type: token.BangEqual, line: 1, column: 4),
      token.Token(token_type: token.EqualEqual, line: 1, column: 7),
      token.Token(token_type: token.Eof, line: 1, column: 9),
    ],
    [],
  )

  assert actual == expected
}

pub fn scanner_new_line_test() {
  let actual =
    scanner.scan(
      "()
!= @
<
==
",
    )
  let expected = #(
    [
      token.Token(token_type: token.LeftParen, line: 1, column: 1),
      token.Token(token_type: token.RightParen, line: 1, column: 2),
      token.Token(token_type: token.BangEqual, line: 2, column: 1),
      token.Token(token_type: token.Less, line: 3, column: 1),
      token.Token(token_type: token.EqualEqual, line: 4, column: 1),
      token.Token(token_type: token.Eof, line: 5, column: 1),
    ],
    [
      scanner.UnexpectedGrapheme(grapheme: "@", line: 2, column: 4),
    ],
  )

  assert actual == expected
}

pub fn scanner_can_parse_slash_and_comments_test() {
  let actual =
    scanner.scan(
      "()
+/-
// this should be ignored
//
{
//",
    )
  let expected = #(
    [
      token.Token(token_type: token.LeftParen, line: 1, column: 1),
      token.Token(token_type: token.RightParen, line: 1, column: 2),
      token.Token(token_type: token.Plus, line: 2, column: 1),
      token.Token(token_type: token.Slash, line: 2, column: 2),
      token.Token(token_type: token.Minus, line: 2, column: 3),
      token.Token(token_type: token.LeftBrace, line: 5, column: 1),
      token.Token(token_type: token.Eof, line: 6, column: 3),
    ],
    [],
  )
  assert actual == expected
}

pub fn scanner_can_parse_string_literal_test() {
  let actual = scanner.scan("\"foo bar baz\"")
  let expected = #(
    [
      token.Token(
        token_type: token.String(value: "foo bar baz"),
        line: 1,
        column: 1,
      ),
      token.Token(token_type: token.Eof, line: 1, column: 14),
    ],
    [],
  )
  assert actual == expected
}

pub fn scanner_can_parse_multi_line_string_literal_test() {
  let actual =
    scanner.scan(
      "\"foo
bar
baz\"",
    )
  let expected = #(
    [
      token.Token(
        token_type: token.String(
          value: "foo
bar
baz",
        ),
        line: 1,
        column: 1,
      ),
      token.Token(token_type: token.Eof, line: 3, column: 5),
    ],
    [],
  )
  assert actual == expected
}

pub fn scanner_reports_unterminated_strings_test() {
  let actual =
    scanner.scan(
      "^\"foo
bar
baz",
    )
  let expected = #(
    [
      token.Token(token_type: token.Eof, line: 3, column: 4),
    ],
    [
      scanner.UnexpectedGrapheme(grapheme: "^", line: 1, column: 1),
      scanner.UnterminatedString(line: 1, column: 2),
    ],
  )
  assert actual == expected
}

pub fn scanner_can_parse_integers_test() {
  let actual = scanner.scan("123")
  let expected = #(
    [
      token.Token(token_type: token.Number("123"), line: 1, column: 1),
      token.Token(token_type: token.Eof, line: 1, column: 4),
    ],
    [],
  )
  assert actual == expected
}

pub fn scanner_can_parse_floats_test() {
  let actual = scanner.scan("123.23 0.1")
  let expected = #(
    [
      token.Token(token_type: token.Number("123.23"), line: 1, column: 1),
      token.Token(token_type: token.Number("0.1"), line: 1, column: 8),
      token.Token(token_type: token.Eof, line: 1, column: 11),
    ],
    [],
  )
  assert actual == expected
}

pub fn scanner_parses_numbers_with_trailing_dot_as_separate_tokens_test() {
  let actual = scanner.scan("123.")
  let expected = #(
    [
      token.Token(token_type: token.Number("123"), line: 1, column: 1),
      token.Token(token_type: token.Dot, line: 1, column: 4),
      token.Token(token_type: token.Eof, line: 1, column: 5),
    ],
    [],
  )
  assert actual == expected
}

pub fn scanner_can_parse_identifier_test() {
  let actual =
    scanner.scan(
      "foo for bar
while",
    )
  let expected = #(
    [
      token.Token(
        token_type: token.Identifier(value: "foo"),
        line: 1,
        column: 1,
      ),
      token.Token(token_type: token.For, line: 1, column: 5),
      token.Token(
        token_type: token.Identifier(value: "bar"),
        line: 1,
        column: 9,
      ),
      token.Token(token_type: token.While, line: 2, column: 1),
      token.Token(token_type: token.Eof, line: 2, column: 6),
    ],
    [],
  )
  assert actual == expected
}
