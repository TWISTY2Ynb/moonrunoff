///|
test "holdout has no future leakage and excludes unseen origins" {
  let a = Triangle::new([[100.0, 150.0, 180.0], [120.0, 190.0], [140.0]])
  let b = Triangle::new([[100.0, 150.0, 9999.0], [120.0, 9000.0], [9000.0]])
  let ha = holdout(a, 1)
  let hb = holdout(b, 1)
  assert_eq(ha.length(), 1)
  close(ha[0].predicted, 180.0)
  close(hb[0].predicted, ha[0].predicted)
  close(backtest_score(ha).mean_absolute_error, 10.0)
  close(backtest_score(rolling_holdout(a)).bias, -10.0)
}
