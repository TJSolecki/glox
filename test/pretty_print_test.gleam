import pretty_printer
import token

pub fn pretty_print_book_test() {
  let actual =
    pretty_printer.pretty_print(pretty_printer.Binary(
      pretty_printer.Unary(
        token.Token(token.Minus, 1, 1),
        pretty_printer.LiteralNumber(123.0),
      ),
      token.Token(token.Star, 1, 1),
      pretty_printer.Grouping(pretty_printer.LiteralNumber(45.67)),
    ))

  let expected = "(* (- 123) (group 45.67))"
  assert actual == expected
}
