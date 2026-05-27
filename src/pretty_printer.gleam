import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import parser.{
  type Expression, type Statement, Assign, Binary, Block, ExpressionStatement,
  LiteralNumber, PrintStatement, Variable, VariableDeclaration, WhileStatement,
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
    VariableDeclaration(name, Some(expression)) ->
      "var "
      <> token.lexeme(name.token_type)
      <> " = "
      <> pretty_print_expression(expression)
      <> ";"
    VariableDeclaration(name, None) ->
      "var " <> token.lexeme(name.token_type) <> ";"
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
    Block(statements) -> {
      let printer_after_block =
        statements
        |> list.fold(
          Printer(printer.source <> "{\n", printer.block_level + 1),
          fn(printer, statement) { pretty_print_statement(statement, printer) },
        )
      printer_after_block.source
      <> string.repeat(" ", times: printer.block_level * 4)
      <> "}"
    }
    _ -> todo as "print statement"
  }
  |> append(printer)
}

fn pretty_print_expression(expression: Expression) -> String {
  case expression {
    Binary(left, operator, right, ..) ->
      pretty_print_expression(left)
      <> " "
      <> token.lexeme(operator.token_type)
      <> " "
      <> pretty_print_expression(right)
    Assign(name, value, ..) ->
      token.lexeme(name.token_type) <> " = " <> pretty_print_expression(value)
    LiteralNumber(value, ..) -> {
      case value == float.floor(value) {
        True -> float.truncate(value) |> int.to_string
        False -> float.to_string(value)
      }
    }
    Variable(name, ..) -> token.lexeme(name.token_type)
    _ -> todo as "print expr"
  }
}
