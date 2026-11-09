///|
test "CSV roundtrip forbids missing duplicate malformed coordinates" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  assert_eq(Triangle::from_csv(t.to_csv()).cumulative(), t.cumulative())
  assert_eq(
    Triangle::from_csv(t.to_csv(incremental=true), incremental=true).cumulative(),
    t.cumulative(),
  )
  for
    bad in [
      "origin,age,value\n0,0,1\n0,1,2\n", "origin,age,value\n0,0,1\n0,0,2\n1,0,3\n",
      "origin,age,value\n-1,0,1\n", "origin,age,value\n0,0,NaN\n",
    ] {
    assert_true(
      try {
        let _ = Triangle::from_csv(bad)
        false
      } catch {
        _ => true
      },
    )
  }
}
