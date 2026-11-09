///|
/// Explicit exclusions are (origin, development-age) pairs. Recent=0 uses all.
pub fn selected_factors(
  triangle : Triangle,
  average~ : Average = Volume,
  recent~ : Int32 = 0,
  excluded~ : Array[(Int32, Int32)] = [],
  overrides~ : Array[(Int32, Double)] = [],
) -> Array[FactorStat] raise RunoffError {
  let n = triangle.order()
  if recent < 0 || recent > n {
    raise Selection("recent window outside 0..order")
  }
  for k in 0..<excluded.length() {
    let (origin, age) = excluded[k]
    if age < 0 || age >= n - 1 || origin < 0 || origin >= n - age - 1 {
      raise Selection("excluded pair is not observed")
    }
    for j in 0..<k {
      if excluded[j] == excluded[k] {
        raise Selection("duplicate excluded pair")
      }
    }
  }
  for k in 0..<overrides.length() {
    let (age, factor) = overrides[k]
    if age < 0 || age >= n - 1 {
      raise Selection("override age outside pattern")
    }
    nonnegative(factor, "override must be finite")
    if factor < 1.0 {
      raise Selection("override factor must be at least one")
    }
    for j in 0..<k {
      if overrides[j].0 == age {
        raise Selection("duplicate override age")
      }
    }
  }
  let out : Array[FactorStat] = []
  for age in 0..<(n - 1) {
    let mut manual : Double? = None
    for pair in overrides {
      if pair.0 == age {
        manual = Some(pair.1)
      }
    }
    match manual {
      Some(factor) =>
        out.push({
          age,
          factor,
          pairs: 0,
          skipped_zero: 0,
          numerator: 0.0,
          denominator: 0.0,
        })
      None =>
        out.push(estimate_pair_column(triangle, age, average, excluded, recent))
    }
  }
  out
}
