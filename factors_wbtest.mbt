///|
fn close(a : Double, b : Double) -> Unit raise {
  assert_true((a - b).abs() <= 1.0e-10 * (1.0 + b.abs()))
}

///|
test "paired factors distinguish volume simple and regression" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [200.0, 400.0], [120.0]])
  let volume = development_factors(t)
  close(volume[0].factor, 550.0 / 300.0)
  close(development_factors(t, average=Simple)[0].factor, 1.75)
  close(development_factors(t, average=Regression)[0].factor, 95000.0 / 50000.0)
  assert_eq(volume[0].pairs, 2)
  close(volume[1].factor, 1.2)
  assert_true(
    try {
      let _ = development_factors(Triangle::new([[0.0, 1.0], [2.0]]))
      false
    } catch {
      _ => true
    },
  )
}
