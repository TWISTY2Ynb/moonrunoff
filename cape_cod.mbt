///|
pub struct CapeCodResult {
  priv rate : Double
  priv adjusted_exposure : Double
  priv estimate : Estimate
}

///|
pub fn CapeCodResult::rate(self : CapeCodResult) -> Double {
  self.rate
}

///|
pub fn CapeCodResult::adjusted_exposure(self : CapeCodResult) -> Double {
  self.adjusted_exposure
}

///|
pub fn CapeCodResult::estimate(self : CapeCodResult) -> Estimate {
  self.estimate
}

///|
/// Exposures share one unit and must be positive. Rate is fitted to paid claims.
pub fn cape_cod(
  triangle : Triangle,
  pattern : Pattern,
  exposure : Array[Double],
) -> CapeCodResult raise RunoffError {
  compatible(triangle, pattern)
  validate_prior(exposure, triangle.order())
  let mut paid = 0.0
  let mut adjusted_exposure = 0.0
  for i in 0..<triangle.order() {
    if exposure[i] <= 0.0 {
      raise Value("exposure must be strictly positive")
    }
    let age = triangle.order() - i - 1
    paid = checked(paid + triangle.rows[i][age], "Cape Cod paid overflow")
    adjusted_exposure = checked(
      adjusted_exposure + exposure[i] / pattern.cdf[age],
      "adjusted exposure overflow",
    )
  }
  if adjusted_exposure <= 0.0 {
    raise Numerical("adjusted exposure underflow")
  }
  let rate = checked(paid / adjusted_exposure, "Cape Cod rate overflow")
  let prior : Array[Double] = []
  for x in exposure {
    prior.push(checked(x * rate, "Cape Cod prior overflow"))
  }
  let bf = bornhuetter_ferguson(triangle, pattern, prior)
  let estimate = from_ultimates(
    triangle,
    pattern,
    bf.origins.map(fn(r) { r.ultimate }),
    "cape-cod",
  )
  { rate, adjusted_exposure, estimate, }
}
