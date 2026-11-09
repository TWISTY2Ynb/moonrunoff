///|
test "selection changes observed window and overrides sparse periods" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [200.0, 400.0], [50.0]])
  close(selected_factors(t, recent=1)[0].factor, 2.0)
  close(selected_factors(t, excluded=[(1, 0)])[0].factor, 1.5)
  close(selected_factors(t, overrides=[(1, 1.1)])[1].factor, 1.1)
  assert_true(
    try {
      let _ = selected_factors(t, excluded=[(2, 0)])
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = selected_factors(t, overrides=[(0, 1.1), (0, 1.2)])
      false
    } catch {
      _ => true
    },
  )
}
