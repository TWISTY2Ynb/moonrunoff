///|
suberror CliError {
  Usage(String)
}

///|
fn main raise {
  let args = @env.args()
  let mut found = -1
  for i in 0..<args.length() {
    if args[i] == "--request" {
      found = i
      break
    }
  }
  if found < 0 || found + 2 != args.length() {
    raise Usage("moon run cmd/moonrunoff -- --request '<JSON object>'")
  }
  println(@runoff.execute_request(args[found + 1]))
}
