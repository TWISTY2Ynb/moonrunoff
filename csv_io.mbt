///|
/// Strict numeric CSV: origin,age,value; no quoting, comments or missing cells.
/// Cell order is irrelevant, but duplicate coordinates are errors.
pub fn Triangle::from_csv(
  text : String,
  incremental~ : Bool = false,
) -> Triangle raise RunoffError {
  if text.length() > 1048576 {
    raise Parse("CSV input exceeds 1 Mi code units")
  }
  let lines = text.split("\n").to_array()
  if lines.is_empty() || lines[0].trim().to_owned() != "origin,age,value" {
    raise Parse("CSV header must be origin,age,value")
  }
  let cells : Array[(Int32, Int32, Double)] = []
  let mut order = 0
  for k in 1..<lines.length() {
    let line = lines[k].trim().to_owned()
    if line.is_empty() {
      if k == lines.length() - 1 {
        continue
      }
      raise Parse("blank line within CSV")
    }
    if cells.length() >= 8256 {
      raise Parse("CSV cell limit exceeded")
    }
    let columns = line.split(",").to_array()
    if columns.length() != 3 {
      raise Parse("CSV needs exactly three columns")
    }
    let coordinates : Array[Int32] = []
    for column in 0..<2 {
      let token = columns[column].trim().to_owned()
      if token.is_empty() {
        raise Parse("empty coordinate")
      }
      let mut value = 0
      for ch in token {
        if ch < '0' || ch > '9' {
          raise Parse("coordinate must be unsigned decimal integer")
        }
        value = value * 10 + (ch.to_int() - '0'.to_int())
        if value >= 128 {
          raise Parse("coordinate exceeds 127")
        }
      }
      coordinates.push(value)
    }
    let token = columns[2].trim().to_owned()
    let amount : Double = @json.from_json(parse_json_bounded(token)) catch {
      _ => raise Parse("value must be a finite JSON number")
    }
    nonnegative(amount, "CSV value must be nonnegative")
    let origin = coordinates[0]
    let age = coordinates[1]
    if origin + age + 1 > order {
      order = origin + age + 1
    }
    cells.push((origin, age, amount))
  }
  if order < 2 || order > 128 {
    raise Shape("CSV implied order must be 2..128")
  }
  let rows : Array[Array[Double]] = []
  let seen : Array[Array[Bool]] = []
  for i in 0..<order {
    rows.push(Array::make(order - i, 0.0))
    seen.push(Array::make(order - i, false))
  }
  for (origin, age, value) in cells {
    if seen[origin][age] {
      raise Parse("duplicate CSV coordinate")
    }
    seen[origin][age] = true
    rows[origin][age] = value
  }
  for row in seen {
    for present in row {
      if !present {
        raise Parse("missing CSV coordinate")
      }
    }
  }
  if incremental {
    Triangle::from_incremental(rows)
  } else {
    Triangle::new(rows)
  }
}

///|
pub fn Triangle::to_csv(self : Triangle, incremental~ : Bool = false) -> String {
  let lines = ["origin,age,value"]
  let rows = if incremental { self.incremental() } else { self.cumulative() }
  for origin in 0..<rows.length() {
    for age in 0..<rows[origin].length() {
      lines.push("\{origin},\{age},\{rows[origin][age]}")
    }
  }
  lines.join("\n") + "\n"
}
