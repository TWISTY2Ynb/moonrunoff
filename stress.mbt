///|
pub(all) struct StressResult {
  name : String
  base_reserve : Double
  stressed_reserve : Double
  change : Double
  relative_change : Double?
} derive(Debug)

///|
pub extend StressResult with @debug.Debug::{to_repr}

///|
/// Multipliers apply to age-to-age factors (not reserves). Tail stays explicit.
pub fn stress_pattern(
  pattern : Pattern,
  multipliers : Array[Double],
  tail_multiplier~ : Double = 1.0,
) -> Pattern raise RunoffError {
  if multipliers.length() != pattern.factors.length() {
    raise Shape("stress factor count differs from pattern")
  }
  nonnegative(tail_multiplier, "tail multiplier must be finite and nonnegative")
  let xs : Array[Double] = []
  for i in 0..<multipliers.length() {
    nonnegative(
      multipliers[i],
      "stress multiplier must be finite and nonnegative",
    )
    xs.push(
      checked(pattern.factors[i] * multipliers[i], "stressed factor overflow"),
    )
  }
  Pattern::new(
    xs,
    tail=checked(pattern.tail * tail_multiplier, "stressed tail overflow"),
  )
}

///|
pub fn compare_stress(
  triangle : Triangle,
  base : Pattern,
  stressed : Pattern,
  name~ : String = "scenario",
) -> StressResult raise RunoffError {
  if name.length() == 0 || name.length() > 128 {
    raise Value("scenario name requires 1..128 code units")
  }
  let base_reserve = chain_ladder(triangle, base).total_reserve()
  let stressed_reserve = chain_ladder(triangle, stressed).total_reserve()
  let change = checked(
    stressed_reserve - base_reserve,
    "stress difference overflow",
  )
  {
    name,
    base_reserve,
    stressed_reserve,
    change,
    relative_change: if base_reserve == 0.0 {
      None
    } else {
      Some(checked(change / base_reserve, "stress relative change overflow"))
    },
  }
}

///|
/// One-at-a-time upward factor shocks, preserving the base pattern.
pub fn factor_sensitivity(
  triangle : Triangle,
  pattern : Pattern,
  shock~ : Double = 0.01,
) -> Array[StressResult] raise RunoffError {
  nonnegative(shock, "sensitivity shock must be finite nonnegative")
  let out : Array[StressResult] = []
  for age in 0..<pattern.factors.length() {
    let multipliers = Array::make(pattern.factors.length(), 1.0)
    multipliers[age] = checked(1.0 + shock, "sensitivity shock overflow")
    let stressed = stress_pattern(pattern, multipliers)
    out.push(compare_stress(triangle, pattern, stressed, name="age-\{age}"))
  }
  out
}
