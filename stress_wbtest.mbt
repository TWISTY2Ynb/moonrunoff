///|
test "factor and tail stresses preserve base and increase reserve" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  let p = Pattern::fit(t)
  let stressed = stress_pattern(p, [1.0, 1.1], tail_multiplier=1.05)
  assert_true(compare_stress(t, p, stressed).change > 0.0)
  close(p.factors()[1], 1.2)
  assert_eq(factor_sensitivity(t, p).length(), 2)
  assert_true(
    try {
      let _ = stress_pattern(p, [0.1, 1.0])
      false
    } catch {
      _ => true
    },
  )
}
