///|
#derive(Debug)
pub(all) struct Payment {
  origin : Int32
  age : Int32
  calendar : Int32
  amount : Double
  is_tail : Bool
}

///|
pub extend Payment with @debug.Debug::{to_repr}

///|
/// Allocates each method's reserve by remaining pattern weights.
/// Tail is a separate final period (age=order), not observed development.
pub fn Estimate::payments(self : Estimate) -> Array[Payment] raise RunoffError {
  let out : Array[Payment] = []
  let p = self.pattern
  for row in self.origins {
    let reported = 1.0 / p.cdf[row.age]
    let remaining = 1.0 - reported
    if remaining == 0.0 {
      if row.reserve != 0.0 {
        raise Numerical("nonzero reserve with fully reported pattern")
      }
      continue
    }
    let mut allocated = 0.0
    let mut previous = reported
    for age in (row.age + 1)..<p.order() {
      let fraction = 1.0 / p.cdf[age]
      let amount = checked(
        row.reserve * ((fraction - previous) / remaining),
        "payment overflow",
      )
      if amount < 0.0 {
        raise Numerical("negative payment weight")
      }
      allocated = checked(allocated + amount, "payment total overflow")
      out.push({
        origin: row.origin,
        age,
        calendar: row.origin + age,
        amount,
        is_tail: false,
      })
      previous = fraction
    }
    if p.tail > 1.0 {
      let amount = checked(
        row.reserve - allocated,
        "tail reconciliation overflow",
      )
      if amount < -1.0e-10 * (1.0 + row.reserve) {
        raise Numerical("payment rounding exceeds reserve")
      }
      out.push({
        origin: row.origin,
        age: p.order(),
        calendar: row.origin + p.order(),
        amount: if amount < 0.0 {
          0.0
        } else {
          amount
        },
        is_tail: true,
      })
    } else if out.length() > 0 {
      // Reconcile the last development payment to eliminate summation drift.
      let last = out.length() - 1
      let old = out[last]
      if old.origin == row.origin {
        let amount = old.amount + (row.reserve - allocated)
        if amount < 0.0 {
          raise Numerical("negative reconciled payment")
        }
        out[last] = { ..old, amount, }
      }
    }
  }
  out
}

///|
pub fn Estimate::calendar_payments(
  self : Estimate,
) -> Array[Double] raise RunoffError {
  let total = Array::make(self.pattern.order() * 2, 0.0)
  for p in self.payments() {
    total[p.calendar] = checked(
      total[p.calendar] + p.amount,
      "calendar payment overflow",
    )
  }
  total
}
