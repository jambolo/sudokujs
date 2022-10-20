SudokuGenerator = require './SudokuGenerator'

# Returns the index of a cell in row major order (though they are stored in column major order)
cellIndex = (x, y) -> y * 9 + x

# Sort by ascending location and then by strength (strong then weak)
ascendingLinkSort = (a, b) ->
  a0 = cellIndex(a.cells[0].x, a.cells[0].y)
  a1 = cellIndex(a.cells[1].x, a.cells[1].y)
  b0 = cellIndex(b.cells[0].x, b.cells[0].y)
  b1 = cellIndex(b.cells[1].x, b.cells[1].y)
  return if a0 > b0 or (a0 == b0 and (a1 > b1 or (a1 == b1 and (not a.strong? and b.strong?)))) then 1 else -1

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

  validate: ->
    board = new Array(9).fill(null)
    for i in [0...9]
      board[i] = new Array(9).fill(0)
      for j in [0...9]
        board[i][j] = @grid[i][j].value

    generator = new SudokuGenerator
    return generator.validateGrid(board)

  import: (importString) ->
    if importString.indexOf("SD") != 0
      return false
    importString = importString.substr(2)
    importString = importString.replace(/[^0-9]/g, "")
    if importString.length != 81
      return false

    @clear()

    index = 0
    zeroCharCode = "0".charCodeAt(0)
    for j in [0...9]
      for i in [0...9]
        v = importString.charCodeAt(index) - zeroCharCode
        index += 1
        if v > 0
          @grid[i][j].locked = true
          @grid[i][j].value = v

    return false if not @validate()

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
    @do "togglePencil", x, y, (i + 1 for flag, i in cell.pencil when flag), @undoJournal
    @redoJournal = []

  togglePencil: (x, y, v) ->
    if @grid[x][y].locked
      return
    @do "togglePencil", x, y, [v], @undoJournal
    @redoJournal = []

  setValue: (x, y, v) ->
    if @grid[x][y].locked
      return
    @do "setValue", x, y, [v], @undoJournal
    @redoJournal = []

  reset: ->
    console.log "reset()"
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
    @highlightX = -1
    @highlightY = -1
    @updateCells()
    @save()

  getLinks: (value) ->
    # Note: the search sorts the links in row major order, first by start cell, then by end cell
    links = []

    # Get row links
    for y in [0...9]
      links.push @getRowLinks(y, value)...

    # Get column links
    for x in [0...9]
      links.push @getColumnLinks(x, value)...

    # Get box links
    for boxX in [0...3]
      for boxY in [0...3]
        links.push @getBoxLinks(boxX, boxY, value)...

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

  getRowLinks: (y, value) ->
    cells = []
    for x in [0...9]
      cell = @grid[x][y]
      if cell.value == 0 and cell.pencil[value - 1]
        cells.push({ x, y })

    if cells.length > 1
      links = generateLinkPermutations(cells)
      if links.length == 1
        links[0].strong = true
    else
      links = []
    return links

  getColumnLinks: (x, value) ->
    cells = []
    for y in [0...9]
      cell = @grid[x][y]
      if cell.value == 0 and cell.pencil[value - 1]
        cells.push({ x, y })

    if cells.length > 1
      links = generateLinkPermutations(cells)
      if links.length == 1
        links[0].strong = true
    else
      links = []
    return links

  getBoxLinks: (boxX, boxY, value) ->
    cells = []
    sx = boxX * 3
    sy = boxY * 3
    for y in [sy...sy + 3]
      for x in [sx...sx + 3]
        cell = @grid[x][y]
        if cell.value == 0 and cell.pencil[value - 1]
          cells.push({ x, y })

    if cells.length > 1
      links = generateLinkPermutations(cells)
      if links.length == 1
        links[0].strong = true
    else
      links = []
    return links

  markIsGood: (x, y, m) ->
    # Check if this mark is a known value in the column
    for j in [0...9] when j isnt y
      if @grid[x][j].value == m
        return false

    # Check if this mark is a known value in the row
    for i in [0...9] when i isnt x
      if @grid[i][y].value == m
        return false

    # Check if this mark is a known value in the box
    sx = Math.floor(x / 3) * 3
    sy = Math.floor(y / 3) * 3
    for i in [sx...sx + 3]
      for j in [sy...sy + 3]
        if (i != x || j != y) && @grid[i][j].value == m
          return false
  
    return true

  newGame: (difficulty) ->
    console.log "newGame(#{difficulty})"
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
    if not localStorage
      alert("No local storage, nothing will work")
      return false
    jsonString = localStorage.getItem("game")
    if jsonString == null
      return false

    # console.log jsonString
    gameData = JSON.parse(jsonString)
    # console.log "found gameData", gameData

    for j in [0...9]
      for i in [0...9]
        src = gameData.grid[i][j]
        dst = @grid[i][j]
        dst.value = src.v
        dst.error = if src.e > 0 then true else false
        dst.locked = if src.l > 0 then true else false
        for k in [0...9]
          dst.pencil[k] = if src.p[k] > 0 then true else false
    @solution = gameData.solution
    @updateCells()
    console.log "Loaded game."
    return true

  save: ->
    if not localStorage
      alert("No local storage, nothing will work")
      return false

    gameData =
      grid: new Array(9).fill(null)
      solution: new Array(9).fill(null)

    for i in [0...9]
      gameData.grid[i] = new Array(9).fill(null)
      gameData.solution[i] = new Array(9).fill(null)

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

    for i in [0...9]
      gameData.solution[i] = new Array(9).fill(null)
      for j in [0...9]
        gameData.solution[i][j] = @solution[i][j]

    jsonString = JSON.stringify(gameData)
    localStorage.setItem("game", jsonString)
    console.log "Saved game (#{jsonString.length} chars)"
    return true

module.exports = SudokuGame
