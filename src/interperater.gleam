import environment.{type Environment}
import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import interperater_types.{
  type Literal, type RuntimeError, LiteralBool, LiteralNil, LiteralNumber,
  LiteralString, UnsupportedNegation, UnsupportedOperation,
}
import parser.{type Expression, type Statement}
import token.{type Token}

pub type EvalResult =
  #(Result(Literal, RuntimeError), environment.Environment)

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
        InterperateResult(new_logs, None, new_env) ->
          interperate_loop(rest, list.append(logs, new_logs), new_env)
        InterperateResult(new_logs, Some(runtime_error), new_env) ->
          InterperateResult(
            list.append(logs, new_logs),
            Some(runtime_error),
            new_env,
          )
      }
    }
    _ -> InterperateResult(logs, None, env)
  }
}

fn interperate_statement(
  statement: Statement,
  env: Environment,
) -> InterperateResult {
  case statement {
    parser.IfStatement(condition, then_statement, else_statement) -> {
      case evaluate(condition, env) {
        #(Ok(literal), env) -> {
          case is_truthy(literal) {
            True -> interperate_statement(then_statement, env)
            False ->
              else_statement
              |> option.map(interperate_statement(_, env))
              |> option.unwrap(InterperateResult([], None, env))
          }
        }
        #(Error(runtime_error), env) ->
          InterperateResult([], Some(runtime_error), env)
      }
    }
    parser.PrintStatement(expression) -> {
      case evaluate(expression, env) {
        #(Ok(literal), env) ->
          InterperateResult([literal_to_string(literal)], None, env)
        #(Error(runtime_error), env) ->
          InterperateResult([], Some(runtime_error), env)
      }
    }
    parser.WhileStatement(condition, body) -> {
      case evaluate(condition, env) {
        #(Ok(literal), env_after_condition) ->
          case is_truthy(literal) {
            True -> {
              use logs, env_after_body <- try_unwrap_interperate_result(
                interperate_statement(body, env_after_condition),
              )
              interperate_statement(statement, env_after_body)
              |> prepend_logs(logs)
            }
            False -> InterperateResult([], None, env)
          }
        #(Error(runtime_error), env) ->
          InterperateResult([], Some(runtime_error), env)
      }
    }
    parser.ExpressionStatement(expression) -> {
      case evaluate(expression, env) {
        #(Ok(..), env) -> InterperateResult([], None, env)
        #(Error(runtime_error), env) ->
          InterperateResult([], Some(runtime_error), env)
      }
    }
    parser.VariableDeclaration(name, None) ->
      InterperateResult([], None, environment.declare(env, name, LiteralNil))
    parser.VariableDeclaration(name, Some(expression)) -> {
      case evaluate(expression, env) {
        #(Ok(literal), env) ->
          InterperateResult([], None, environment.declare(env, name, literal))
        #(Error(parse_error), env) ->
          InterperateResult([], Some(parse_error), env)
      }
    }
    parser.Block(statements) -> {
      let assert InterperateResult(
        logs,
        runtime_error,
        environment.Environment(Some(new_env), ..),
      ) = interperate_loop(statements, [], environment.create_shadow_env(env))
      InterperateResult(logs, runtime_error, new_env)
    }
  }
}

fn try_unwrap_interperate_result(
  result: InterperateResult,
  on_ok: fn(List(String), Environment) -> InterperateResult,
) -> InterperateResult {
  case result {
    InterperateResult(runtime_error: Some(..), ..) -> result
    InterperateResult(logs, None, env) -> on_ok(logs, env)
  }
}

fn prepend_logs(
  result: InterperateResult,
  logs_to_add: List(String),
) -> InterperateResult {
  let InterperateResult(logs, runtime_error, env) = result
  InterperateResult(list.append(logs_to_add, logs), runtime_error, env)
}

pub fn evaluate(expression: Expression, env: Environment) -> EvalResult {
  case expression {
    parser.LiteralBool(value, ..) -> #(Ok(LiteralBool(value)), env)
    parser.LiteralNumber(value, ..) -> #(Ok(LiteralNumber(value)), env)
    parser.LiteralString(value, ..) -> #(Ok(LiteralString(value)), env)
    parser.LiteralNil(..) -> #(Ok(LiteralNil), env)
    parser.Grouping(inner_expression, ..) -> evaluate(inner_expression, env)
    parser.Unary(operator, right, ..) -> evaluate_unary(operator, right, env)
    parser.Binary(left, operator, right, ..) ->
      evaluate_binary(left, operator, right, env)
    parser.Logical(left, operator, right, ..) ->
      evaluate_logical(left, operator, right, env)
    parser.Ternary(cond, left, right, ..) ->
      evaluate_ternary(cond, left, right, env)
    parser.Variable(name, ..) -> #(environment.get(env, name), env)
    parser.Assign(name, expression, ..) -> {
      case evaluate(expression, env) {
        #(Ok(literal), new_env) -> environment.assign(new_env, name, literal)
        error -> error
      }
    }
  }
}

fn evaluate_unary(
  operator: Token,
  right: Expression,
  env: Environment,
) -> EvalResult {
  use literal, env <- try_unwrap_eval_result(evaluate(right, env))
  case operator.token_type {
    token.Bang -> #(Ok(LiteralBool(!is_truthy(literal))), env)
    token.Minus -> {
      case literal {
        LiteralNumber(number) -> #(
          Ok(LiteralNumber(value: -1.0 *. number)),
          env,
        )
        _ -> #(Error(UnsupportedNegation(operator, literal)), env)
      }
    }
    _ ->
      panic as "Unreachable code. Unary only allows Bang and Plus in the grammer"
  }
}

fn assert_number(
  literal: Literal,
  or_else error: RuntimeError,
  on_ok handle_ok: fn(Float) -> Result(Literal, RuntimeError),
) -> Result(Literal, RuntimeError) {
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
  use left_literal, env <- try_unwrap_eval_result(evaluate(left, env))
  use right_literal, env <- try_unwrap_eval_result(evaluate(right, env))
  let literal_or_error = case operator.token_type {
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
  #(literal_or_error, env)
}

fn operate_on_numbers(
  left: Literal,
  operator: Token,
  right: Literal,
) -> Result(Literal, RuntimeError) {
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

fn concat_strings(
  left: Literal,
  operator: Token,
  right: Literal,
) -> Result(Literal, RuntimeError) {
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
  on_ok handle_ok: fn(String) -> Result(Literal, RuntimeError),
) -> Result(Literal, RuntimeError) {
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

fn evaluate_logical(
  left: Expression,
  operator: Token,
  right: Expression,
  env: Environment,
) -> EvalResult {
  use left_literal, env <- try_unwrap_eval_result(evaluate(left, env))
  let or = operator.token_type == token.Or
  let truthy = is_truthy(left_literal)
  use <- bool.guard(or && truthy || !or && !truthy, #(Ok(left_literal), env))
  evaluate(right, env)
}

fn evaluate_ternary(
  condition: Expression,
  left: Expression,
  right: Expression,
  env: Environment,
) -> EvalResult {
  use condition_literal, env <- try_unwrap_eval_result(evaluate(condition, env))
  case is_truthy(condition_literal) {
    True -> evaluate(left, env)
    False -> evaluate(right, env)
  }
}

fn try_unwrap_eval_result(
  eval_result: EvalResult,
  handle_ok: fn(Literal, Environment) -> EvalResult,
) -> EvalResult {
  case eval_result {
    #(Ok(literal), env) -> handle_ok(literal, env)
    error -> error
  }
}
