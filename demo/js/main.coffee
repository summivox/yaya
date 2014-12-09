N = numeric
{abs, sin, cos, atan2, sqrt, PI} = M = Math

{Force, SE2, Body, Solver} = yaya

svgEl = document.querySelector '#svg-main'


############
# forces and fields

spring = (k, d0) -> (t) ->
  v = @bodyN.frame.pos.minus @bodyP.frame.pos
  v.th = 0
  d = N.norm2([v.x, v.y])
  d = M.max d, 1e3*N.epsilon # overlapping bodies have no direction
  new Force v.scale(k*(1-d0/d))

uniformGravity = (g) -> (t, body, id) ->
  new Force 0, -g*body.m, 0

invSqrGravity = (G=6.67384e-11) -> (t) ->
  {x, y} = v = @bodyN.frame.pos.minus @bodyP.frame.pos
  v.th = 0
  d2 = N.norm2Squared([x, y])
  d = sqrt d2
  new Force v.scale(G*@bodyN.m*@bodyP.m/d2/d)
addInvSqrGravity = (world, bodies, G) ->
  l = bodies.length
  for i in [0...l-1] by 1
    for j in [i+1...l] by 1
      world.forceFuncs.add bodies[i], bodies[j], invSqrGravity(G)

drag = (dv, dw) -> (t, body, id) ->
  if !dw? then dw = dv
  {x, y, th} = body.frame.vel
  new Force -x*dv, -y*dv, -th*dw


############
# parametric path helpers

square = (l) -> "M #{l} -#{l} H -#{l} V #{l} H #{l} V -#{l}"
circle = ([cx, cy], r) ->
  """
    M #{cx+r} #{cy}
    a #{r} #{r} 0 0 1 #{-r} #{+r}
    a #{r} #{r} 0 0 1 #{-r} #{-r}
    a #{r} #{r} 0 0 1 #{+r} #{-r}
    a #{r} #{r} 0 0 1 #{+r} #{+r}
  """

worlds =
  TBS: ->
    w = new yaya svgEl,
      timeScale: 10000
      spaceScale: 200
    w.svg.attr('viewBox', '-100 -600 800 600')
    b1 = w.addBody 'b1', new Body(1, 1, pos: SE2(1, 1, 0)), 'M 0 25 L -25 -25 25 -25 Z'
    b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 Q 0 50 -100 0 Q 0 -50 100 0'
    # b2 = w.addBody 'b2', new Body(2, 1, pos: SE2(2, 3, 0)), 'M 100 0 L 0 50 -100 0 L 0 -50 100 0'
    w.forceFuncs.add b1, b2, spring(1, 1)
    w

  TBS3: ->
    w = new yaya svgEl,
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
  WP0: ->
    w = new yaya svgEl,
      timeScale: 10000
      spaceScale: 200
    b0 = w.addBody 'b0', new Body(1000, 1000), 'M 150 -100 Q 0 50 -150 -100 H -180 V 25 H 180 V -100 Z'
    b1 = w.addBody 'b1', new Body(1, 1), 'M 10 -10 H -10 V 10 H 10 V -10'

    window.p = SE2(0, 0.5, 0)
    b1.drive =
      type: 'pos'
      func: (t, dt) -> window.p

    w

  # wok-potato collision test
  WP1: (n = 15) ->
    w = new yaya svgEl,
      spaceScale: 200
      timeScale: 5000
      timestep:
        min: 1e-4
        max: 1e-1
      collision:
        tol: 1e-2
        iters: 10
        cor: 0.1
        posFix: 0.9
    w.svg.attr('viewBox', '-300 -300 600 400')
    wok = w.addBody 'wok', new Body(1000, 1000), 'M 150 -100 Q 0 100 -150 -100 H -180 V 25 H 180 V -100 Z'
    wok.drive =
      type: 'pos'
      func: (t, dt) ->
        ampX = 0.03
        ampY = 0.05
        phi = 2*PI*t/0.2
        SE2(ampX*M.cos(phi), ampY*M.sin(phi), 0)
    for i in [1..n]
      pos = new SE2(
        ((i-1)-(n-1)/2)/n*1.5
        M.random()*1.2 + .6
        M.random()*PI*2
      )
      w.addBody "potato#{i}", new Body(5, 0.1, pos: pos), square(Math.random()*0.5-0.5/2 + 10)
    w.fields.push uniformGravity 10
    w.fields.push drag 20, 20
    w

  # earth-moon
  earthMoon: (mEarth=5.97219e24, jEarth=8e37, mMoon=7.34767309e22, jMoon=6.6e34, d0=362600e3, v0=1.023e3) ->
    w = new yaya svgEl,
      spaceScale: 200/362600e3
      timeScale: 1000/(86400*7)
      timestep:
        min: 1
        max: Infinity
      collision:
        tol: 1e-3
        iters: 1
        cor: 0.00
        posFix: 0.0
    w.svg.attr('viewBox', '-400 -300 800 600')
    radius = 40
    earth = w.addBody 'earth', new Body(mEarth, jEarth), circle([0, 0], radius)
    moon = w.addBody 'moon', new Body(mMoon, jMoon, pos: SE2(d0, 0, 0), vel: SE2(0, v0, 0)), circle([0, 0], radius/3.67)
    w.forceFuncs.add earth, moon, invSqrGravity()
    w

  # three-body stable soln: figure 8
  figure8: ->
    w = new yaya svgEl,
      spaceScale: 200
      timeScale: 1000
      timestep:
        min: 1e-4
        max: 1e-3
      collision:
        tol: 1e-3
        iters: 1
        cor: 0.00
        posFix: 0.0
    w.svg.attr('viewBox', '-400 -300 800 600')

    pos1 = SE2(0.9700436, -0.24308753, 0)
    pos2 = pos1.neg()
    pos3 = SE2(0, 0, 0)
    vel1 = SE2(0.466203685, 0.43236573, 0)
    vel2 = vel1
    vel3 = vel1.scale(-2)

    radius = 18
    b1 = w.addBody 'b1', new Body(1, Infinity, pos: pos1, vel: vel1), circle([0, 0], radius)
    b2 = w.addBody 'b2', new Body(1, Infinity, pos: pos2, vel: vel2), circle([0, 0], radius)
    b3 = w.addBody 'b3', new Body(1, Infinity, pos: pos3, vel: vel3), circle([0, 0], radius)
    addInvSqrGravity w, [b1, b2, b3], 1
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
# window.w = WP0()
# window.w = WP1(15)

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

window.main = (name) ->
  window.w = worlds[name]()
  runWorld window.w, Infinity
