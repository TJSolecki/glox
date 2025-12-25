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

pub fn scanner_can_parse_slash_and_comments() {
  let actual =
    scanner.scan(
      "()
+/-
// this should be ignored
//
[
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
    ],
    [],
  )
  assert actual == expected
}
