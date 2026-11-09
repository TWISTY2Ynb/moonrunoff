///|
fn main raise {
  let t = @runoff.Triangle::from_json(
    "[[100,150,180,198],[120,180,220],[140,210],[160]]",
  )
  let stats = @runoff.selected_factors(t, recent=2, overrides=[(2, 1.1)])
  let p = @runoff.Pattern::new(stats.map(fn(s) { s.factor }), tail=1.05)
  let e = @runoff.chain_ladder(t, p)
  assert_true(e.reconcile().balanced)
  println(@runoff.diagnostics_json(t, p))
  println(@runoff.backtest_json(@runoff.rolling_holdout(t)))
  println(@runoff.stress_json(@runoff.factor_sensitivity(t, p)))
}
