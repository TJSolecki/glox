import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import parser.{
  type Expression, type Statement, Assign, Binary, Block, ExpressionStatement,
  Grouping, IfStatement, LiteralBool, LiteralNil, LiteralNumber, LiteralString,
  Logical, PrintStatement, Ternary, Unary, Variable, VariableDeclaration,
  WhileStatement,
}
import token

/// A pretty printer for glox
pub fn pretty_print(statements: List(Statement)) -> String {
  list.fold(statements, new(), fn(printer, statement) {
    pretty_print_statement(statement, printer)
  }).source
  |> string.trim
  <> "\n"
}

type Printer {
  Printer(source: String, block_level: Int)
}

fn new() -> Printer {
  Printer(source: "", block_level: 0)
}

fn append(new: String, printer: Printer) -> Printer {
  Printer(
    source: printer.source
      <> string.repeat(" ", times: printer.block_level * 4)
      <> new
      <> "\n",
    block_level: printer.block_level,
  )
}

fn pretty_print_statement(statement: Statement, printer: Printer) -> Printer {
  case statement {
    VariableDeclaration(name, initializer) ->
      "var "
      <> token.lexeme(name.token_type)
      <> initializer
      |> option.map(fn(expression) {
        " = " <> pretty_print_expression(expression)
      })
      |> option.unwrap("")
      <> ";"
    WhileStatement(condition, inner_statement) ->
      "while ("
      <> pretty_print_expression(condition)
      <> ") "
      <> pretty_print_statement(
        inner_statement,
        Printer("", printer.block_level),
      ).source
    PrintStatement(expression) ->
      "print " <> pretty_print_expression(expression) <> ";"
    ExpressionStatement(expression) ->
      pretty_print_expression(expression) <> ";"
    IfStatement(condition, then_branch, else_branch) ->
      "if ("
      <> pretty_print_expression(condition)
      <> ") "
      <> pretty_print_statement(then_branch, Printer("", printer.block_level)).source
      |> string.drop_end(up_to: 1)
      <> option.map(else_branch, fn(else_branch) {
        " else "
        <> pretty_print_statement(else_branch, Printer("", printer.block_level)).source
      })
      |> option.unwrap("")
    Block([]) -> "{}"
    Block(statements) -> {
      let printer_after_block =
        statements
        |> list.fold(
          Printer("{\n", printer.block_level + 1),
          fn(printer, statement) { pretty_print_statement(statement, printer) },
        )
      printer_after_block.source
      <> string.repeat(" ", times: printer.block_level * 4)
      <> "}"
    }
  }
  |> append(printer)
}

fn pretty_print_expression(expression: Expression) -> String {
  case expression {
    Unary(operator, operand, ..) ->
      token.lexeme(operator.token_type) <> pretty_print_expression(operand)
    Binary(left, operator, right, ..) ->
      pretty_print_expression(left)
      <> " "
      <> token.lexeme(operator.token_type)
      <> " "
      <> pretty_print_expression(right)
    Ternary(condition, if_branch, else_branch, ..) ->
      pretty_print_expression(condition)
      <> " ? "
      <> pretty_print_expression(if_branch)
      <> " : "
      <> pretty_print_expression(else_branch)
    Assign(name, value, ..) ->
      token.lexeme(name.token_type) <> " = " <> pretty_print_expression(value)
    Logical(left, operator, right, ..) ->
      pretty_print_expression(left)
      <> " "
      <> token.lexeme(operator.token_type)
      <> " "
      <> pretty_print_expression(right)
    LiteralNumber(value, ..) -> {
      case value == float.floor(value) {
        True -> float.truncate(value) |> int.to_string
        False -> float.to_string(value)
      }
    }
    LiteralBool(value, ..) ->
      case value {
        True -> "true"
        False -> "false"
      }
    LiteralNil(..) -> "nil"
    LiteralString(value, ..) -> "\"" <> value <> "\""
    Variable(name, ..) -> token.lexeme(name.token_type)
    Grouping(inner_expression, ..) ->
      "(" <> pretty_print_expression(inner_expression) <> ")"
  }
}
