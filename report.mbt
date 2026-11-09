///|
pub fn diagnostics_json(
  triangle : Triangle,
  pattern : Pattern,
) -> String raise RunoffError {
  let summary = fit_summary(triangle, pattern)
  let pairs : Array[Json] = []
  for row in pair_diagnostics(triangle, pattern) {
    pairs.push(
      Json::object({
        "origin": Json::Json(row.origin),
        "age": Json::Json(row.age),
        "base": Json::Json(row.base),
        "observed": Json::Json(row.observed),
        "expected": Json::Json(row.expected),
        "residual": Json::Json(row.residual),
        "ratio": Json::Json(row.ratio),
      }),
    )
  }
  Json::object({
    "schema": Json::string("moonrunoff/diagnostics/v1"),
    "pairs": Json::Json(pairs),
    "count": Json::Json(summary.pairs),
    "zero_bases": Json::Json(summary.zero_bases),
    "mae": Json::Json(summary.mean_absolute_residual),
    "rmse": Json::Json(summary.root_mean_square_residual),
    "maximum_absolute_residual": Json::Json(summary.maximum_absolute_residual),
  }).stringify()
}

///|
pub fn backtest_json(cells : Array[HoldoutCell]) -> String raise RunoffError {
  let score = backtest_score(cells)
  let rows : Array[Json] = []
  for cell in cells {
    rows.push(
      Json::object({
        "cutoff": Json::Json(cell.cutoff),
        "origin": Json::Json(cell.origin),
        "age": Json::Json(cell.age),
        "predicted": Json::Json(cell.predicted),
        "observed": Json::Json(cell.observed),
        "error": Json::Json(cell.error),
      }),
    )
  }
  Json::object({
    "schema": Json::string("moonrunoff/backtest/v1"),
    "cells": Json::Json(rows),
    "count": Json::Json(score.count),
    "bias": Json::Json(score.bias),
    "mae": Json::Json(score.mean_absolute_error),
    "rmse": Json::Json(score.root_mean_square_error),
    "wape": Json::Json(score.weighted_absolute_percentage_error),
  }).stringify()
}

///|
pub fn stress_json(results : Array[StressResult]) -> String raise RunoffError {
  if results.is_empty() || results.length() > 127 {
    raise Shape("stress report requires 1..127 scenarios")
  }
  let rows : Array[Json] = []
  for row in results {
    nonnegative(row.base_reserve, "base reserve must be finite nonnegative")
    nonnegative(
      row.stressed_reserve,
      "stressed reserve must be finite nonnegative",
    )
    let _ = checked(row.change, "stress change must be finite")
    match row.relative_change {
      Some(x) => {
        let _ = checked(x, "relative change must be finite")
      }
      None => ()
    }
    rows.push(
      Json::object({
        "name": Json::Json(row.name),
        "base_reserve": Json::Json(row.base_reserve),
        "stressed_reserve": Json::Json(row.stressed_reserve),
        "change": Json::Json(row.change),
        "relative_change": Json::Json(row.relative_change),
      }),
    )
  }
  Json::object({
    "schema": Json::string("moonrunoff/stress/v1"),
    "scenarios": Json::Json(rows),
  }).stringify()
}

///|
/// Coordinate CSV result, numeric-only cells safe for downstream CSV readers.
pub fn Estimate::to_csv(self : Estimate) -> String {
  let lines = ["origin,age,latest,ultimate,reserve"]
  for row in self.origins {
    lines.push(
      "\{row.origin},\{row.age},\{row.latest},\{row.ultimate},\{row.reserve}",
    )
  }
  lines.join("\n") + "\n"
}
