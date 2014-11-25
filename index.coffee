{World, Body, Boundary, Force, SE2, Solver} = require 'yaya-core'
{abs, sin, cos, atan2, sqrt, PI} = M = Math
N = require 'numeric'
RAD = 180/PI

_ = require 'lodash'
d3 = require './lib/d3.js'

# brfs
fs = require('fs')
FRAME_MARKER = fs.readFileSync 'res/frame-marker.svg'
STYLE = """<![CDATA[#{fs.readFileSync 'res/style.css'}]]>"""

console.log STYLE


# note: omitting yaya-core default options
defaultOptions = {
  timeScale: 1000 # (1s) in simulated world <=> (timeScale ms) in real time
  frameMarker: true # mark the coordinate frame of every body
}

module.exports = class Yaya extends World
  constructor: (svgEl, options = {}) ->
    if this not instanceof Yaya then return new Yaya svgEl, options

    @options = _.cloneDeep defaultOptions
    _.merge @options, options
    super @options
    @svg = d3.select(svgEl)
    @realTime = null

    @svg.append('style').attr('type', 'text/css').html(STYLE)
    if @options.frameMarker
      @svg.append('defs').html(FRAME_MARKER)

  update: (realTime) ->
    if !@realTime?
      @realTime = realTime
    else
      # determine how long we need to run the simulation
      dtRem = (realTime - @realTime)/@options.timeScale
      @realTime = realTime

      # actually run the simulation
      #TODO: handle min timestep
      while abs(dtRem) > 1e-5
        dtRem -= @step dtRem
        #TODO: min/max, observer

    # list bodies with key
    bodyList = []
    @bodies.forEach (body, key) ->
      bodyList.push {body, key}


    ############
    # graphics

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
    B.attr 'transform', ({body}) =>
      {x, y, th} = body.frame.pos
      x = x *  @options.spaceScale
      y = y * -@options.spaceScale
      th = -th*RAD
      "translate(#{x},#{y})rotate(#{th})"

_.merge module.exports, {Body, Force, SE2, Solver}