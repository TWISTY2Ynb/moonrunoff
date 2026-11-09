///|
fn main raise {
  let t = @runoff.Triangle::from_csv(
    "origin,age,value\n0,0,100\n0,1,150\n0,2,180\n1,0,120\n1,1,180\n2,0,140\n",
  )
  let p = @runoff.Pattern::fit(t)
  let e = @runoff.chain_ladder(t, p)
  assert_eq(e.total_reserve(), 148.0)
  assert_true(e.reconcile().balanced)
  println(e.to_json())
}
