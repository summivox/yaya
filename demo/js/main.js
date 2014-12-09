// Generated by CoffeeScript 1.7.1
(function() {
  var Body, Force, M, N, PI, Runner, SE2, Solver, a, abs, addInvSqrGravity, atan2, b, bindings, circle, cos, drag, invSqrGravity, runWorld, sin, spring, sqrt, square, svgEl, uniformGravity, worlds, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3, _ref4,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  N = numeric;

  _ref = M = Math, abs = _ref.abs, sin = _ref.sin, cos = _ref.cos, atan2 = _ref.atan2, sqrt = _ref.sqrt, PI = _ref.PI;

  Force = yaya.Force, SE2 = yaya.SE2, Body = yaya.Body, Solver = yaya.Solver;

  svgEl = document.querySelector('#svg-main');

  spring = function(k, d0) {
    return function(t) {
      var d, v;
      v = this.bodyN.frame.pos.minus(this.bodyP.frame.pos);
      v.th = 0;
      d = N.norm2([v.x, v.y]);
      d = M.max(d, 1e3 * N.epsilon);
      return new Force(v.scale(k * (1 - d0 / d)));
    };
  };

  uniformGravity = function(g) {
    return function(t, body, id) {
      return new Force(0, -g * body.m, 0);
    };
  };

  invSqrGravity = function(G) {
    if (G == null) {
      G = 6.67384e-11;
    }
    return function(t) {
      var d, d2, v, x, y, _ref1;
      _ref1 = v = this.bodyN.frame.pos.minus(this.bodyP.frame.pos), x = _ref1.x, y = _ref1.y;
      v.th = 0;
      d2 = N.norm2Squared([x, y]);
      d = sqrt(d2);
      return new Force(v.scale(G * this.bodyN.m * this.bodyP.m / d2 / d));
    };
  };

  addInvSqrGravity = function(world, bodies, G) {
    var i, j, l, _i, _ref1, _results;
    l = bodies.length;
    _results = [];
    for (i = _i = 0, _ref1 = l - 1; _i < _ref1; i = _i += 1) {
      _results.push((function() {
        var _j, _ref2, _results1;
        _results1 = [];
        for (j = _j = _ref2 = i + 1; _j < l; j = _j += 1) {
          _results1.push(world.forceFuncs.add(bodies[i], bodies[j], invSqrGravity(G)));
        }
        return _results1;
      })());
    }
    return _results;
  };

  drag = function(dv, dw) {
    return function(t, body, id) {
      var th, x, y, _ref1;
      if (dw == null) {
        dw = dv;
      }
      _ref1 = body.frame.vel, x = _ref1.x, y = _ref1.y, th = _ref1.th;
      return new Force(-x * dv, -y * dv, -th * dw);
    };
  };

  square = function(l) {
    return "M " + l + " -" + l + " H -" + l + " V " + l + " H " + l + " V -" + l;
  };

  circle = function(_arg, r) {
    var cx, cy;
    cx = _arg[0], cy = _arg[1];
    return "M " + (cx + r) + " " + cy + "\na " + r + " " + r + " 0 0 1 " + (-r) + " " + (+r) + "\na " + r + " " + r + " 0 0 1 " + (-r) + " " + (-r) + "\na " + r + " " + r + " 0 0 1 " + (+r) + " " + (-r) + "\na " + r + " " + r + " 0 0 1 " + (+r) + " " + (+r);
  };

  worlds = {
    TBS: function() {
      var b1, b2, w;
      w = new yaya(svgEl, {
        timeScale: 10000,
        spaceScale: 200
      });
      w.svg.attr('viewBox', '-100 -600 800 600');
      b1 = w.addBody('b1', new Body(1, 1, {
        pos: SE2(1, 1, 0)
      }), 'M 0 25 L -25 -25 25 -25 Z');
      b2 = w.addBody('b2', new Body(2, 1, {
        pos: SE2(2, 3, 0)
      }), 'M 100 0 Q 0 50 -100 0 Q 0 -50 100 0');
      w.forceFuncs.add(b1, b2, spring(1, 1));
      return w;
    },
    TBS3: function() {
      var b1, b2, w;
      w = new yaya(svgEl, {
        timeScale: 10000,
        spaceScale: 200
      });
      b1 = w.addBody('b1', new Body(1, 1, {
        pos: SE2(1, 1, 0)
      }), 'M 0 25 L -25 -25 25 -25 Z');
      b2 = w.addBody('b2', new Body(2, 1, {
        pos: SE2(2, 3, 0)
      }), 'M 100 0 Q 0 50 -100 0 Q 0 -50 100 0');
      window.p = SE2(1, 1, 0);
      b1.drive = {
        type: 'pos',
        func: function(t, dt) {
          return window.p;
        }
      };
      return w;
    },
    WP0: function() {
      var b0, b1, w;
      w = new yaya(svgEl, {
        timeScale: 10000,
        spaceScale: 200
      });
      b0 = w.addBody('b0', new Body(1000, 1000), 'M 150 -100 Q 0 50 -150 -100 H -180 V 25 H 180 V -100 Z');
      b1 = w.addBody('b1', new Body(1, 1), 'M 10 -10 H -10 V 10 H 10 V -10');
      window.p = SE2(0, 0.5, 0);
      b1.drive = {
        type: 'pos',
        func: function(t, dt) {
          return window.p;
        }
      };
      return w;
    },
    WP1: function(n) {
      var i, pos, w, wok, _i;
      if (n == null) {
        n = 15;
      }
      w = new yaya(svgEl, {
        spaceScale: 200,
        timeScale: 5000,
        timestep: {
          min: 1e-4,
          max: 1e-1
        },
        collision: {
          tol: 1e-2,
          iters: 10,
          cor: 0.1,
          posFix: 0.9
        }
      });
      w.svg.attr('viewBox', '-300 -300 600 400');
      wok = w.addBody('wok', new Body(1000, 1000), 'M 150 -100 Q 0 100 -150 -100 H -180 V 25 H 180 V -100 Z');
      wok.drive = {
        type: 'pos',
        func: function(t, dt) {
          var ampX, ampY, phi;
          ampX = 0.03;
          ampY = 0.05;
          phi = 2 * PI * t / 0.2;
          return SE2(ampX * M.cos(phi), ampY * M.sin(phi), 0);
        }
      };
      for (i = _i = 1; 1 <= n ? _i <= n : _i >= n; i = 1 <= n ? ++_i : --_i) {
        pos = new SE2(((i - 1) - (n - 1) / 2) / n * 1.5, M.random() * 1.2 + .6, M.random() * PI * 2);
        w.addBody("potato" + i, new Body(5, 0.1, {
          pos: pos
        }), square(Math.random() * 0.5 - 0.5 / 2 + 10));
      }
      w.fields.push(uniformGravity(10));
      w.fields.push(drag(20, 20));
      return w;
    },
    earthMoon: function(mEarth, jEarth, mMoon, jMoon, d0, v0) {
      var earth, moon, radius, w;
      if (mEarth == null) {
        mEarth = 5.97219e24;
      }
      if (jEarth == null) {
        jEarth = 8e37;
      }
      if (mMoon == null) {
        mMoon = 7.34767309e22;
      }
      if (jMoon == null) {
        jMoon = 6.6e34;
      }
      if (d0 == null) {
        d0 = 362600e3;
      }
      if (v0 == null) {
        v0 = 1.023e3;
      }
      w = new yaya(svgEl, {
        spaceScale: 200 / 362600e3,
        timeScale: 1000 / (86400 * 7),
        timestep: {
          min: 1,
          max: Infinity
        },
        collision: {
          tol: 1e-3,
          iters: 1,
          cor: 0.00,
          posFix: 0.0
        }
      });
      w.svg.attr('viewBox', '-400 -300 800 600');
      radius = 40;
      earth = w.addBody('earth', new Body(mEarth, jEarth), circle([0, 0], radius));
      moon = w.addBody('moon', new Body(mMoon, jMoon, {
        pos: SE2(d0, 0, 0),
        vel: SE2(0, v0, 0)
      }), circle([0, 0], radius / 3.67));
      w.forceFuncs.add(earth, moon, invSqrGravity());
      return w;
    },
    figure8: function() {
      var b1, b2, b3, pos1, pos2, pos3, radius, vel1, vel2, vel3, w;
      w = new yaya(svgEl, {
        spaceScale: 200,
        timeScale: 1000,
        timestep: {
          min: 1e-4,
          max: 1e-3
        },
        collision: {
          tol: 1e-3,
          iters: 1,
          cor: 0.00,
          posFix: 0.0
        }
      });
      w.svg.attr('viewBox', '-400 -300 800 600');
      pos1 = SE2(0.9700436, -0.24308753, 0);
      pos2 = pos1.neg();
      pos3 = SE2(0, 0, 0);
      vel1 = SE2(0.466203685, 0.43236573, 0);
      vel2 = vel1;
      vel3 = vel1.scale(-2);
      radius = 18;
      b1 = w.addBody('b1', new Body(1, Infinity, {
        pos: pos1,
        vel: vel1
      }), circle([0, 0], radius));
      b2 = w.addBody('b2', new Body(1, Infinity, {
        pos: pos2,
        vel: vel2
      }), circle([0, 0], radius));
      b3 = w.addBody('b3', new Body(1, Infinity, {
        pos: pos3,
        vel: vel3
      }), circle([0, 0], radius));
      addInvSqrGravity(w, [b1, b2, b3], 1);
      return w;
    }
  };

  Runner = (function() {
    function Runner(tMax, cb) {
      this.tMax = tMax;
      this.cb = cb;
      this.handler = __bind(this.handler, this);
      this.reset();
    }

    Runner.prototype.reset = function() {
      this.t = 0;
      return this.running = false;
    };

    Runner.prototype.start = function() {
      this.running = true;
      this.msLast = null;
      return this.next();
    };

    Runner.prototype.pause = function() {
      return this.running = false;
    };

    Runner.prototype.next = function() {
      return window.requestAnimationFrame(this.handler);
    };

    Runner.prototype.handler = function(ms) {
      var dt;
      if (!this.running || this.t > this.tMax) {
        this.running = false;
        return;
      }
      if (this.msLast == null) {
        this.msLast = ms;
        this.next();
        return;
      }
      dt = ms - this.msLast;
      this.msLast = ms;
      this.t += dt;
      if (this.t > this.tMax) {
        return;
      }
      this.cb(this.t, dt);
      this.next();
    };

    return Runner;

  })();

  runWorld = function(w, duration) {
    var a, fps, r;
    w.solver = Solver.verletFixed;
    w._getAcc(0);
    fps = 0;
    a = 0.1;
    r = new Runner(duration, function(t, dt) {
      fps = (1 - a) * fps + a * (1000 / dt);
      $('#disp_fps').text(fps.toFixed(0));
      $('#disp_time').text(t.toFixed(0));
      return w.update(t);
    });
    $('#btn_start').on('click', function() {
      return r.start();
    });
    return $('#btn_pause').on('click', function() {
      return r.pause();
    });
  };

  bindings = new Keys.Bindings();

  _ref1 = [['up', 'W'], ['down', 'S'], ['left', 'A'], ['right', 'D'], ['CCW', 'Q'], ['CW', 'E'], ['speedup', 'R'], ['speeddown', 'F']];
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    _ref2 = _ref1[_i], a = _ref2[0], b = _ref2[1];
    bindings.add(a, new Keys.Combo(Keys.Key[b]));
  }

  window.speed = 0.01;

  _ref3 = [
    [
      'up', function() {
        return p.y += window.speed;
      }
    ], [
      'down', function() {
        return p.y -= window.speed;
      }
    ], [
      'left', function() {
        return p.x -= window.speed;
      }
    ], [
      'right', function() {
        return p.x += window.speed;
      }
    ], [
      'CCW', function() {
        return p.th += window.speed;
      }
    ], [
      'CW', function() {
        return p.th -= window.speed;
      }
    ], [
      'speedup', function() {
        return window.speed *= 1.5;
      }
    ], [
      'speeddown', function() {
        return window.speed /= 1.5;
      }
    ]
  ];
  for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
    _ref4 = _ref3[_j], a = _ref4[0], b = _ref4[1];
    bindings.registerHandler(a, b);
  }

  window.main = function(name) {
    window.w = worlds[name]();
    return runWorld(window.w, Infinity);
  };

}).call(this);
