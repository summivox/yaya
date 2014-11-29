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
  b1 = w.addBody 'b1', new Body(1, 1, pos: SE2(1, 1, 0)), 'M 0 50 L -25 0 25 0 Z'
  b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 Q 0 50 -100 0 Q 0 -50 100 0'
  # b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 L 0 50 -100 0 L 0 -50 100 0'
  w.forceFuncs.add b1, b2, spring(1, 1)
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

window.w = TBS()
runWorld w, 100000