///|
fn integer_control(value : Json) -> Unit raise RunoffError {
  match value {
    Number(n, ..) => {
      if !finite(n) || n < 0.0 || n > 1000.0 {
        raise Parse("integer control outside 0..1000")
      }
      if n.to_int().to_double() != n {
        raise Parse("integer controls cannot be fractional")
      }
    }
    _ => raise Parse("integer control must be a number")
  }
}

///|
fn validate_integer_controls(
  fields : Map[String, Json],
) -> Unit raise RunoffError {
  for key in ["recent", "iterations"] {
    match fields.get(key) {
      Some(v) => integer_control(v)
      None => ()
    }
  }
  for key in ["excluded", "overrides"] {
    match fields.get(key) {
      None => ()
      Some(Array(pairs)) => {
        if pairs.length() > 8256 {
          raise Parse("too many selection controls")
        }
        for pair in pairs {
          match pair {
            Array(columns) => {
              if columns.length() != 2 {
                raise Parse("selection controls require pairs")
              }
              integer_control(columns[0])
              if key == "excluded" {
                integer_control(columns[1])
              }
            }
            _ => raise Parse("selection control must be a pair")
          }
        }
      }
      Some(_) => raise Parse("selection controls must be arrays")
    }
  }
}

///|
fn[T : @json.FromJson] field(
  fields : Map[String, Json],
  key : String,
) -> T raise RunoffError {
  match fields.get(key) {
    None => raise Parse("missing request field: " + key)
    Some(value) =>
      @json.from_json(value) catch {
        _ => raise Parse("invalid request field: " + key)
      }
  }
}

///|
fn[T : @json.FromJson] optional_field(
  fields : Map[String, Json],
  key : String,
  fallback : T,
) -> T raise RunoffError {
  if fields.contains(key) {
    field(fields, key)
  } else {
    fallback
  }
}

///|
fn request_average(fields : Map[String, Json]) -> Average raise RunoffError {
  let name : String = optional_field(fields, "average", "volume")
  match name {
    "volume" => Volume
    "simple" => Simple
    "regression" => Regression
    _ => raise Parse("average must be volume, simple or regression")
  }
}

///|
fn request_pattern(
  fields : Map[String, Json],
  triangle : Triangle,
  average : Average,
) -> Pattern raise RunoffError {
  let tail : Double = optional_field(fields, "tail", 1.0)
  match fields.get("factors") {
    Some(value) => {
      for key in ["recent", "excluded", "overrides"] {
        if fields.contains(key) {
          raise Parse("explicit factors cannot combine with selection controls")
        }
      }
      let factors : Array[Double] = @json.from_json(value) catch {
        _ => raise Parse("factors must be numeric array")
      }
      let p = Pattern::new(factors, tail~)
      compatible(triangle, p)
      p
    }
    None => {
      let recent : Int32 = optional_field(fields, "recent", 0)
      let excluded : Array[(Int32, Int32)] = optional_field(
        fields,
        "excluded",
        [],
      )
      let overrides : Array[(Int32, Double)] = optional_field(
        fields,
        "overrides",
        [],
      )
      let stats = selected_factors(
        triangle,
        average~,
        recent~,
        excluded~,
        overrides~,
      )
      Pattern::new(stats.map(fn(row) { row.factor }), tail~)
    }
  }
}

///|
/// Pure request engine shared by the CLI, WASM hosts and services.
/// Unknown fields and irrelevant model controls are errors, not silent fallbacks.
pub fn execute_request(text : String) -> String raise RunoffError {
  let fields = match parse_json_bounded(text) {
    Object(fields) => fields
    _ => raise Parse("request must be an object")
  }
  validate_integer_controls(fields)
  let action : String = optional_field(fields, "action", "reserve")
  let allowed = [
    "triangle", "incremental", "action", "average", "tail", "factors", "recent",
    "excluded", "overrides", "estimator", "prior", "exposure", "iterations", "shock",
  ]
  for (key, _) in fields {
    if !allowed.contains(key) {
      raise Parse("unknown request field: " + key)
    }
  }
  let rows : Array[Array[Double]] = field(fields, "triangle")
  let incremental : Bool = optional_field(fields, "incremental", false)
  let triangle = if incremental {
    Triangle::from_incremental(rows)
  } else {
    Triangle::new(rows)
  }
  let average = request_average(fields)
  if action == "backtest" {
    for
      key in [
        "factors", "tail", "recent", "excluded", "overrides", "estimator", "prior",
        "exposure", "iterations", "shock",
      ] {
      if fields.contains(key) {
        raise Parse(
          "backtest refits historical factors and rejects model controls",
        )
      }
    }
    return backtest_json(rolling_holdout(triangle, average~))
  }
  if action != "reserve" && action != "diagnostics" && action != "stress" {
    raise Parse("action must be reserve, diagnostics, backtest or stress")
  }
  if action != "reserve" {
    for key in ["estimator", "prior", "exposure", "iterations"] {
      if fields.contains(key) {
        raise Parse("model controls are only valid for reserve action")
      }
    }
  }
  if action != "stress" && fields.contains("shock") {
    raise Parse("shock is only valid for stress action")
  }
  let pattern = request_pattern(fields, triangle, average)
  if action == "diagnostics" {
    return diagnostics_json(triangle, pattern)
  }
  if action == "stress" {
    let shock : Double = optional_field(fields, "shock", 0.01)
    return stress_json(factor_sensitivity(triangle, pattern, shock~))
  }
  let estimator : String = optional_field(fields, "estimator", "chain-ladder")
  if estimator != "benktander" && fields.contains("iterations") {
    raise Parse("iterations only valid for Benktander")
  }
  if estimator != "cape-cod" && fields.contains("exposure") {
    raise Parse("exposure only valid for Cape Cod")
  }
  if estimator != "bornhuetter-ferguson" &&
    estimator != "benktander" &&
    fields.contains("prior") {
    raise Parse("prior only valid for BF or Benktander")
  }
  let estimate = match estimator {
    "chain-ladder" => chain_ladder(triangle, pattern)
    "bornhuetter-ferguson" =>
      bornhuetter_ferguson(triangle, pattern, field(fields, "prior"))
    "benktander" => {
      let iterations : Int32 = optional_field(fields, "iterations", 2)
      benktander(triangle, pattern, field(fields, "prior"), iterations~)
    }
    "cape-cod" =>
      cape_cod(triangle, pattern, field(fields, "exposure")).estimate()
    _ => raise Parse("unsupported estimator")
  }
  estimate.to_json()
}

///|
/// Error output remains valid JSON, even for quotes or non-ASCII messages.
pub fn execute_request_result(text : String) -> String {
  execute_request(text) catch {
    err =>
      Json::object({
        "schema": Json::string("moonrunoff/error/v1"),
        "error": Json::string(@debug.to_string(err)),
      }).stringify()
  }
}
