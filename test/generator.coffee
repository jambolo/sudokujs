{ test } = require 'node:test'
assert = require 'node:assert/strict'
SudokuGenerator = require '../game/src/SudokuGenerator'
{ quietly, PUZZLE, SOLUTION } = require './helpers'

# Converts an export string to a column-major grid
toGrid = (s) ->
  digits = s.replace(/^SD/, "")
  return ((Number(digits[y * 9 + x]) for y in [0...9]) for x in [0...9])

test 'solveGrid solves a valid puzzle', ->
  solved = new SudokuGenerator().solveGrid(toGrid(PUZZLE))
  assert.deepEqual(solved, toGrid(SOLUTION))

test 'solveGrid rejects conflicting givens', ->
  grid = toGrid(PUZZLE)
  grid[2][0] = 5
  assert.equal(new SudokuGenerator().solveGrid(grid), null)

test 'validateGrid requires a unique solution', ->
  generator = new SudokuGenerator
  assert.equal(generator.validateGrid(toGrid(PUZZLE)), true)
  assert.equal(generator.validateGrid(toGrid("0".repeat(81))), false)

test 'solveString reports the solution or false', ->
  generator = new SudokuGenerator
  answer = generator.solveString(PUZZLE)
  assert.equal(answer.replace(/\s/g, "").length, 81)
  assert.equal(quietly(-> generator.solveString("SD" + "0".repeat(81))), false)
  assert.equal(generator.solveString("garbage"), false)

test 'generate returns a uniquely solvable puzzle and its solution', ->
  generator = new SudokuGenerator
  [ puzzle, solution ] = quietly -> generator.generate(SudokuGenerator.difficulty.easy)
  holes = 0
  for x in [0...9]
    for y in [0...9]
      if puzzle[x][y] == 0
        holes += 1
      else
        assert.equal(puzzle[x][y], solution[x][y])
  assert.equal(holes, 40)
  assert.equal(generator.validateGrid(puzzle), true)
  assert.deepEqual(generator.solveGrid(puzzle), solution)
