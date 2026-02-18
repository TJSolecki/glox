import environment.{type Environment}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import interperater_types.{
  type Literal, type RuntimeError, LiteralBool, LiteralNil, LiteralNumber,
  LiteralString, UnsupportedNegation, UnsupportedOperation,
}
import parser.{type Expression, type Statement}
import token.{type Token}

pub type EvalResult =
  Result(Literal, RuntimeError)

pub type InterperateResult {
  InterperateResult(
    logs: List(String),
    runtime_error: Option(RuntimeError),
    env: Environment,
  )
}

pub fn literal_to_string(literal: Literal) -> String {
  case literal {
    LiteralBool(value) ->
      case value {
        True -> "true"
        False -> "false"
      }
    LiteralNil -> "nil"
    LiteralString(value) -> value
    LiteralNumber(value) -> {
      let truncated_value = float.truncate(value)
      case value == truncated_value |> int.to_float {
        True -> int.to_string(truncated_value)
        False -> float.to_string(value)
      }
    }
  }
}

pub fn interperate(
  statements: List(Statement),
  env: Environment,
) -> InterperateResult {
  interperate_loop(statements, [], env)
}

pub fn interperate_loop(
  statements: List(Statement),
  logs: List(String),
  env: Environment,
) -> InterperateResult {
  case statements {
    [statement, ..rest] -> {
      case interperate_statement(statement, env) {
        #(Ok(Some(log)), env) ->
          interperate_loop(rest, list.append(logs, [log]), env)
        #(Ok(None), env) -> interperate_loop(rest, logs, env)
        #(Error(runtime_error), env) ->
          InterperateResult(logs, Some(runtime_error), env)
      }
    }
    _ -> InterperateResult(logs, None, env)
  }
}

fn interperate_statement(
  statement: Statement,
  env: Environment,
) -> #(Result(Option(String), RuntimeError), Environment) {
  case statement {
    parser.PrintStatement(expression) -> {
      case evaluate(expression, env) {
        Ok(literal) -> #(Ok(Some(literal_to_string(literal))), env)
        Error(runtime_error) -> #(Error(runtime_error), env)
      }
    }
    parser.ExpressionStatement(expression) -> {
      case evaluate(expression, env) {
        Ok(..) -> #(Ok(None), env)
        Error(runtime_error) -> #(Error(runtime_error), env)
      }
    }
    parser.VariableDeclaration(name, None) -> #(
      Ok(None),
      environment.declare(env, name, LiteralNil),
    )
    parser.VariableDeclaration(name, Some(expression)) -> {
      case evaluate(expression, env) {
        Ok(literal) -> #(Ok(None), environment.declare(env, name, literal))
        Error(parse_error) -> #(Error(parse_error), env)
      }
    }
  }
}

pub fn evaluate(expression: Expression, env: Environment) -> EvalResult {
  case expression {
    parser.LiteralBool(value, ..) -> Ok(LiteralBool(value))
    parser.LiteralNumber(value, ..) -> Ok(LiteralNumber(value))
    parser.LiteralString(value, ..) -> Ok(LiteralString(value))
    parser.LiteralNil(..) -> Ok(LiteralNil)
    parser.Grouping(inner_expression, ..) -> evaluate(inner_expression, env)
    parser.Unary(operator, right, ..) -> evaluate_unary(operator, right, env)
    parser.Binary(left, operator, right, ..) ->
      evaluate_binary(left, operator, right, env)
    parser.Ternary(cond, left, right, ..) ->
      evaluate_ternary(cond, left, right, env)
    parser.Variable(name, ..) -> environment.get(env, name)
  }
}

fn evaluate_unary(
  operator: Token,
  right: Expression,
  env: Environment,
) -> EvalResult {
  use literal <- result.try(evaluate(right, env))
  case operator.token_type {
    token.Bang -> Ok(LiteralBool(!is_truthy(literal)))
    token.Minus -> {
      use number <- assert_number(
        literal,
        or_else: UnsupportedNegation(operator, literal),
      )
      Ok(LiteralNumber(value: -1.0 *. number))
    }
    _ ->
      panic as "Unreachable code. Unary only allows Bang and Plus in the grammer"
  }
}

fn assert_number(
  literal: Literal,
  or_else error: RuntimeError,
  on_ok handle_ok: fn(Float) -> EvalResult,
) -> EvalResult {
  case literal {
    LiteralNumber(value) -> handle_ok(value)
    _ -> Error(error)
  }
}

fn is_truthy(literal: Literal) -> Bool {
  case literal {
    LiteralNil -> False
    LiteralBool(value) -> value
    _ -> True
  }
}

fn evaluate_binary(
  left: Expression,
  operator: Token,
  right: Expression,
  env: Environment,
) -> EvalResult {
  use left_literal <- result.try(evaluate(left, env))
  use right_literal <- result.try(evaluate(right, env))
  case operator.token_type {
    token.Minus -> operate_on_numbers(left_literal, operator, right_literal)
    token.Star -> operate_on_numbers(left_literal, operator, right_literal)
    token.Slash -> operate_on_numbers(left_literal, operator, right_literal)
    token.Plus -> {
      case left_literal {
        LiteralNumber(..) ->
          operate_on_numbers(left_literal, operator, right_literal)
        LiteralString(..) ->
          concat_strings(left_literal, operator, right_literal)
        _ -> Error(UnsupportedOperation(left_literal, operator, right_literal))
      }
    }
    token.Less -> operate_on_numbers(left_literal, operator, right_literal)
    token.LessEqual -> operate_on_numbers(left_literal, operator, right_literal)
    token.Greater -> operate_on_numbers(left_literal, operator, right_literal)
    token.GreaterEqual ->
      operate_on_numbers(left_literal, operator, right_literal)
    token.EqualEqual -> Ok(LiteralBool(is_equal(left_literal, right_literal)))
    token.BangEqual -> Ok(LiteralBool(!is_equal(left_literal, right_literal)))
    token.Comma -> Ok(right_literal)
    _ -> Error(UnsupportedOperation(left_literal, operator, right_literal))
  }
}

fn operate_on_numbers(
  left: Literal,
  operator: Token,
  right: Literal,
) -> EvalResult {
  use left_number <- assert_number(
    left,
    or_else: UnsupportedOperation(left, operator, right),
  )
  use right_number <- assert_number(
    right,
    or_else: UnsupportedOperation(left, operator, right),
  )
  case operator.token_type {
    token.Minus -> Ok(LiteralNumber(left_number -. right_number))
    token.Plus -> Ok(LiteralNumber(left_number +. right_number))
    token.Star -> Ok(LiteralNumber(left_number *. right_number))
    token.Slash -> Ok(LiteralNumber(left_number /. right_number))
    token.Less -> Ok(LiteralBool(left_number <. right_number))
    token.LessEqual -> Ok(LiteralBool(left_number <=. right_number))
    token.Greater -> Ok(LiteralBool(left_number >. right_number))
    token.GreaterEqual -> Ok(LiteralBool(left_number >=. right_number))
    _ -> Error(UnsupportedOperation(left, operator, right))
  }
}

fn concat_strings(left: Literal, operator: Token, right: Literal) -> EvalResult {
  use left_string <- assert_string(
    left,
    or_else: UnsupportedOperation(left, operator, right),
  )
  use right_string <- assert_string(
    right,
    or_else: UnsupportedOperation(left, operator, right),
  )
  Ok(LiteralString(left_string <> right_string))
}

fn assert_string(
  literal: Literal,
  or_else error: RuntimeError,
  on_ok handle_ok: fn(String) -> EvalResult,
) -> EvalResult {
  case literal {
    LiteralString(value) -> handle_ok(value)
    _ -> Error(error)
  }
}

fn is_equal(left_literal: Literal, right_literal: Literal) -> Bool {
  case left_literal, right_literal {
    LiteralNil, LiteralNil -> True
    LiteralNumber(left_value), LiteralNumber(right_value) ->
      left_value == right_value
    LiteralString(left_value), LiteralString(right_value) ->
      left_value == right_value
    LiteralBool(left_value), LiteralBool(right_value) ->
      left_value == right_value
    _, _ -> False
  }
}

fn evaluate_ternary(
  condition: Expression,
  left: Expression,
  right: Expression,
  env: Environment,
) -> EvalResult {
  use condition_literal <- result.try(evaluate(condition, env))
  case is_truthy(condition_literal) {
    True -> evaluate(left, env)
    False -> evaluate(right, env)
  }
}
