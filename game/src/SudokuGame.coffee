SudokuGenerator = require './SudokuGenerator'

# Returns the index of a cell in row major order (though they are stored in column major order)
cellIndex = (x, y) -> y * 9 + x

# Sort by ascending location and then by strength (strong then weak)
ascendingLinkSort = (a, b) ->
  a0 = cellIndex(a.cells[0].x, a.cells[0].y)
  a1 = cellIndex(a.cells[1].x, a.cells[1].y)
  b0 = cellIndex(b.cells[0].x, b.cells[0].y)
  b1 = cellIndex(b.cells[1].x, b.cells[1].y)
  return a0 - b0 if a0 != b0
  return a1 - b1 if a1 != b1
  return (if a.strong? then 0 else 1) - (if b.strong? then 0 else 1)

# Note strength is not compared
uniqueLinkFilter = (e, i, a) ->
  if i == 0
    return true
  p = a[i - 1]
  e0 = cellIndex(e.cells[0].x, e.cells[0].y)
  e1 = cellIndex(e.cells[1].x, e.cells[1].y)
  p0 = cellIndex(p.cells[0].x, p.cells[0].y)
  p1 = cellIndex(p.cells[1].x, p.cells[1].y)
  return e0 != p0 or e1 != p1

generateLinkPermutations = (cells) ->
  links = []
  count = cells.length
  for i in [0...count - 1]
    for j in [i + 1...count]
      links.push({ cells: [cells[i], cells[j]] })
  return links

# Version of the saved game format
SAVE_VERSION = 2

# Returns true if the value is a completely filled 9x9 grid
isFullGrid = (grid) ->
  return false if not Array.isArray(grid) or grid.length != 9
  for column in grid
    return false if not Array.isArray(column) or column.length != 9
    for v in column
      return false if not Number.isInteger(v) or v < 1 or v > 9
  return true

# Returns true if the value is a valid undo or redo journal
isJournal = (journal) ->
  return false if not Array.isArray(journal)
  for step in journal
    return false if step?.action not in ["togglePencil", "setValue"]
    return false if not (Number.isInteger(step.x) and 0 <= step.x < 9)
    return false if not (Number.isInteger(step.y) and 0 <= step.y < 9)
    return false if not Array.isArray(step.values) or step.values.length == 0
    for v in step.values
      return false if not (Number.isInteger(v) and 0 <= v <= 9)
  return true

# Returns the local storage, or null if it is unavailable or blocked
getStorage = ->
  try
    return localStorage ? null
  catch
    return null

class SudokuGame
  constructor: ->
    @clear()
    if not @load()
      @newGame(SudokuGenerator.difficulty.easy)
    return

  clear: ->
    @grid = new Array(9).fill(null)
    for i in [0...9]
      @grid[i] = new Array(9).fill(null)
    for j in [0...9]
      for i in [0...9]
        @grid[i][j] =
          value: 0
          error: false
          locked: false
          pencil: new Array(9).fill(false)

    @solved = false
    @undoJournal = []
    @redoJournal = []

  holeCount: ->
    count = 0
    for j in [0...9]
      for i in [0...9]
        if not @grid[i][j].locked
          count += 1
    return count

  export: ->
    exportString = "SD"
    for j in [0...9]
      for i in [0...9]
        if @grid[i][j].locked
          exportString += "#{@grid[i][j].value}"
        else
          exportString += "0"
    return exportString

  import: (importString) ->
    if importString.indexOf("SD") != 0
      return false
    importString = importString.substr(2)
    importString = importString.replace(/[^0-9]/g, "")
    if importString.length != 81
      return false

    # Parse and validate before touching the current game
    values = new Array(9).fill(null)
    for i in [0...9]
      values[i] = new Array(9).fill(0)

    index = 0
    zeroCharCode = "0".charCodeAt(0)
    for j in [0...9]
      for i in [0...9]
        values[i][j] = importString.charCodeAt(index) - zeroCharCode
        index += 1

    generator = new SudokuGenerator
    return false if not generator.validateGrid(values)

    @clear()
    @solution = generator.solveGrid(values)
    for j in [0...9]
      for i in [0...9]
        if values[i][j] > 0
          @grid[i][j].locked = true
          @grid[i][j].value = values[i][j]

    @updateCells()
    @save()
    return true

  updateCell: (x, y) ->
    cell = @grid[x][y]

    for i in [0...9]
      if x != i
        v = @grid[i][y].value
        if v > 0
          if v == cell.value
            @grid[i][y].error = true
            cell.error = true

      if y != i
        v = @grid[x][i].value
        if v > 0
          if v == cell.value
            @grid[x][i].error = true
            cell.error = true

    sx = Math.floor(x / 3) * 3
    sy = Math.floor(y / 3) * 3
    for j in [0...3]
      for i in [0...3]
        if (x != (sx + i)) && (y != (sy + j))
          v = @grid[sx + i][sy + j].value
          if v > 0
            if v == cell.value
              @grid[sx + i][sy + j].error = true
              cell.error = true
    return

  updateCells: ->
    for j in [0...9]
      for i in [0...9]
        @grid[i][j].error = false

    for j in [0...9]
      for i in [0...9]
        @updateCell(i, j)

    @solved = true
    for j in [0...9]
      for i in [0...9]
        if @grid[i][j].error
          @solved = false
        if @grid[i][j].value == 0
          @solved = false

    # if @solved
    #   console.log "solved #{@solved}"

    return @solved

  done: ->
    d = new Array(9).fill(false)
    counts = new Array(9).fill(0)
    for j in [0...9]
      for i in [0...9]
        if @grid[i][j].value != 0
          counts[@grid[i][j].value - 1] += 1

    for i in [0...9]
      if counts[i] == 9
        d[i] = true
    return d

  pencilMarks: (x, y) ->
    cell = @grid[x][y]
    marks = []
    for i in [0...9]
      if cell.pencil[i]
        marks.push i + 1
    return marks

  do: (action, x, y, values, journal) ->
    if values.length > 0
      cell = @grid[x][y]
      switch action
        when "togglePencil"
          journal.push { action: "togglePencil", x: x, y: y, values: values }
          cell.pencil[v - 1] = !cell.pencil[v - 1] for v in values
        when "setValue"
          journal.push { action: "setValue", x: x, y: y, values: [cell.value] }
          cell.value = values[0]
      @updateCells()
      @save()

  undo: ->
    if (@undoJournal.length > 0)
      step = @undoJournal.pop()
      @do step.action, step.x, step.y, step.values, @redoJournal
      return [ step.x, step.y ]

  redo: ->
    if (@redoJournal.length > 0)
      step = @redoJournal.pop()
      @do step.action, step.x, step.y, step.values, @undoJournal
      return [ step.x, step.y ]

  clearPencil: (x, y) ->
    cell = @grid[x][y]
    if cell.locked
      return
    marks = (i + 1 for flag, i in cell.pencil when flag)
    if marks.length == 0
      return
    @redoJournal = []
    @do "togglePencil", x, y, marks, @undoJournal

  togglePencil: (x, y, v) ->
    if @grid[x][y].locked
      return
    @redoJournal = []
    @do "togglePencil", x, y, [v], @undoJournal

  setValue: (x, y, v) ->
    if @grid[x][y].locked or @grid[x][y].value == v
      return
    @redoJournal = []
    @do "setValue", x, y, [v], @undoJournal

  reset: ->
    for j in [0...9]
      for i in [0...9]
        cell = @grid[i][j]
        if not cell.locked
          cell.value = 0
        cell.error = false
        for k in [0...9]
          cell.pencil[k] = false
    @undoJournal = []
    @redoJournal = []
    @updateCells()
    @save()

  getLinks: (value) ->
    # Note: the search sorts the links in row major order, first by start cell, then by end cell
    links = []

    for i in [0...9]
      # Row, column, and box
      sx = (i % 3) * 3
      sy = (i // 3) * 3
      links.push @getUnitLinks(({ x, y: i } for x in [0...9]), value)...
      links.push @getUnitLinks(({ x: i, y } for y in [0...9]), value)...
      links.push @getUnitLinks(({ x: sx + (k % 3), y: sy + (k // 3) } for k in [0...9]), value)...

    # The box links might have duplicated some row and column links, so duplicates must be filtered out. Note that only
    # locations are considered when finding duplicates, but strong links take precedence when duplicates are removed
    # (because they are ordered before weak links).
    links = links.sort(ascendingLinkSort).filter(uniqueLinkFilter)

    strong = []
    for link in links
      strong.push link.cells if link.strong?
    weak = []
    for link in links
      weak.push link.cells if not link.strong?

    return { strong, weak }

  # Returns the links between the unsolved cells in the unit that are marked with the value
  getUnitLinks: (unit, value) ->
    cells = (c for c in unit when @grid[c.x][c.y].value == 0 and @grid[c.x][c.y].pencil[value - 1])
    return [] if cells.length < 2
    links = generateLinkPermutations(cells)
    links[0].strong = true if links.length == 1
    return links

  # Returns false if the mark is ruled out by a correct value in the same row, column, or box
  markIsGood: (x, y, m) ->
    sx = Math.floor(x / 3) * 3
    sy = Math.floor(y / 3) * 3
    for i in [0...9]
      return false if @valueIsCorrect(i, y, m)
      return false if @valueIsCorrect(x, i, m)
      return false if @valueIsCorrect(sx + (i % 3), sy + (i // 3), m)
    return true

  # Returns true if the cell has the value and it matches the solution
  valueIsCorrect: (x, y, v) ->
    return @grid[x][y].value == v and @solution[x][y] == v

  newGame: (difficulty) ->
    for j in [0...9]
      for i in [0...9]
        cell = @grid[i][j]
        cell.value = 0
        cell.error = false
        cell.locked = false
        for k in [0...9]
          cell.pencil[k] = false

    generator = new SudokuGenerator()
    [ newGrid, @solution ] = generator.generate(difficulty)
    # console.log "newGrid", newGrid
    for j in [0...9]
      for i in [0...9]
        if newGrid[i][j] != 0
          @grid[i][j].value = newGrid[i][j]
          @grid[i][j].locked = true
    @undoJournal = []
    @redoJournal = []
    @updateCells()
    @save()

  load: ->
    storage = getStorage()
    if storage == null
      console.log "No local storage, the game will not be saved"
      return false
    jsonString = storage.getItem("game")
    if jsonString == null
      return false

    # console.log jsonString
    # A corrupt save is discarded
    try
      gameData = JSON.parse(jsonString)
      # console.log "found gameData", gameData

      if gameData.version > SAVE_VERSION
        throw new Error("unsupported save version #{gameData.version}")

      for j in [0...9]
        for i in [0...9]
          src = gameData.grid[i][j]
          dst = @grid[i][j]
          dst.value = src.v
          dst.error = if src.e > 0 then true else false
          dst.locked = if src.l > 0 then true else false
          for k in [0...9]
            dst.pencil[k] = if src.p[k] > 0 then true else false

      # Saves without a usable solution get one computed from the locked cells
      @solution = gameData.solution
      if not isFullGrid(@solution)
        givens = ((if cell.locked then cell.value else 0) for cell in column for column in @grid)
        @solution = new SudokuGenerator().solveGrid(givens)
        if @solution == null
          throw new Error("saved puzzle has no solution")

      @undoJournal = if isJournal(gameData.undo) then gameData.undo else []
      @redoJournal = if isJournal(gameData.redo) then gameData.redo else []
    catch e
      console.log "Failed to load saved game: #{e.message}"
      @clear()
      return false

    @updateCells()
    return true

  save: ->
    storage = getStorage()
    return false if storage == null

    gameData =
      version: SAVE_VERSION
      grid: new Array(9).fill(null)
      solution: (column.slice() for column in @solution)
      undo: @undoJournal
      redo: @redoJournal

    for i in [0...9]
      gameData.grid[i] = new Array(9).fill(null)

    for j in [0...9]
      for i in [0...9]
        cell = @grid[i][j]
        gameData.grid[i][j] =
          v: cell.value
          e: if cell.error then 1 else 0
          l: if cell.locked then 1 else 0
          p: []
        dst = gameData.grid[i][j].p
        for k in [0...9]
          dst.push(if cell.pencil[k] then 1 else 0)

    try
      storage.setItem("game", JSON.stringify(gameData))
    catch e
      console.log "Failed to save game: #{e.message}"
      return false
    return true

module.exports = SudokuGame
