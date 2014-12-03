{World, Body, Boundary, Force, SE2, Solver} = require 'yaya-core'
{abs, sin, cos, atan2, sqrt, PI} = M = Math
N = require 'numeric'
RAD = 180/PI

_ = require 'lodash'
d3 = require './lib/d3.js'

# brfs
fs = require('fs')
FRAME_MARKER = fs.readFileSync 'res/frame-marker.svg'
NORMAL_MARKER = fs.readFileSync 'res/normal-marker.svg'
STYLE = fs.readFileSync 'res/style.css'

cdataify = (s) -> """<![CDATA[#{s}]]>"""


# note: omitting yaya-core default options
defaultOptions = {
  timeScale: 1000 # (1s) in simulated world <=> (timeScale ms) in real time
  frameMarker: true # mark the coordinate frame of every body
  showCollision: true # mark intersections of boundaries
}

module.exports = class Yaya extends World
  constructor: (svgEl, options = {}) ->
    if this not instanceof Yaya then return new Yaya svgEl, options

    @options = _.cloneDeep defaultOptions
    _.merge @options, options
    super @options
    @svg = d3.select(svgEl).classed('yaya', true)
    @realTime = null

    style = document.createElement('style')
    style.setAttribute('type', 'text/css')
    style.innerHTML = STYLE
    document.head.appendChild style

    if @options.frameMarker
      @svg.append('defs').html(FRAME_MARKER + NORMAL_MARKER)

  update: (realTime) ->
    if !@realTime?
      @realTime = realTime
    else
      # determine how long we need to run the simulation
      dtRem = (realTime - @realTime)/@options.timeScale
      @realTime = realTime

      # actually run the simulation
      #TODO: handle min timestep

      if @options.showCollision
        collPoints = []
        collList = null
        dtRem -= @step dtRem,
          collision: (cL) ->
            collList = cL
            for {contacts} in collList
              for {p, lNormal: [x, y]} in contacts
                collPoints.push {p, th: atan2(y, x)}

      while dtRem > 1e-5
        dtRem -= @step dtRem
        #TODO: min/max, observer

    # list bodies with key
    bodyList = []
    @bodies.forEach (body, key) ->
      bodyList.push {body, key}


    ############
    # draw bodies

    k = @options.spaceScale
    B = @svg.selectAll('.yaya-body').data(bodyList, ({key}) -> key)

    # removed/added bodies
    B.exit().remove()
    G = B.enter().append('g')
    G
      .attr 'class', 'yaya-body'
      .attr 'id', ({key}) -> 'yaya-body-' + key
    G
      .filter ({body}) -> body.boundary?
      .append 'path'
      .attr 'd', ({body}) -> body.boundary.pathStr
      .attr 'class', 'yaya-boundary'
    if @options.frameMarker
      G.append('use').attr('xlink:href', '#yaya-frame-marker')

    # update
    B.attr 'transform', ({body}) ->
      {x, y, th} = body.frame.pos
      x = x *  k
      y = y * -k
      th = -th*RAD
      "translate(#{x},#{y})rotate(#{th})"


    ############
    # showCollision

    if @options.showCollision && collPoints
      X = @svg.selectAll('.yaya-x').data(collPoints)
      X.exit().remove()
      X.enter().append('circle').attr('class', 'yaya-x').attr('r', 3)
      X
        .attr 'cx', ({p}) -> p[0] *  k
        .attr 'cy', ({p}) -> p[1] * -k
      normal = @svg.selectAll('.yaya-n').data(collPoints)
      normal.exit().remove()
      normal.enter().append('use').attr('class', 'yaya-n').attr('xlink:href', '#yaya-normal-marker')
      normal.attr 'transform', ({p: [x, y], th}) ->
        x = x *  k
        y = y * -k
        th = -th*RAD
        "translate(#{x},#{y})rotate(#{th})"


_.merge module.exports, {Body, Force, SE2, Solver}