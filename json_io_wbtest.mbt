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
