///|
test "full projections preserve observations and reconcile method ultimates" {
  let t = Triangle::new([[100.0, 150.0, 180.0], [120.0, 180.0], [140.0]])
  let p = Pattern::new([1.5, 1.2], tail=1.1)
  let e = bornhuetter_ferguson(t, p, [200.0, 220.0, 260.0])
  let full = e.projected_cumulative(t)
  for i in 0..<3 {
    for age in 0..<(3 - i) {
      close(full[i][age], t.at(i, age))
    }
    close(full[i][3], e.origins()[i].ultimate)
  }
  close(t.combine(t).at(0, 2), 360.0)
  close(t.restate([1.0, 2.0, 3.0]).at(2, 0), 420.0)
}
