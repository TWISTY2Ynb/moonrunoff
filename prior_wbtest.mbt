///|
test "BF prior weighting and Benktander iteration semantics" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  let p = Pattern::new([1.5, 1.2])
  let prior = [200.0, 200.0, 200.0]
  let bf = bornhuetter_ferguson(t, p, prior)
  close(bf.origins()[0].reserve, 0.0)
  close(bf.origins()[1].ultimate, 180.0 + 200.0 / 6.0)
  close(
    benktander(t, p, prior, iterations=1).total_reserve(),
    bf.total_reserve(),
  )
  close(benktander(t, p, prior, iterations=100).origins()[2].ultimate, 252.0)
  assert_true(
    try {
      let _ = benktander(t, p, prior, iterations=0)
      false
    } catch {
      _ => true
    },
  )
}
