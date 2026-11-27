///|
test "strict JSON triangle and pattern roundtrip and rejection" {
  let t = Triangle::from_json("[[100,150,180],[120,180],[140]]")
  assert_eq(Triangle::from_json(t.to_json()).cumulative(), t.cumulative())
  let p = Pattern::fit(t)
  close(Pattern::from_json(p.to_json()).tail(), 1.0)
  assert_true(chain_ladder(t, p).to_json().contains("moonrunoff/v1"))
  for bad in ["null", "[[1,2],[null]]", "[[1,2],[true]]", "[[1,2],[NaN]]"] {
    assert_true(
      try {
        let _ = Triangle::from_json(bad)
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(
    try {
      let _ = Pattern::from_json("{\"factors\":[2],\"tail\":1,\"tail\":2}")
      false
    } catch {
      _ => true
    },
  )
}

///|
test "bounded JSON RC parser preserves depth strings keys and input limits" {
  let mut nested = "0"
  for _ in 0..<16 {
    nested = "[" + nested + "]"
  }
  let _ = parse_json_bounded(nested)
  for bad in ["[" + nested + "]", "{\"x\":1,\"x\":2}", "[}", "\"unterminated"] {
    assert_true(
      try {
        let _ = parse_json_bounded(bad)
        false
      } catch {
        _ => true
      },
    )
  }
  // Many brackets inside a string are not container nesting.
  let _ = parse_json_bounded(
    Json::string("[[[[[[[[[[[[[[[[[[[\\\"{{{").stringify(),
  )
  // Exactly 1 Mi code units is permitted; the next unit is rejected first.
  let boundary = " ".repeat(1048575) + "0"
  let _ = parse_json_bounded(boundary)
  assert_true(
    try {
      let _ = parse_json_bounded(boundary + " ")
      false
    } catch {
      _ => true
    },
  )
}
