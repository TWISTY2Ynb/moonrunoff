///|
test "all request actions and prior model dispatch produce valid reports" {
  let base = "{\"triangle\":[[100,150,180],[120,190],[140]]"
  for
    options in [
      ",\"estimator\":\"bornhuetter-ferguson\",\"prior\":[200,220,260]}", ",\"estimator\":\"benktander\",\"prior\":[200,220,260],\"iterations\":3}",
      ",\"estimator\":\"cape-cod\",\"exposure\":[1000,1100,1200]}", ",\"action\":\"diagnostics\",\"average\":\"simple\"}",
      ",\"action\":\"backtest\",\"average\":\"regression\"}", ",\"action\":\"stress\",\"factors\":[1.5,1.2],\"tail\":1.1,\"shock\":0.02}",
      ",\"recent\":1,\"excluded\":[],\"overrides\":[[1,1.2]]}",
    ] {
    assert_true(@json.valid(execute_request(base + options)[:]))
  }
  for
    options in [
      ",\"recent\":0.5}", ",\"excluded\":[[0.5,0]]}", ",\"excluded\":[[0,0.5]]}",
      ",\"overrides\":[[1.5,2]]}", ",\"estimator\":\"benktander\",\"prior\":[1,2,3],\"iterations\":1.5}",
      ",\"action\":\"nonsense\"}", ",\"average\":\"nonsense\"}", ",\"factors\":[1.5]}",
    ] {
    assert_true(
      try {
        let _ = execute_request(base + options)
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "reports reject externally constructed inconsistent or nonfinite holdouts" {
  let cell : HoldoutCell = {
    cutoff: 1,
    origin: 1,
    age: 1,
    predicted: 10.0,
    observed: 8.0,
    error: 2.0,
  }
  close(backtest_score([cell]).bias, 2.0)
  assert_true(
    try {
      let _ = backtest_json([{ ..cell, error: 3.0, }])
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = backtest_json([{ ..cell, predicted: 1.0 / 0.0, }])
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = backtest_score([])
      false
    } catch {
      _ => true
    },
  )
}

///|
test "zero-base diagnostics and fully developed zero reserve" {
  let t = Triangle::new([[0.0, 2.0], [3.0]])
  let p = Pattern::new([2.0])
  assert_eq(pair_diagnostics(t, p)[0].ratio, None)
  assert_eq(fit_summary(t, p).zero_bases, 1)
  let unit = Pattern::new([1.0])
  let e = chain_ladder(Triangle::new([[2.0, 2.0], [3.0]]), unit)
  assert_eq(e.payments().length(), 0)
  assert_true(e.reconcile().balanced)
  assert_eq(e.projected_cumulative(Triangle::new([[2.0, 2.0], [3.0]])), [
    [2.0, 2.0],
    [3.0, 3.0],
  ])
}
