///|
pub(all) struct PairDiagnostic {
  origin : Int32
  age : Int32
  base : Double
  observed : Double
  expected : Double
  residual : Double
  ratio : Double?
} derive(Debug)

///|
pub extend PairDiagnostic with @debug.Debug::{to_repr}

///|
/// Raw residuals are descriptive, not Mack standard errors.
pub fn pair_diagnostics(
  triangle : Triangle,
  pattern : Pattern,
) -> Array[PairDiagnostic] raise RunoffError {
  compatible(triangle, pattern)
  let out : Array[PairDiagnostic] = []
  for age in 0..<(triangle.order() - 1) {
    for origin in 0..<(triangle.order() - age - 1) {
      let base = triangle.rows[origin][age]
      let observed = triangle.rows[origin][age + 1]
      let expected = checked(
        base * pattern.factors[age],
        "diagnostic expected overflow",
      )
      let ratio = if base == 0.0 {
        None
      } else {
        Some(checked(observed / base, "diagnostic ratio overflow"))
      }
      out.push({
        origin,
        age,
        base,
        observed,
        expected,
        residual: observed - expected,
        ratio,
      })
    }
  }
  out
}

///|
pub(all) struct FitSummary {
  pairs : Int32
  zero_bases : Int32
  mean_absolute_residual : Double
  root_mean_square_residual : Double
  maximum_absolute_residual : Double
} derive(Debug)

///|
pub extend FitSummary with @debug.Debug::{to_repr}

///|
pub fn fit_summary(
  triangle : Triangle,
  pattern : Pattern,
) -> FitSummary raise RunoffError {
  let pairs = pair_diagnostics(triangle, pattern)
  let mut zero_bases = 0
  let mut absolute = 0.0
  let mut square = 0.0
  let mut maximum = 0.0
  for row in pairs {
    if row.base == 0.0 {
      zero_bases += 1
    }
    let a = row.residual.abs()
    absolute = checked(absolute + a, "absolute residual sum overflow")
    square = checked(
      square + checked(a * a, "squared residual overflow"),
      "residual square sum overflow",
    )
    if a > maximum {
      maximum = a
    }
  }
  let count = pairs.length().to_double()
  {
    pairs: pairs.length(),
    zero_bases,
    mean_absolute_residual: absolute / count,
    root_mean_square_residual: (square / count).sqrt(),
    maximum_absolute_residual: maximum,
  }
}
