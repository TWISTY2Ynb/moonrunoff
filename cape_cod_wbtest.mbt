///|
test "Cape Cod uses reported exposure denominator" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  let p = Pattern::new([1.5, 1.2])
  let c = cape_cod(t, p, [200.0, 220.0, 240.0])
  close(c.adjusted_exposure(), 200.0 + 220.0 / 1.2 + 240.0 / 1.8)
  close(c.rate(), 500.0 / c.adjusted_exposure())
  close(c.estimate().origins()[2].reserve, 240.0 * c.rate() * (1.0 - 1.0 / 1.8))
  assert_true(
    try {
      let _ = cape_cod(t, p, [0.0, 220.0, 240.0])
      false
    } catch {
      _ => true
    },
  )
}
