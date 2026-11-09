///|
test "future cashflow reconciles both BF and chain-ladder with separate tail" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  let p = Pattern::new([1.5, 1.2], tail=1.1)
  for
    e in [chain_ladder(t, p), bornhuetter_ferguson(t, p, [200.0, 230.0, 260.0])] {
    let mut sum = 0.0
    let by_origin = Array::make(3, 0.0)
    for payment in e.payments() {
      assert_true(payment.calendar >= 3)
      assert_true(payment.amount >= 0.0)
      by_origin[payment.origin] += payment.amount
      sum += payment.amount
    }
    close(sum, e.total_reserve())
    for i in 0..<3 {
      close(by_origin[i], e.origins()[i].reserve)
    }
  }
}
