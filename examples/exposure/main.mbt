///|
fn main raise {
  let t = @runoff.Triangle::from_json("[[100,150,180],[120,180],[140]]")
  let p = @runoff.Pattern::fit(t)
  let prior = [200.0, 220.0, 240.0]
  let bf = @runoff.bornhuetter_ferguson(t, p, prior)
  let bk = @runoff.benktander(t, p, prior)
  let cc = @runoff.cape_cod(t, p, [1000.0, 1100.0, 1200.0])
  assert_true(bf.reconcile().balanced)
  assert_true(bk.reconcile().balanced)
  assert_true(cc.estimate().reconcile().balanced)
  println(bf.to_json())
  println(bk.to_json())
  println(cc.estimate().to_json())
}
