///|
/// Error categories are stable; messages add context, never change behavior.
#derive(Debug)
pub(all) suberror RunoffError {
  Shape(String)
  Value(String)
  Selection(String)
  Numerical(String)
  Parse(String)
}

///|
pub extend RunoffError with @debug.Debug::{to_repr}

///|
/// An immutable-by-contract square cumulative paid-loss upper triangle.
pub struct Triangle {
  priv rows : Array[Array[Double]]
}

///|
fn finite(x : Double) -> Bool {
  x == x && x <= 1.7976931348623157e308 && x >= -1.7976931348623157e308
}

///|
fn checked(x : Double, context : String) -> Double raise RunoffError {
  if !finite(x) {
    raise Numerical(context)
  }
  x
}

///|
fn nonnegative(x : Double, context : String) -> Unit raise RunoffError {
  let _ = checked(x, context)
  if x < 0.0 {
    raise Value(context)
  }
}

///|
/// Construct from cumulative observations. Copies all nested arrays.
pub fn Triangle::new(rows : Array[Array[Double]]) -> Triangle raise RunoffError {
  let n = rows.length()
  if n < 2 || n > 128 {
    raise Shape("triangle order must be 2..128")
  }
  let copy : Array[Array[Double]] = []
  for i in 0..<n {
    if rows[i].length() != n - i {
      raise Shape("row length must equal order minus origin index")
    }
    let row : Array[Double] = []
    let mut previous = 0.0
    for x in rows[i] {
      nonnegative(x, "observations must be finite and nonnegative")
      if x < previous {
        raise Value("cumulative observations must not decrease")
      }
      previous = x
      row.push(x)
    }
    copy.push(row)
  }
  { rows: copy, }
}

///|
pub fn Triangle::order(self : Triangle) -> Int32 {
  self.rows.length()
}

///|
/// A defensive copy; modifying it cannot mutate this triangle.
pub fn Triangle::cumulative(self : Triangle) -> Array[Array[Double]] {
  self.rows.map(fn(row) { row.copy() })
}

///|
pub fn Triangle::latest(self : Triangle) -> Array[Double] {
  self.rows.map(fn(row) { row[row.length() - 1] })
}

///|
pub fn Triangle::observed_count(self : Triangle) -> Int32 {
  let n = self.order()
  n * (n + 1) / 2
}

///|
pub fn Triangle::at(
  self : Triangle,
  origin : Int32,
  age : Int32,
) -> Double raise RunoffError {
  if origin < 0 ||
    origin >= self.order() ||
    age < 0 ||
    age >= self.order() - origin {
    raise Shape("cell is outside observed triangle")
  }
  self.rows[origin][age]
}
