///|
test "exact multiplicative triangle has zero raw residuals" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  let p = Pattern::fit(t)
  let s = fit_summary(t, p)
  assert_eq(s.pairs, 3)
  close(s.root_mean_square_residual, 0.0)
  close(s.mean_absolute_residual, 0.0)
  assert_eq(pair_diagnostics(t, p)[0].ratio, Some(1.5))
}
