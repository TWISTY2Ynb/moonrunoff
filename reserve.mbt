///|
#derive(Debug)
pub(all) struct OriginEstimate {
  origin : Int32
  age : Int32
  latest : Double
  ultimate : Double
  reserve : Double
}

///|
pub extend OriginEstimate with @debug.Debug::{to_repr}

///|
/// Full estimate carries the selected pattern for reproducible cash flows.
pub struct Estimate {
  priv origins : Array[OriginEstimate]
  priv pattern : Pattern
  priv estimator : String
}

///|
fn from_ultimates(
  triangle : Triangle,
  pattern : Pattern,
  ultimates : Array[Double],
  estimator : String,
) -> Estimate raise RunoffError {
  compatible(triangle, pattern)
  if ultimates.length() != triangle.order() {
    raise Shape("ultimate count differs from order")
  }
  let origins : Array[OriginEstimate] = []
  for i in 0..<triangle.order() {
    let age = triangle.order() - i - 1
    let latest = triangle.rows[i][age]
    let ultimate = checked(ultimates[i], "ultimate must be finite")
    if ultimate < latest {
      raise Numerical("ultimate below observed paid claims")
    }
    origins.push({
      origin: i,
      age,
      latest,
      ultimate,
      reserve: ultimate - latest,
    })
  }
  { origins, pattern, estimator, }
}

///|
pub fn chain_ladder(
  triangle : Triangle,
  pattern : Pattern,
) -> Estimate raise RunoffError {
  compatible(triangle, pattern)
  let out : Array[Double] = []
  for i in 0..<triangle.order() {
    let age = triangle.order() - i - 1
    out.push(
      checked(
        triangle.rows[i][age] * pattern.cdf[age],
        "chain-ladder ultimate overflow",
      ),
    )
  }
  from_ultimates(triangle, pattern, out, "chain-ladder")
}

///|
pub fn Estimate::origins(self : Estimate) -> Array[OriginEstimate] {
  self.origins.copy()
}

///|
pub fn Estimate::estimator(self : Estimate) -> String {
  self.estimator
}

///|
pub fn Estimate::total_latest(self : Estimate) -> Double raise RunoffError {
  let mut total = 0.0
  for row in self.origins {
    total = checked(total + row.latest, "latest total overflow")
  }
  total
}

///|
pub fn Estimate::total_ultimate(self : Estimate) -> Double raise RunoffError {
  let mut total = 0.0
  for row in self.origins {
    total = checked(total + row.ultimate, "ultimate total overflow")
  }
  total
}

///|
pub fn Estimate::total_reserve(self : Estimate) -> Double raise RunoffError {
  let mut total = 0.0
  for row in self.origins {
    total = checked(total + row.reserve, "reserve total overflow")
  }
  total
}

///|
fn compatible(triangle : Triangle, pattern : Pattern) -> Unit raise RunoffError {
  if triangle.order() != pattern.order() {
    raise Shape("pattern and triangle order differ")
  }
}

///|
pub fn Estimate::pattern(self : Estimate) -> Pattern {
  self.pattern
}
