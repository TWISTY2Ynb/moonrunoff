///|
/// Immutable selected age-to-age factors and one final tail multiplier.
pub struct Pattern {
  priv factors : Array[Double]
  priv tail : Double
  priv cdf : Array[Double]
}

///|
pub fn Pattern::new(
  factors : Array[Double],
  tail~ : Double = 1.0,
) -> Pattern raise RunoffError {
  if factors.length() < 1 || factors.length() > 127 {
    raise Shape("pattern requires 1..127 factors")
  }
  nonnegative(tail, "tail must be finite")
  if tail < 1.0 {
    raise Value("tail must be at least one")
  }
  let cdf = Array::make(factors.length() + 1, tail)
  let mut age = factors.length() - 1
  while age >= 0 {
    nonnegative(factors[age], "factor must be finite")
    if factors[age] < 1.0 {
      raise Value("factor must be at least one")
    }
    cdf[age] = checked(
      cdf[age + 1] * factors[age],
      "cumulative factor overflow",
    )
    age = age - 1
  }
  { factors: factors.copy(), tail, cdf, }
}

///|
pub fn Pattern::fit(
  triangle : Triangle,
  average~ : Average = Volume,
  tail~ : Double = 1.0,
) -> Pattern raise RunoffError {
  Pattern::new(
    development_factors(triangle, average~).map(fn(s) { s.factor }),
    tail~,
  )
}

///|
pub fn Pattern::factors(self : Pattern) -> Array[Double] {
  self.factors.copy()
}

///|
pub fn Pattern::tail(self : Pattern) -> Double {
  self.tail
}

///|
pub fn Pattern::cumulative_factors(self : Pattern) -> Array[Double] {
  self.cdf.copy()
}

///|
pub fn Pattern::order(self : Pattern) -> Int32 {
  self.cdf.length()
}

///|
pub fn Pattern::reported_fraction(
  self : Pattern,
  age : Int32,
) -> Double raise RunoffError {
  if age < 0 || age >= self.order() {
    raise Shape("age outside pattern")
  }
  1.0 / self.cdf[age]
}
