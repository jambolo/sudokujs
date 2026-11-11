FontFaceObserver = require 'fontfaceobserver'

MenuView = require './MenuView'
SudokuView = require './SudokuView'

FONT_FAMILY = "saxMono, monospace"

class App
  constructor: (@canvas) ->
    @ctx = @canvas.getContext("2d")
    @views =
      menu: new MenuView(this, @canvas)
      sudoku: new SudokuView(this, @canvas)
    @view = @views.sudoku
    @resize()
    @loadFont("saxMono")

  # Sizes the canvas to its displayed size in device pixels and lays out the views
  resize: ->
    @pixelRatio = window.devicePixelRatio or 1
    @canvas.width = Math.round(@canvas.clientWidth * @pixelRatio)
    @canvas.height = Math.round(@canvas.clientHeight * @pixelRatio)

    @versionFontHeight = Math.floor(@canvas.height * 0.02)
    @versionFont = @font(@versionFontHeight)
    @generatingFont = @font(@canvas.height * 0.04)

    view.layout() for name, view of @views
    @draw()

  # Returns the canvas font for a height in pixels
  font: (height) ->
    return "#{Math.floor(height)}px #{FONT_FAMILY}"

  # Redraws when the font becomes available
  loadFont: (fontName) ->
    new FontFaceObserver(fontName).load().then (=> @draw()), ->
      console.log "Failed to load font #{fontName}"

  switchView: (view) ->
    @view = @views[view]
    @draw()

  newGame: (difficulty) ->
    # console.log "app.newGame(#{difficulty})"

    # @drawFill(0, 0, @canvas.width, @canvas.height, "#444444")
    # @drawTextCentered("Generating, please wait...", @canvas.width / 2, @canvas.height / 2, @generatingFont, "#ffffff")

    # window.setTimeout =>
    @views.sudoku.newGame(difficulty)
    @switchView("sudoku")
    # , 0

  reset: ->
    @views.sudoku.reset()
    @switchView("sudoku")

  import: (importString) ->
    return @views.sudoku.import(importString)

  export: ->
    return @views.sudoku.export()

  holeCount: ->
    return @views.sudoku.holeCount()

  draw: ->
    @view.draw()

  click: (x, y) ->
    @view.click(x, y)

  key: (k) ->
    @view.key?(k)

  drawFill: (x, y, w, h, color) ->
    @ctx.beginPath()
    @ctx.rect(x, y, w, h)
    @ctx.fillStyle = color
    @ctx.fill()

  drawRoundedRect: (x, y, w, h, r, fillColor = null, strokeColor = null, lineWidth = 1) ->
    @ctx.beginPath()
    @ctx.roundRect(x, y, w, h, Math.min(r, w / 2, h / 2))
    if fillColor != null
      @ctx.fillStyle = fillColor
      @ctx.fill()
    if strokeColor != null
      @ctx.strokeStyle = strokeColor
      @ctx.lineWidth = lineWidth
      @ctx.stroke()
    return

  drawRect: (x, y, w, h, color, lineWidth = 1) ->
    @ctx.beginPath()
    @ctx.strokeStyle = color
    @ctx.lineWidth = lineWidth
    @ctx.rect(x, y, w, h)
    @ctx.stroke()

  drawLine: (x1, y1, x2, y2, color = "black", lineWidth = 1) ->
    @ctx.beginPath()
    @ctx.strokeStyle = color
    @ctx.lineWidth = lineWidth
    @ctx.lineCap = "butt"
    @ctx.moveTo(x1, y1)
    @ctx.lineTo(x2, y2)
    @ctx.stroke()

  drawTextCentered: (text, cx, cy, font, color) ->
    @ctx.font = font
    @ctx.fillStyle = color
    @ctx.textAlign = "center"
    @ctx.textBaseline = "middle"
    @ctx.fillText(text, cx, cy)

  drawLowerLeft: (text, color = "white") ->
    @ctx.font = @versionFont
    @ctx.fillStyle = color
    @ctx.textAlign = "left"
    @ctx.textBaseline = "alphabetic"
    @ctx.fillText(text, 0, @canvas.height - (@versionFontHeight / 3))

  drawVersion: (color = "white") ->
    @ctx.font = @versionFont
    @ctx.fillStyle = color
    @ctx.textAlign = "right"
    @ctx.textBaseline = "alphabetic"
    @ctx.fillText("v#{VERSION}", @canvas.width - (@versionFontHeight / 3), @canvas.height - (@versionFontHeight / 3))

  drawArc: (x1, y1, x2, y2, radius, color, lineWidth) ->
    # Derived from https://github.com/jambolo/drawArc at 6c3e0d3

    P1 = { x: x1, y: y1 }
    P2 = { x: x2, y: y2 }

    # Determine the midpoint (M) from P1 to P2
    M =
      x: (P1.x + P2.x) / 2
      y: (P1.y + P2.y) / 2

    # Determine the distance from M to P1
    dMP1 = Math.sqrt((P1.x - M.x) * (P1.x - M.x) + (P1.y - M.y) * (P1.y - M.y))

    # Validate the radius
    if not radius? or radius < dMP1
      radius = dMP1

    # Determine the unit vector from M to P1
    uMP1 =
      x: (P1.x - M.x) / dMP1
      y: (P1.y - M.y) / dMP1

    # Determine the unit vector from M to Q (just uMP1 rotated pi/2)
    uMQ = { x: -uMP1.y, y: uMP1.x }

    # Determine the distance from the center of the circle (C) to M
    dCM = Math.sqrt(radius * radius - dMP1 * dMP1)

    # Determine the distance from M to Q
    dMQ = dMP1 * dMP1 / dCM

    # Determine the location of Q
    Q =
      x: M.x + uMQ.x * dMQ
      y: M.y + uMQ.y * dMQ

    @ctx.beginPath()
    @ctx.strokeStyle = color
    @ctx.lineWidth = lineWidth
    @ctx.lineCap = "round"
    @ctx.moveTo(x1, y1)
    @ctx.arcTo(Q.x, Q.y, x2, y2, radius)
    @ctx.stroke()
    return

  drawPoint: (x, y, r, color) ->
    @ctx.beginPath()
    @ctx.fillStyle = color
    @ctx.arc(x, y, r, 0, 2 * Math.PI)
    @ctx.fill()
    return

module.exports = App
