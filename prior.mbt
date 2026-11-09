///|
fn validate_prior(prior : Array[Double], n : Int32) -> Unit raise RunoffError {
  if prior.length() != n {
    raise Shape("prior count differs from triangle order")
  }
  for x in prior {
    nonnegative(x, "priors must be finite and nonnegative")
  }
}

///|
/// Prior is expected ultimate, not premium. No fitted exposure assumptions.
pub fn bornhuetter_ferguson(
  triangle : Triangle,
  pattern : Pattern,
  prior : Array[Double],
) -> Estimate raise RunoffError {
  compatible(triangle, pattern)
  validate_prior(prior, triangle.order())
  let out : Array[Double] = []
  for i in 0..<triangle.order() {
    let age = triangle.order() - i - 1
    let reserve = checked(
      prior[i] * (1.0 - 1.0 / pattern.cdf[age]),
      "BF reserve overflow",
    )
    out.push(checked(triangle.rows[i][age] + reserve, "BF ultimate overflow"))
  }
  from_ultimates(triangle, pattern, out, "bornhuetter-ferguson")
}

///|
/// Conceptual iteration zero is the prior; the public API starts at one.
/// Each subsequent iteration feeds the previous ultimate into BF.
pub fn benktander(
  triangle : Triangle,
  pattern : Pattern,
  prior : Array[Double],
  iterations~ : Int32 = 2,
) -> Estimate raise RunoffError {
  compatible(triangle, pattern)
  validate_prior(prior, triangle.order())
  if iterations < 1 || iterations > 1000 {
    raise Value("Benktander iterations must be 1..1000")
  }
  let mut current = prior.copy()
  for _ in 0..<iterations {
    current = bornhuetter_ferguson(triangle, pattern, current).origins.map(fn(
      r,
    ) {
      r.ultimate
    })
  }
  from_ultimates(triangle, pattern, current, "benktander")
}
