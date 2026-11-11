# In-memory replacement for localStorage
class MemoryStorage
  constructor: ->
    @items = {}

  getItem: (key) ->
    return @items[key] ? null

  setItem: (key, value) ->
    @items[key] = String(value)
    return

  removeItem: (key) ->
    delete @items[key]
    return

# Installs a fresh in-memory localStorage and returns it
installStorage = ->
  storage = new MemoryStorage
  Object.defineProperty(globalThis, 'localStorage', { value: storage, configurable: true, writable: true })
  return storage

# Runs a function with console.log silenced
quietly = (f) ->
  log = console.log
  console.log = ->
  try
    return f()
  finally
    console.log = log

# A valid puzzle and its solution in export format
PUZZLE = "SD530070000600195000098000060800060003400803001700020006060000280000419005000080079"
SOLUTION = "534678912672195348198342567859761423426853791713924856961537284287419635345286179"

# Returns the solution value of a cell
solutionAt = (x, y) ->
  return Number(SOLUTION[y * 9 + x])

module.exports = { installStorage, quietly, PUZZLE, SOLUTION, solutionAt }
