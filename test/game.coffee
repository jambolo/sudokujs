{ test, beforeEach } = require 'node:test'
assert = require 'node:assert/strict'
SudokuGame = require '../game/src/SudokuGame'
{ installStorage, quietly, PUZZLE, solutionAt } = require './helpers'

storage = null

# Returns a game holding the test puzzle
newGame = ->
  game = quietly -> new SudokuGame
  assert.equal(game.import(PUZZLE), true)
  return game

# Returns the unlocked cells of a game
holes = (game) ->
  cells = []
  for y in [0...9]
    for x in [0...9]
      cells.push({ x, y }) if not game.grid[x][y].locked
  return cells

beforeEach ->
  storage = installStorage()

test 'import and export round trip', ->
  game = newGame()
  assert.equal(game.export(), PUZZLE)
  assert.equal(game.holeCount(), 51)
  assert.equal(game.solution[2][0], 4)

test 'a failed import keeps the current game', ->
  game = newGame()
  game.setValue(2, 0, 4)
  assert.equal(game.import("SD" + "1".repeat(81)), false)
  assert.equal(game.import("nonsense"), false)
  assert.equal(game.export(), PUZZLE)
  assert.equal(game.grid[2][0].value, 4)

test 'locked cells cannot be changed', ->
  game = newGame()
  game.setValue(0, 0, 9)
  game.togglePencil(0, 0, 9)
  assert.equal(game.grid[0][0].value, 5)
  assert.deepEqual(game.pencilMarks(0, 0), [])
  assert.equal(game.undoJournal.length, 0)

test 'conflicting values are flagged', ->
  game = newGame()
  game.setValue(2, 0, 5)
  assert.equal(game.grid[2][0].error, true)
  assert.equal(game.grid[0][0].error, true)
  game.setValue(2, 0, 4)
  assert.equal(game.grid[2][0].error, false)
  assert.equal(game.grid[0][0].error, false)

test 'undo and redo', ->
  game = newGame()
  game.setValue(2, 0, 4)
  game.togglePencil(3, 0, 6)
  game.togglePencil(3, 0, 2)
  game.clearPencil(3, 0)
  assert.deepEqual(game.pencilMarks(3, 0), [])
  assert.deepEqual(game.undo(), [3, 0])
  assert.deepEqual(game.pencilMarks(3, 0), [2, 6])
  game.undo()
  game.undo()
  assert.deepEqual(game.undo(), [2, 0])
  assert.equal(game.grid[2][0].value, 0)
  assert.equal(game.undo(), undefined)
  assert.deepEqual(game.redo(), [2, 0])
  assert.equal(game.grid[2][0].value, 4)
  game.setValue(2, 0, 1)
  assert.equal(game.redoJournal.length, 0)

test 'setting the same value is not journaled', ->
  game = newGame()
  game.setValue(2, 0, 4)
  game.setValue(2, 0, 4)
  game.clearPencil(2, 0)
  assert.equal(game.undoJournal.length, 1)

test 'solving the puzzle', ->
  game = newGame()
  cells = holes(game)
  game.setValue(c.x, c.y, solutionAt(c.x, c.y)) for c in cells
  assert.equal(game.solved, true)
  assert.deepEqual(game.done(), new Array(9).fill(true))
  game.undo()
  assert.equal(game.solved, false)
  game.redo()
  assert.equal(game.solved, true)

test 'save and load keep the game, solution, and journals', ->
  game = newGame()
  game.setValue(2, 0, 4)
  game.togglePencil(3, 0, 6)
  game.undo()
  loaded = new SudokuGame
  assert.equal(loaded.export(), PUZZLE)
  assert.equal(loaded.grid[2][0].value, 4)
  assert.deepEqual(loaded.solution, game.solution)
  assert.deepEqual(loaded.undoJournal, game.undoJournal)
  assert.deepEqual(loaded.redoJournal, game.redoJournal)
  loaded.redo()
  assert.deepEqual(loaded.pencilMarks(3, 0), [6])

test 'a save without a solution or journals gets them rebuilt', ->
  game = newGame()
  game.setValue(2, 0, 4)
  data = JSON.parse(storage.getItem("game"))
  delete data.version
  delete data.solution
  delete data.undo
  data.redo = [{ action: "bogus" }]
  storage.setItem("game", JSON.stringify(data))
  loaded = new SudokuGame
  assert.equal(loaded.grid[2][0].value, 4)
  assert.deepEqual(loaded.solution, game.solution)
  assert.deepEqual(loaded.undoJournal, [])
  assert.deepEqual(loaded.redoJournal, [])

test 'a corrupt save starts a new game', ->
  storage.setItem("game", "{not json")
  game = quietly -> new SudokuGame
  assert.equal(game.holeCount(), 40)

test 'the game works without storage', ->
  Object.defineProperty(globalThis, 'localStorage', { get: (-> throw new Error("blocked")), configurable: true })
  game = quietly -> new SudokuGame
  assert.equal(game.import(PUZZLE), true)
  game.setValue(2, 0, 4)
  assert.equal(game.grid[2][0].value, 4)

test 'marks are checked against correct values only', ->
  game = newGame()
  # Row 0 of the solution is 534678912
  game.togglePencil(2, 0, v) for v in [2, 4, 5]
  assert.equal(game.markIsGood(2, 0, 4), true)
  assert.equal(game.markIsGood(2, 0, 5), false)
  assert.equal(game.markIsGood(2, 0, 2), true)
  # A wrong value does not rule out a mark
  game.setValue(3, 0, 4)
  assert.equal(game.markIsGood(2, 0, 4), true)
  # A correct value does
  game.setValue(8, 0, 2)
  assert.equal(game.markIsGood(2, 0, 2), false)

test 'links', ->
  game = newGame()
  # Two marks in a row make a strong link
  game.togglePencil(2, 0, 4)
  game.togglePencil(3, 0, 4)
  links = game.getLinks(4)
  assert.deepEqual(links.strong, [[{ x: 2, y: 0 }, { x: 3, y: 0 }]])
  assert.deepEqual(links.weak, [])
  # A third mark in the row makes them all weak, and a strong link in its column
  game.togglePencil(6, 0, 4)
  game.togglePencil(6, 4, 4)
  links = game.getLinks(4)
  assert.deepEqual(links.strong, [[{ x: 6, y: 0 }, { x: 6, y: 4 }]])
  assert.equal(links.weak.length, 3)
  # Marks in the same row and box are linked once
  game.togglePencil(3, 0, 2)
  game.togglePencil(5, 0, 2)
  links = game.getLinks(2)
  assert.deepEqual(links.strong, [[{ x: 3, y: 0 }, { x: 5, y: 0 }]])
  assert.deepEqual(links.weak, [])
