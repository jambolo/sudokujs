SudokuGenerator = require './SudokuGenerator'

arg = process.argv.slice(2).shift()
if not arg
  console.log "Please give a sudoku string on the commandline."
  process.exit(1)

gen = new SudokuGenerator

answer = gen.solveString(arg)
console.log "solving: '#{arg}'"
if answer
  console.log answer
else
  process.exitCode = 1
