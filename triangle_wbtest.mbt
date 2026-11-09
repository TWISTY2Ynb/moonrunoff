///|
test "triangle validates shape, values and defensive copies" {
  let input = [[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]]
  let t = Triangle::new(input)
  input[0][0] = 999.0
  let copy = t.cumulative()
  copy[0][0] = 888.0
  assert_eq(t.at(0, 0), 100.0)
  assert_eq(t.latest(), [180.0, 180.0, 140.0])
  assert_eq(t.observed_count(), 6)
  assert_true(
    try {
      let _ = Triangle::new([[1.0], [2.0]])
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = Triangle::new([[2.0, 1.0], [1.0]])
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = t.at(-1, 0)
      false
    } catch {
      _ => true
    },
  )
}
