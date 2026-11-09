///|
test "reports contain valid versioned JSON and numeric CSV" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 190.0], [140.0]])
  let p = Pattern::fit(t)
  assert_true(@json.valid(diagnostics_json(t, p)[:]))
  assert_true(@json.valid(backtest_json(rolling_holdout(t))[:]))
  assert_true(@json.valid(stress_json(factor_sensitivity(t, p))[:]))
  assert_true(
    chain_ladder(t, p).to_csv().contains("origin,age,latest,ultimate,reserve"),
  )
}
