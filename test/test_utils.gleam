import gleam/list

pub fn data_provider(test_cases: List(_), run_test: fn(_) -> Nil) -> Nil {
  list.each(test_cases, fn(test_case) { run_test(test_case) })
}
