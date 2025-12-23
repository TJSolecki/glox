import argv
import gleam/io

pub fn main() -> Nil {
  case argv.load().arguments {
    [] -> run_prompt()
    [file_name] -> run_file(file_name)
    _ -> {
      io.println("Usage: glox [script]")
      halt(64)
    }
  }
}

fn run_prompt() -> Nil {
  // todo
  Nil
}

fn run_file(_file_name: String) -> Nil {
  // todo
  Nil
}

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil
