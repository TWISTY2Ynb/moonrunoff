///|
pub(all) struct Reconciliation {
  latest : Double
  ultimate : Double
  reserve : Double
  payment_total : Double
  calendar_total : Double
  maximum_origin_error : Double
  tolerance : Double
  balanced : Bool
} derive(Debug)

///|
pub extend Reconciliation with @debug.Debug::{to_repr}

///|
/// Independently sums all three result views with a scale-aware tolerance.
/// Overflow remains an error, even when relative tolerances are large.
pub fn Estimate::reconcile(
  self : Estimate,
  relative_tolerance~ : Double = 1.0e-10,
) -> Reconciliation raise RunoffError {
  nonnegative(
    relative_tolerance, "reconciliation tolerance must be finite nonnegative",
  )
  if relative_tolerance > 0.01 {
    raise Value("relative tolerance must not exceed 0.01")
  }
  let by_origin = Array::make(self.origins.length(), 0.0)
  let mut payment_total = 0.0
  for payment in self.payments() {
    nonnegative(payment.amount, "payment must be finite nonnegative")
    payment_total = checked(
      payment_total + payment.amount,
      "payment reconciliation overflow",
    )
    by_origin[payment.origin] = checked(
      by_origin[payment.origin] + payment.amount,
      "origin reconciliation overflow",
    )
  }
  let mut calendar_total = 0.0
  for amount in self.calendar_payments() {
    calendar_total = checked(
      calendar_total + amount,
      "calendar reconciliation overflow",
    )
  }
  let latest = self.total_latest()
  let ultimate = self.total_ultimate()
  let reserve = self.total_reserve()
  let tolerance = checked(
    relative_tolerance * (1.0 + reserve),
    "reconciliation tolerance overflow",
  )
  let mut maximum_origin_error = 0.0
  for row in self.origins {
    let error = (by_origin[row.origin] - row.reserve).abs()
    if error > maximum_origin_error {
      maximum_origin_error = error
    }
  }
  // Paid and reserve totals can have very different scales.
  let accounting_tolerance = checked(
    relative_tolerance * (1.0 + ultimate),
    "accounting tolerance overflow",
  )
  let balanced = (ultimate - latest - reserve).abs() <= accounting_tolerance &&
    (payment_total - reserve).abs() <= tolerance &&
    (calendar_total - reserve).abs() <= tolerance &&
    maximum_origin_error <= tolerance
  {
    latest,
    ultimate,
    reserve,
    payment_total,
    calendar_total,
    maximum_origin_error,
    tolerance,
    balanced,
  }
}

///|
/// Origin-level deterministic discounting. Rates are per calendar period,
/// beginning at the first future diagonal (calendar=triangle order).
pub fn Estimate::discounted_reserves(
  self : Estimate,
  forward_rates : Array[Double],
) -> Array[Double] raise RunoffError {
  let n = self.pattern.order()
  if forward_rates.length() != n {
    raise Shape(
      "discount curve requires order forward rates including tail horizon",
    )
  }
  let discounts : Array[Double] = []
  let mut discount = 1.0
  for rate in forward_rates {
    let _ = checked(rate, "forward rate must be finite")
    if rate <= -1.0 {
      raise Value("forward rates must exceed minus one")
    }
    discount = checked(discount / (1.0 + rate), "discount factor overflow")
    if discount == 0.0 {
      raise Numerical("discount factor underflow")
    }
    discounts.push(discount)
  }
  let out = Array::make(n, 0.0)
  for payment in self.payments() {
    let horizon = payment.calendar - n
    if horizon < 0 || horizon >= n {
      raise Numerical("payment horizon outside discount curve")
    }
    let discounted = checked(
      payment.amount * discounts[horizon],
      "discounted payment overflow",
    )
    out[payment.origin] = checked(
      out[payment.origin] + discounted,
      "discounted reserve overflow",
    )
  }
  out
}
