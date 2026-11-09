///|
pub(all) struct HoldoutCell {
  cutoff : Int32
  origin : Int32
  age : Int32
  predicted : Double
  observed : Double
  error : Double
} derive(Debug)

///|
pub extend HoldoutCell with @debug.Debug::{to_repr}

///|
/// Fit solely to calendar<=cutoff; predict the next observed diagonal.
/// New origins with no observation at cutoff are excluded.
pub fn holdout(
  triangle : Triangle,
  cutoff : Int32,
  average~ : Average = Volume,
) -> Array[HoldoutCell] raise RunoffError {
  if cutoff < 1 || cutoff >= triangle.order() - 1 {
    raise Shape("holdout cutoff must be 1..order-2")
  }
  let historical = triangle.at_calendar(cutoff)
  let fitted = development_factors(historical, average~)
  let out : Array[HoldoutCell] = []
  for origin in 1..<=cutoff {
    let age = cutoff - origin + 1
    let base = historical.rows[origin][age - 1]
    let predicted = checked(
      base * fitted[age - 1].factor,
      "holdout prediction overflow",
    )
    let observed = triangle.rows[origin][age]
    out.push({
      cutoff,
      origin,
      age,
      predicted,
      observed,
      error: predicted - observed,
    })
  }
  out
}

///|
pub fn rolling_holdout(
  triangle : Triangle,
  average~ : Average = Volume,
) -> Array[HoldoutCell] raise RunoffError {
  if triangle.order() < 3 {
    raise Shape("rolling holdout requires at least order three")
  }
  let out : Array[HoldoutCell] = []
  for cutoff in 1..<(triangle.order() - 1) {
    for cell in holdout(triangle, cutoff, average~) {
      out.push(cell)
    }
  }
  out
}

///|
pub(all) struct BacktestScore {
  count : Int32
  bias : Double
  mean_absolute_error : Double
  root_mean_square_error : Double
  weighted_absolute_percentage_error : Double?
} derive(Debug)

///|
pub extend BacktestScore with @debug.Debug::{to_repr}

///|
pub fn backtest_score(
  cells : Array[HoldoutCell],
) -> BacktestScore raise RunoffError {
  if cells.is_empty() {
    raise Shape("cannot score an empty holdout")
  }
  let mut bias = 0.0
  let mut absolute = 0.0
  let mut square = 0.0
  let mut observed = 0.0
  for c in cells {
    nonnegative(c.predicted, "holdout prediction must be finite nonnegative")
    nonnegative(c.observed, "holdout observed must be finite nonnegative")
    let err = checked(c.predicted - c.observed, "nonfinite holdout error")
    if c.error != err {
      raise Value("holdout error differs from prediction minus observation")
    }
    bias = checked(bias + err, "holdout bias overflow")
    absolute = checked(absolute + err.abs(), "holdout absolute error overflow")
    square = checked(
      square + checked(err * err, "holdout square overflow"),
      "holdout squares overflow",
    )
    nonnegative(c.observed, "holdout observed must be nonnegative")
    observed = checked(observed + c.observed, "holdout observed total overflow")
  }
  let count = cells.length().to_double()
  {
    count: cells.length(),
    bias: bias / count,
    mean_absolute_error: absolute / count,
    root_mean_square_error: (square / count).sqrt(),
    weighted_absolute_percentage_error: if observed == 0.0 {
      None
    } else {
      Some(checked(absolute / observed, "WAPE overflow"))
    },
  }
}
