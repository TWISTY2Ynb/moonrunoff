///|
/// Three classical paired-observation estimators, without automatic trimming.
pub(all) enum Average {
  Volume
  Simple
  Regression
} derive(Eq, Debug)

///|
pub extend Average with @debug.Debug::{to_repr}

///|
/// One development period's transparent fitted statistics.
pub(all) struct FactorStat {
  age : Int32
  factor : Double
  pairs : Int32
  skipped_zero : Int32
  numerator : Double
  denominator : Double
} derive(Debug)

///|
pub extend FactorStat with @debug.Debug::{to_repr}

///|
fn estimate_pair_column(
  triangle : Triangle,
  age : Int32,
  average : Average,
  excluded : Array[(Int32, Int32)],
  recent : Int32,
) -> FactorStat raise RunoffError {
  let n = triangle.order()
  let mut numerator = 0.0
  let mut denominator = 0.0
  let mut pairs = 0
  let mut skipped_zero = 0
  let mut start = 0
  if recent > 0 && n - age - 1 > recent {
    start = n - age - 1 - recent
  }
  for i in start..<(n - age - 1) {
    if excluded.contains((i, age)) {
      continue
    }
    let x = triangle.rows[i][age]
    let y = triangle.rows[i][age + 1]
    if x == 0.0 {
      skipped_zero = skipped_zero + 1
      continue
    }
    let (top, bottom) = match average {
      Volume => (y, x)
      Simple => (checked(y / x, "individual ratio overflow"), 1.0)
      Regression =>
        (
          checked(x * y, "regression product overflow"),
          checked(x * x, "regression square overflow"),
        )
    }
    numerator = checked(numerator + top, "factor numerator overflow")
    denominator = checked(denominator + bottom, "factor denominator overflow")
    pairs = pairs + 1
  }
  if pairs == 0 || denominator <= 0.0 {
    raise Selection("no usable positive-base pair for development period")
  }
  let factor = checked(numerator / denominator, "factor division overflow")
  if factor < 1.0 {
    raise Numerical("development factor below one")
  }
  { age, factor, pairs, skipped_zero, numerator, denominator, }
}

///|
/// Fit all observed development periods using all available pairs.
pub fn development_factors(
  triangle : Triangle,
  average~ : Average = Volume,
) -> Array[FactorStat] raise RunoffError {
  let out : Array[FactorStat] = []
  for age in 0..<(triangle.order() - 1) {
    out.push(estimate_pair_column(triangle, age, average, [], 0))
  }
  out
}

///|
pub extend Average with Eq::{not_equal, equal}
