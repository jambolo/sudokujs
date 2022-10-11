SudokuGenerator = require './SudokuGenerator'

window.solve = (arg) ->
  gen = new SudokuGenerator
  return gen.solveString(arg)

window.qs = (name) ->
  url = window.location.href
  name = name.replace(/[\[\]]/g, '\\$&')
  regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)')
  results = regex.exec(url);
  if not results or not results[2]
    return null
  return decodeURIComponent(results[2].replace(/\+/g, ' '))

