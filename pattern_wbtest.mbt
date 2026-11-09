///|
test "CDF includes tail once and defends against caller mutation" {
  let xs = [1.5, 1.2]
  let p = Pattern::new(xs, tail=1.1)
  xs[0] = 9.0
  close(p.cumulative_factors()[0], 1.98)
  close(p.reported_fraction(1), 1.0 / 1.32)
  assert_true(
    try {
      let _ = Pattern::new([0.9])
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = Pattern::new([1.0e308, 1.0e308])
      false
    } catch {
      _ => true
    },
  )
}
