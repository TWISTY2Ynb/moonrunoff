///|
test "request engine routes models and rejects silent configuration mistakes" {
  let input = "{\"triangle\":[[100,150,180],[120,180],[140]]}"
  assert_true(execute_request(input).contains("total_reserve"))
  for
    suffix in [
      ",\"unknown\":1", ",\"iterations\":2", ",\"exposure\":[1,2,3]", ",\"action\":\"backtest\",\"factors\":[1.5,1.2]",
    ] {
    let bad = "{\"triangle\":[[100,150,180],[120,180],[140]]" + suffix + "}"
    assert_true(
      try {
        let _ = execute_request(bad)
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(@json.valid(execute_request_result("invalid")[:]))
}
