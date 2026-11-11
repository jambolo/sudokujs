{ test, beforeEach, mock } = require 'node:test'
assert = require 'node:assert/strict'
SudokuView = require '../game/src/SudokuView'
MenuView = require '../game/src/MenuView'
{ installStorage, quietly, PUZZLE, solutionAt } = require './helpers'

CELL = 100

# Minimal stand-in for App that counts draw calls
class FakeApp
  constructor: ->
    @pixelRatio = 1
    @drawCount = 0
    @switched = []
    @view = null

  font: (height) -> "#{Math.floor(height)}px test"
  switchView: (name) -> @switched.push(name)
  newGame: (difficulty) -> @switched.push("new #{difficulty}")
  holeCount: -> 0
  drawFill: -> @drawCount += 1
  drawRect: ->
  drawRoundedRect: ->
  drawLine: ->
  drawTextCentered: ->
  drawLowerLeft: ->
  drawVersion: ->
  drawArc: ->
  drawPoint: ->

# Returns a view of the test puzzle
newView = ->
  app = new FakeApp
  view = quietly -> new SudokuView(app, { width: 9 * CELL, height: 14 * CELL })
  view.layout()
  app.view = view
  assert.equal(view.import(PUZZLE), true)
  return view

# Clicks the center of a cell
clickCell = (view, x, y) ->
  view.click((x + 0.5) * CELL, (y + 0.5) * CELL)

# Selects a pen value from the pen pad
selectPen = (view, v) ->
  clickCell(view, 1 + ((v - 1) % 3), 10 + ((v - 1) // 3))

# Fills every hole but (2,0) with its solution, then selects the pen for (2,0)
almostSolve = (view) ->
  for y in [0...9]
    for x in [0...9]
      continue if view.game.grid[x][y].locked or (x == 2 and y == 0)
      view.game.setValue(x, y, solutionAt(x, y))
  selectPen(view, 4)

# Runs the timers until any celebration is over
finishTimers = ->
  mock.timers.tick(50) for i in [0...100]
  return

beforeEach ->
  installStorage()
  mock.timers.reset()
  mock.timers.enable({ apis: ['setTimeout', 'Date'] })
  globalThis.requestAnimationFrame = (f) -> setTimeout(f, 16)
  globalThis.cancelAnimationFrame = (id) -> clearTimeout(id)

test 'layout follows the canvas size', ->
  view = newView()
  assert.equal(view.cellSize, CELL)
  view.canvas.width = 450
  view.layout()
  assert.equal(view.cellSize, 50)
  view.draw()

test 'pen and pencil entry', ->
  view = newView()
  selectPen(view, 4)
  clickCell(view, 2, 0)
  assert.equal(view.game.grid[2][0].value, 4)
  clickCell(view, 0, 13)                              # undo
  assert.equal(view.game.grid[2][0].value, 0)
  clickCell(view, 5, 10)                              # pencil 1
  clickCell(view, 2, 0)
  assert.deepEqual(view.game.pencilMarks(2, 0), [1])
  assert.equal(view.preferPencil, true)

test 'keys follow the mode label', ->
  view = newView()
  clickCell(view, 8, 9)                               # check
  clickCell(view, 2, 0)
  clickCell(view, 4, 9)                               # mode label: check -> pencil
  assert.equal(view.preferPencil, true)
  view.key('3')
  assert.equal(view.penValue, 3)
  view.key('.')
  assert.equal(view.preferPencil, false)
  clickCell(view, 2, 0)
  assert.equal(view.game.grid[2][0].value, 3)

test 'celebrates each time the puzzle becomes solved, but not on load', ->
  view = newView()
  almostSolve(view)
  assert.equal(view.celebrationStart, null)
  clickCell(view, 2, 0)
  assert.equal(view.game.solved, true)
  assert.ok(view.celebrationStart?)
  finishTimers()
  assert.equal(view.celebrationStart, null)

  clickCell(view, 0, 13)                              # undo
  assert.equal(view.celebrationStart, null)
  clickCell(view, 8, 13)                              # redo
  assert.ok(view.celebrationStart?)
  finishTimers()

  reloaded = quietly -> new SudokuView(view.app, view.canvas)
  reloaded.layout()
  reloaded.draw()
  assert.equal(reloaded.game.solved, true)
  assert.equal(reloaded.celebrationStart, null)

test 'the celebration wave spreads from the last cell', ->
  view = newView()
  almostSolve(view)
  clickCell(view, 2, 0)
  assert.equal(view.celebrationLevel(2, 0), 0)
  mock.timers.tick(228)
  assert.ok(view.celebrationLevel(2, 0) > 0.99)
  assert.equal(view.celebrationLevel(8, 8), 0)
  mock.timers.tick(900)
  assert.equal(view.celebrationLevel(2, 0), 0)
  assert.ok(view.celebrationLevel(8, 8) > 0)
  assert.match(view.celebrationColor(8, 8, 1), /^hsla\(\d+, 80%, 60%, 0\.800\)$/)
  finishTimers()
  assert.equal(view.celebrationStart, null)
  assert.equal(view.celebrationLevel(8, 8), 0)

test 'undoing the solution stops the celebration', ->
  view = newView()
  almostSolve(view)
  clickCell(view, 2, 0)
  clickCell(view, 0, 13)                              # undo
  assert.equal(view.celebrationStart, null)
  mock.timers.tick(50)                                # flash redraw
  count = view.app.drawCount
  finishTimers()
  assert.equal(view.app.drawCount, count)

test 'the celebration does not draw over the menu', ->
  view = newView()
  almostSolve(view)
  clickCell(view, 2, 0)
  view.app.view = null
  count = view.app.drawCount
  finishTimers()
  assert.equal(view.app.drawCount, count)
  assert.equal(view.celebrationStart, null)

test 'menu buttons need the click inside them', ->
  app = new FakeApp
  menu = new MenuView(app, { width: 1000, height: 1000 })
  menu.layout()
  menu.draw()
  button = menu.buttons.resume
  menu.click(button.x - 1, button.y + button.h / 2)
  assert.deepEqual(app.switched, [])
  menu.click(button.x + 1, button.y + button.h / 2)
  assert.deepEqual(app.switched, ["sudoku"])
  assert.equal(menu.key, undefined)
