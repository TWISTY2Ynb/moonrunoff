///|
test "cashflow reconciliation and forward discount horizon" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  let e = chain_ladder(t, Pattern::fit(t))
  assert_true(e.reconcile().balanced)
  let zero = e.discounted_reserves([0.0, 0.0, 0.0])
  for i in 0..<3 {
    close(zero[i], e.origins()[i].reserve)
  }
  let d = e.discounted_reserves([0.1, 0.1, 0.1])
  close(d[1], 36.0 / 1.1)
  close(d[2], 70.0 / 1.1 + 42.0 / 1.21)
  assert_true(
    try {
      let _ = e.discounted_reserves([-1.0, 0.0, 0.0])
      false
    } catch {
      _ => true
    },
  )
}
