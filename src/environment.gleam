import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/result
import interperater_types.{type Literal, type RuntimeError, UndefinedVariable}
import token.{type Token}

pub type Environment {
  Environment(enclosing: Option(Environment), values: Dict(String, Literal))
}

pub fn new() -> Environment {
  Environment(None, dict.new())
}

pub fn create_shadow_env(encolsing_env: Environment) {
  Environment(Some(encolsing_env), dict.new())
}

pub fn get(env: Environment, name: Token) -> Result(Literal, RuntimeError) {
  dict.get(env.values, token.lexeme(name.token_type))
  |> result.try_recover(fn(_) {
    case env.enclosing {
      Some(enclosing) -> get(enclosing, name)
      None -> Error(UndefinedVariable(name))
    }
  })
}

pub fn declare(env: Environment, key: Token, value: Literal) -> Environment {
  Environment(
    enclosing: env.enclosing,
    values: dict.insert(env.values, token.lexeme(key.token_type), value),
  )
}

pub fn assign(
  env: Environment,
  name: Token,
  value: Literal,
) -> #(Result(Literal, RuntimeError), Environment) {
  let env_has_key = dict.has_key(env.values, name.token_type |> token.lexeme)
  case env_has_key, env.enclosing {
    True, _ -> #(Ok(value), declare(env, name, value))
    False, Some(enclosing) -> {
      let #(result, new_enclosing) = assign(enclosing, name, value)
      #(result, Environment(Some(new_enclosing), env.values))
    }
    False, None -> #(Error(UndefinedVariable(name)), env)
  }
}
