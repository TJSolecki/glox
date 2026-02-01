import argv
import errors
import gleam/bool
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_community/ansi
import input
import interperater
import parser
import scanner
import simplifile

pub fn main() -> Nil {
  case argv.load().arguments {
    [] -> run_prompt()
    [file_name] -> run_file(file_name)
    _ -> {
      io.println("Usage: glox [script]")
      exit(64)
    }
  }
}

fn run_prompt() -> Nil {
  io.print("> ")
  case input.input("") {
    Ok(line) -> {
      let trimmed_line = string.trim(line)
      case trimmed_line |> string.is_empty() {
        True -> run_prompt()
        False -> {
          run(trimmed_line)
          run_prompt()
        }
      }
    }
    Error(_) -> Nil
  }
}

fn run_file(file_name: String) -> Nil {
  case simplifile.read(file_name) {
    Ok(content) -> run(content)
    Error(_) -> {
      io.print_error("Error: cannot read file '" <> file_name <> "'")
      exit(1)
    }
  }
}

fn run(code: String) -> Nil {
  let #(tokens, scan_errors) = scanner.scan(code)
  list.each(scan_errors, fn(error) {
    errors.from_scan_error(error)
    |> errors.error_message(code)
    |> ansi.red
    |> io.println_error
    io.println("")
  })
  use <- bool.guard(!list.is_empty(scan_errors), Nil)
  case parser.parse(tokens) {
    Ok(expression) ->
      interperater.evaluate(expression)
      |> result.map(fn(literal) {
        interperater.literal_to_string(literal)
        |> io.println
      })
      |> result.map_error(fn(runtime_error) {
        errors.from_runtime_error(runtime_error)
        |> errors.error_message(code)
        |> ansi.red
        |> io.println_error
        io.println("")
      })
      |> result.unwrap(Nil)
    Error(parser_error) -> {
      errors.from_parse_error(parser_error, code)
      |> errors.error_message(code)
      |> ansi.red
      |> io.println_error
      io.println("")
      Nil
    }
  }
}

@external(erlang, "erlang", "halt")
fn exit(code: Int) -> Nil
