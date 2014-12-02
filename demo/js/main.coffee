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
    timeScale: 10000
    spaceScale: 200
  b1 = w.addBody 'b1', new Body(1, 1, pos: SE2(1, 1, 0)), 'M 0 25 L -25 -25 25 -25 Z'
  b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 Q 0 50 -100 0 Q 0 -50 100 0'
  # b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 L 0 50 -100 0 L 0 -50 100 0'
  w.forceFuncs.add b1, b2, spring(1, 1)
  w

TBS3 = ->
  w = new yaya '#main',
    timeScale: 10000
    spaceScale: 200
  b1 = w.addBody 'b1', new Body(1, 1, pos: SE2(1, 1, 0)), 'M 0 25 L -25 -25 25 -25 Z'
  b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 Q 0 50 -100 0 Q 0 -50 100 0'
  # b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 L 0 50 -100 0 L 0 -50 100 0'
  # w.forceFuncs.add b1, b2, spring(1, 1)

  window.p = SE2(1, 1, 0)
  b1.drive =
    type: 'pos'
    func: (t, dt) -> window.p

  w

# wok-potato test
WP0 = ->
  w = new yaya '#main',
    timeScale: 10000
    spaceScale: 200
  b0 = w.addBody 'b0', new Body(1000, 1000), 'M 150 -100 Q 0 50 -150 -100 H -180 V 25 H 180 V -100 Z'
  b1 = w.addBody 'b1', new Body(1, 1), 'M 10 -10 H -10 V 10 H 10 V -10'

  window.p = SE2(0, 1, 0)
  b1.drive =
    type: 'pos'
    func: (t, dt) -> window.p

  w

class Runner
  # cb: (t, dt) -> ...
  constructor: (@tMax, @cb) ->
    @reset()
  reset: ->
    @t = 0
    @running = false
  start: ->
    @running = true
    @msLast = null
    @next()
  pause: ->
    @running = false
  next: ->
    window.requestAnimationFrame @handler
  handler: (ms) =>
    if !@running || @t > @tMax
      @running = false
      return
    if !@msLast?
      @msLast = ms
      @next()
      return
    dt = ms - @msLast
    @msLast = ms
    @t += dt
    if @t > @tMax then return
    @cb @t, dt
    @next()
    return

runWorld = (w, duration) ->
  w.solver = Solver.verletFixed
  w._getAcc 0
  fps = 0
  a = 0.1
  r = new Runner duration, (t, dt) ->
    fps = (1-a)*fps + a*(1000/dt)
    $('#disp_fps').text fps.toFixed(0)
    $('#disp_time').text t.toFixed(0)
    w.update t
  $('#btn_start').on 'click', -> r.start()
  $('#btn_pause').on 'click', -> r.pause()
#  $('#btn_reset').on 'click', -> r.reset()

# window.w = TBS()
# window.w = TBS3()
window.w = WP0()
runWorld w, Infinity

bindings = new Keys.Bindings()
bindings.add a, new Keys.Combo Keys.Key[b] for [a, b] in [
  ['up', 'W']
  ['down', 'S']
  ['left', 'A']
  ['right', 'D']
  ['CCW', 'Q']
  ['CW', 'E']
  ['speedup', 'R']
  ['speeddown', 'F']
]

window.speed = 0.01
bindings.registerHandler a, b for [a, b] in [
  ['up', -> p.y += window.speed]
  ['down', -> p.y -= window.speed]
  ['left', -> p.x -= window.speed]
  ['right', -> p.x += window.speed]
  ['CCW', -> p.th += window.speed]
  ['CW', -> p.th -= window.speed]
  ['speedup', -> window.speed *= 1.5]
  ['speeddown', -> window.speed /= 1.5]
]