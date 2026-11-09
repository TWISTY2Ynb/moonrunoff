///|
test "triangle shape and paid claim boundaries" {
  for
    rows in [
      [],
      [[1.0]],
      [[1.0, 2.0], [1.0, 2.0]],
      [[2.0, 1.0], [1.0]],
      [[1.0, 2.0], [-1.0]],
    ] {
    assert_true(
      try {
        let _ = Triangle::new(rows)
        false
      } catch {
        _ => true
      },
    )
  }
  let nan = 0.0 / 0.0
  let inf = 1.0 / 0.0
  for x in [nan, inf, -inf] {
    assert_true(
      try {
        let _ = Triangle::new([[1.0, 2.0], [x]])
        false
      } catch {
        _ => true
      },
    )
    assert_true(
      try {
        let _ = Pattern::new([x])
        false
      } catch {
        _ => true
      },
    )
  }
  let rows : Array[Array[Double]] = []
  for i in 0..<128 {
    rows.push(Array::make(128 - i, 0.0))
  }
  let t = Triangle::new(rows)
  assert_eq(t.observed_count(), 8256)
  let p = Pattern::new(Array::make(127, 1.0))
  let e = chain_ladder(t, p)
  close(e.total_reserve(), 0.0)
  assert_true(e.reconcile().balanced)
  assert_true(Triangle::from_csv(t.to_csv()).observed_count() == 8256)
}

///|
test "all model paths propagate overflow and reject bad priors" {
  let t = Triangle::new([[1.0, 2.0], [1.0e308]])
  let p = Pattern::new([2.0])
  assert_true(
    try {
      let _ = chain_ladder(t, p)
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = bornhuetter_ferguson(t, p, [1.0, -1.0])
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = bornhuetter_ferguson(t, p, [1.0])
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = benktander(t, p, [1.0, 1.0], iterations=1001)
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      let _ = t.scale(2.0)
      false
    } catch {
      _ => true
    },
  )
  let sparse = Triangle::new([[0.0, 2.0], [3.0]])
  let manual = selected_factors(sparse, overrides=[(0, 2.0)])
  close(manual[0].factor, 2.0)
  assert_eq(manual[0].pairs, 0)
}

///|
test "request numeric types JSON depth and irrelevant controls are strict" {
  for
    text in [
      "{\"triangle\":[[1,2],[1]],\"recent\":1.5}", "{\"triangle\":[[1,2],[1]],\"incremental\":1}",
      "{\"triangle\":[[1,2],[1]],\"estimator\":\"unknown\"}", "{\"triangle\":[[1,2],[1]],\"prior\":[1,2]}",
      "{\"triangle\":[[1,2],[1]],\"action\":\"diagnostics\",\"exposure\":[1,2]}",
      "{\"triangle\":[[1,2],[1]],\"factors\":[2],\"recent\":0}", "[[[[[[[[[[[[[[[[[1]]]]]]]]]]]]]]]]]",
    ] {
    assert_true(
      try {
        let _ = execute_request(text)
        false
      } catch {
        _ => true
      },
    )
  }
}
