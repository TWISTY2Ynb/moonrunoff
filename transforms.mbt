///|
/// Construct from nonnegative incremental observations, checking accumulation.
pub fn Triangle::from_incremental(
  rows : Array[Array[Double]],
) -> Triangle raise RunoffError {
  let cumulative : Array[Array[Double]] = []
  for row in rows {
    let mut sum = 0.0
    let result : Array[Double] = []
    for x in row {
      nonnegative(x, "increments must be finite and nonnegative")
      sum = checked(sum + x, "increment accumulation overflow")
      result.push(sum)
    }
    cumulative.push(result)
  }
  Triangle::new(cumulative)
}

///|
/// Convert cumulative data to independent incremental rows.
pub fn Triangle::incremental(self : Triangle) -> Array[Array[Double]] {
  self.rows.map(fn(row) {
    let out : Array[Double] = []
    for j in 0..<row.length() {
      out.push(if j == 0 { row[j] } else { row[j] - row[j - 1] })
    }
    out
  })
}

///|
/// Historical valuation: retain only origin+age<=calendar. No future leakage.
pub fn Triangle::at_calendar(
  self : Triangle,
  calendar : Int32,
) -> Triangle raise RunoffError {
  if calendar < 1 || calendar >= self.order() {
    raise Shape("historical calendar must be 1..order-1")
  }
  let n = calendar + 1
  Triangle::new(
    Array::makei(n, fn(i) { Array::makei(n - i, fn(j) { self.rows[i][j] }) }),
  )
}

///|
/// Scale all observations. Zero is allowed; factor fitting may then fail.
pub fn Triangle::scale(
  self : Triangle,
  factor : Double,
) -> Triangle raise RunoffError {
  nonnegative(factor, "scale must be finite and nonnegative")
  let rows : Array[Array[Double]] = []
  for row in self.rows {
    let scaled : Array[Double] = []
    for x in row {
      scaled.push(checked(x * factor, "triangle scale overflow"))
    }
    rows.push(scaled)
  }
  Triangle::new(rows)
}

///|
/// Calendar-diagonal observed incremental sums, including early diagonals.
pub fn Triangle::calendar_totals(
  self : Triangle,
) -> Array[Double] raise RunoffError {
  let out = Array::make(self.order(), 0.0)
  for i, row in self.incremental() {
    for j, x in row {
      out[i + j] = checked(out[i + j] + x, "calendar total overflow")
    }
  }
  out
}

///|
/// Development-period observed incremental sums; each period has fewer origins.
pub fn Triangle::development_totals(
  self : Triangle,
) -> Array[Double] raise RunoffError {
  let out = Array::make(self.order(), 0.0)
  for row in self.incremental() {
    for j, x in row {
      out[j] = checked(out[j] + x, "development total overflow")
    }
  }
  out
}
