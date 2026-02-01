pub type InvalidToken {
  AndAnd
  OrOr
  BitwiseOr
  BitwiseAnd
}

pub fn lexeme(invalid_token: InvalidToken) -> String {
  case invalid_token {
    AndAnd -> "&&"
    OrOr -> "||"
    BitwiseOr -> "|"
    BitwiseAnd -> "&"
  }
}

pub fn lexeme_length(invalid_token: InvalidToken) -> Int {
  case invalid_token {
    AndAnd -> 2
    OrOr -> 2
    BitwiseOr -> 1
    BitwiseAnd -> 1
  }
}
