N = numeric
{abs, sin, cos, atan2, sqrt, PI} = M = Math

{Force, SE2, Body, Solver} = yaya

spring = (k, d0) -> (t) ->
  v = @bodyN.frame.pos.minus @bodyP.frame.pos
  v.th = 0
  d = N.norm2([v.x, v.y])
  d = M.max d, 1e3*N.epsilon # overlapping bodies have no direction
  new Force v.scale(k*(1-d0/d))

TBS = ->
  w = new yaya '#main',
    spaceScale: 200
  b1 = w.addBody 'b1', new Body(1, 1, pos: SE2(1, 1, 0)), 'M 0 50 L -25 0 25 0 Z'
  b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 Q 0 50 -100 0 Q 0 -50 100 0'
  w.forceFuncs.add b1, b2, spring(1, 1)
  w

runWorld = (w, duration) ->
  w.solver = Solver.verletFixed
  w._getAcc 0
  ms0 = null
  ms1 = null
  window.requestAnimationFrame handler = (ms) ->
    if !ms0?
      ms0 = ms
      ms1 = ms + duration
    console.log ms
    w.update ms
    if ms < ms1
      window.requestAnimationFrame handler


runWorld TBS(), 10000