///|
fn parse_json_bounded(text : String) -> Json raise RunoffError {
  if text.length() > 1048576 {
    raise Parse("JSON input exceeds 1 Mi code units")
  }
  // Bound containers before parsing; RC1 deprecates the parser depth label.
  // Quotes and escaped quotes must not turn string contents into containers.
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  for ch in text {
    if quoted {
      if escaped {
        escaped = false
      } else if ch == '\\' {
        escaped = true
      } else if ch == '"' {
        quoted = false
      }
    } else if ch == '"' {
      quoted = true
    } else if ch == '[' || ch == '{' {
      depth += 1
      if depth > 16 {
        raise Parse("JSON nesting depth exceeds 16")
      }
    } else if ch == ']' || ch == '}' {
      depth -= 1
    }
  }
  @json.parse(text[:], reject_duplicate_keys=true) catch {
    _ => raise Parse("invalid JSON syntax, duplicate key or nesting depth")
  }
}

///|
fn json_rows(value : Json) -> Array[Array[Double]] raise RunoffError {
  let rows : Array[Array[Double]] = @json.from_json(value) catch {
    _ => raise Parse("triangle must contain numeric arrays")
  }
  rows
}

///|
/// Bare JSON array-of-arrays, without hidden origin labels or coercion.
pub fn Triangle::from_json(
  text : String,
  incremental~ : Bool = false,
) -> Triangle raise RunoffError {
  let rows = json_rows(parse_json_bounded(text))
  if incremental {
    Triangle::from_incremental(rows)
  } else {
    Triangle::new(rows)
  }
}

///|
pub fn Triangle::to_json(
  self : Triangle,
  incremental~ : Bool = false,
) -> String {
  let rows = if incremental { self.incremental() } else { self.cumulative() }
  Json::Json(rows).stringify()
}

///|
pub fn Pattern::to_json(self : Pattern) -> String {
  Json::object({
    "factors": Json::Json(self.factors),
    "tail": Json::Json(self.tail),
  }).stringify()
}

///|
pub fn Pattern::from_json(text : String) -> Pattern raise RunoffError {
  match parse_json_bounded(text) {
    Object(fields) => {
      if fields.length() != 2 {
        raise Parse("pattern requires exactly factors and tail")
      }
      let factors : Array[Double] = match fields.get("factors") {
        Some(v) =>
          @json.from_json(v) catch {
            _ => raise Parse("factors must be a number array")
          }
        None => raise Parse("missing factors")
      }
      let tail : Double = match fields.get("tail") {
        Some(v) =>
          @json.from_json(v) catch {
            _ => raise Parse("tail must be numeric")
          }
        None => raise Parse("missing tail")
      }
      Pattern::new(factors, tail~)
    }
    _ => raise Parse("pattern must be a JSON object")
  }
}

///|
/// Versioned result schema uses zero-based origins, ages and calendars.
pub fn Estimate::to_json(self : Estimate) -> String raise RunoffError {
  let rows : Array[Json] = []
  for row in self.origins {
    rows.push(
      Json::object({
        "origin": Json::Json(row.origin),
        "age": Json::Json(row.age),
        "latest": Json::Json(row.latest),
        "ultimate": Json::Json(row.ultimate),
        "reserve": Json::Json(row.reserve),
      }),
    )
  }
  let payments : Array[Json] = []
  for row in self.payments() {
    payments.push(
      Json::object({
        "origin": Json::Json(row.origin),
        "age": Json::Json(row.age),
        "calendar": Json::Json(row.calendar),
        "amount": Json::Json(row.amount),
        "is_tail": Json::Json(row.is_tail),
      }),
    )
  }
  Json::object({
    "schema": Json::Json("moonrunoff/v1"),
    "estimator": Json::Json(self.estimator),
    "origins": Json::Json(rows),
    "payments": Json::Json(payments),
    "total_latest": Json::Json(self.total_latest()),
    "total_ultimate": Json::Json(self.total_ultimate()),
    "total_reserve": Json::Json(self.total_reserve()),
  }).stringify()
}
