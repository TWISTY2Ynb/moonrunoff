///|
test "incremental conversion historical cutoff and aggregation" {
  let rows = [[100.0, 50.0, 30.0], [120.0, 60.0], [140.0]]
  let t = Triangle::from_incremental(rows)
  assert_eq(t.incremental(), rows)
  assert_eq(t.at_calendar(1).cumulative(), [[100.0, 150.0], [120.0]])
  assert_eq(t.calendar_totals(), [100.0, 170.0, 230.0])
  assert_eq(t.development_totals(), [360.0, 110.0, 30.0])
  assert_eq(t.scale(2.0).latest(), [360.0, 360.0, 280.0])
  assert_true(
    try {
      let _ = t.at_calendar(0)
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = t.scale(-1.0)
      false
    } catch {
      _ => true
    },
  )
}
