///|
test "chain-ladder matches hand calculated ultimate and reserve" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  let e = chain_ladder(t, Pattern::fit(t))
  close(e.origins()[1].ultimate, 216.0)
  close(e.origins()[2].ultimate, 252.0)
  close(e.total_reserve(), 148.0)
  close(e.total_ultimate(), 648.0)
  close(e.total_latest(), 500.0)
  assert_eq(e.estimator(), "chain-ladder")
}
