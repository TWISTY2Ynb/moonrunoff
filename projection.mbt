///|
/// Complete cumulative development table, preserving every observed value.
/// Includes an additional tail column only when tail>1.
pub fn Estimate::projected_cumulative(
  self : Estimate,
  triangle : Triangle,
) -> Array[Array[Double]] raise RunoffError {
  compatible(triangle, self.pattern)
  let out : Array[Array[Double]] = []
  for origin in 0..<triangle.order() {
    if triangle.rows[origin][triangle.order() - origin - 1] !=
      self.origins[origin].latest {
      raise Value("triangle latest differs from estimate")
    }
    let row = triangle.rows[origin].copy()
    let reserve = self.origins[origin].reserve
    let age = self.origins[origin].age
    let fraction = 1.0 / self.pattern.cdf[age]
    let remaining = 1.0 - fraction
    for next in (age + 1)..<triangle.order() {
      let amount = if remaining == 0.0 {
        0.0
      } else {
        checked(
          reserve * ((1.0 / self.pattern.cdf[next] - fraction) / remaining),
          "projected cumulative overflow",
        )
      }
      row.push(
        checked(self.origins[origin].latest + amount, "projected cell overflow"),
      )
    }
    if self.pattern.tail > 1.0 {
      row.push(self.origins[origin].ultimate)
    }
    // Ultimate is exact at the final development or tail column.
    row[row.length() - 1] = self.origins[origin].ultimate
    out.push(row)
  }
  out
}

///|
/// Add portfolios cell-wise before fitting. This does not average fitted factors.
pub fn Triangle::combine(
  self : Triangle,
  other : Triangle,
) -> Triangle raise RunoffError {
  if self.order() != other.order() {
    raise Shape("combined triangles must have matching geometry")
  }
  let rows : Array[Array[Double]] = []
  for i in 0..<self.order() {
    let row : Array[Double] = []
    for age in 0..<(self.order() - i) {
      row.push(
        checked(
          self.rows[i][age] + other.rows[i][age],
          "combined claims overflow",
        ),
      )
    }
    rows.push(row)
  }
  Triangle::new(rows)
}

///|
/// Restate all cumulative claims of an origin by a positive exposure/trend weight.
/// Factors must be refitted explicitly after restatement.
pub fn Triangle::restate(
  self : Triangle,
  weights : Array[Double],
) -> Triangle raise RunoffError {
  if weights.length() != self.order() {
    raise Shape("restatement weight count differs from order")
  }
  let rows : Array[Array[Double]] = []
  for i in 0..<self.order() {
    nonnegative(weights[i], "restatement weights must be finite nonnegative")
    let row : Array[Double] = []
    for value in self.rows[i] {
      row.push(checked(value * weights[i], "restated claims overflow"))
    }
    rows.push(row)
  }
  Triangle::new(rows)
}
