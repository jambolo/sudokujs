shuffle = (a) ->
    i = a.length
    while --i > 0
        j = ~~(Math.random() * (i + 1))
        t = a[j]
        a[j] = a[i]
        a[i] = t
    return a

class Board
  constructor: (otherBoard = null) ->
    @lockedCount = 0;
    @grid = new Array(9).fill(null)
    @locked = new Array(9).fill(null)
    for i in [0...9]
      @grid[i] = new Array(9).fill(0)
      @locked[i] = new Array(9).fill(false)
    if otherBoard != null
      for j in [0...9]
        for i in [0...9]
          @grid[i][j] = otherBoard.grid[i][j]
          @lock(i, j, otherBoard.locked[i][j])
    return

  matches: (otherBoard) ->
    for j in [0...9]
      for i in [0...9]
        if @grid[i][j] != otherBoard.grid[i][j]
          return false
    return true

  lock: (x, y, v = true) ->
    if v
      @lockedCount += 1 if not @locked[x][y]
    else
      @lockedCount -= 1 if @locked[x][y]
    @locked[x][y] = v;


class SudokuGenerator
  @difficulty:
    easy: 1
    medium: 2
    hard: 3
    extreme: 4

  constructor: ->

  boardToGrid: (board) ->
    newBoard = new Array(9).fill(null)
    for i in [0...9]
      newBoard[i] = new Array(9).fill(0)
    for j in [0...9]
      for i in [0...9]
        if board.locked[i][j]
          newBoard[i][j] = board.grid[i][j]
    return newBoard

  cellValid: (board, x, y, v) ->
    if board.locked[x][y]
      return board.grid[x][y] == v

    for i in [0...9]
      if (x != i) and (board.grid[i][y] == v)
          return false
      if (y != i) and (board.grid[x][i] == v)
          return false

    sx = Math.floor(x / 3) * 3
    sy = Math.floor(y / 3) * 3
    for j in [0...3]
      for i in [0...3]
        if (x != (sx + i)) && (y != (sy + j))
          if board.grid[sx + i][sy + j] == v
            return false
    return true

  pencilMarks: (board, x, y) ->
    if board.locked[x][y]
      return [ board.grid[x][y] ]
    marks = []
    for v in [1..9]
      if @cellValid(board, x, y, v)
        marks.push v
    if marks.length > 1
      shuffle(marks)
    return marks

  solve: (board) ->
    solved = new Board(board)
    pencil = new Array(9).fill(null)
    for i in [0...9]
      pencil[i] = new Array(9).fill(null)
    return @solveInternal(board, solved, pencil)

  hasUniqueSolution: (board) ->
    solved = new Board(board)
    pencil = new Array(9).fill(null)
    for i in [0...9]
      pencil[i] = new Array(9).fill(null)

    # if there is no solution, return false
    return false if @solveInternal(board, solved, pencil) == null

    # check for a second solution
    return @solveInternal(board, solved, pencil, 80, -1) == null

  solveInternal: (board, solved, pencil, walkIndex = 0, direction = 1) ->
    while walkIndex < 81
      x = walkIndex % 9
      y = walkIndex // 9

      if not solved.locked[x][y]
        if (direction == 1) and ((pencil[x][y] == null) or (pencil[x][y].length == 0))
          pencil[x][y] = @pencilMarks(solved, x, y)

        if pencil[x][y].length == 0
          solved.grid[x][y] = 0
          direction = -1
        else
          solved.grid[x][y] = pencil[x][y].pop()
          direction = 1

      walkIndex += direction
      if walkIndex < 0
        return null

    return solved

  generateInternal: (amountToRemove) ->
    board = @solve(new Board())
    # hack
    for j in [0...9]
      for i in [0...9]
        board.lock(i, j)

    indexesToRemove = shuffle([0...81])
    removed = 0
    while removed < amountToRemove
      if indexesToRemove.length == 0
        break

      removeIndex = indexesToRemove.pop()
      rx = removeIndex % 9
      ry = Math.floor(removeIndex / 9)

      nextBoard = new Board(board)
      nextBoard.grid[rx][ry] = 0
      nextBoard.lock(rx, ry, false)

      if @hasUniqueSolution(nextBoard)
        board = nextBoard
        removed += 1
        # console.log "successfully removed #{rx},#{ry}"
      else
        # console.log "failed to remove #{rx},#{ry}, creates non-unique solution"

    return {
      board: board
      removed: removed
    }

  generate: (difficulty) ->
    amountToRemove = switch difficulty
      when SudokuGenerator.difficulty.extreme then 60
      when SudokuGenerator.difficulty.hard    then 52
      when SudokuGenerator.difficulty.medium  then 46
      else 40 # easy / unknown

    best = null
    for attempt in [0...2]
      generated = @generateInternal(amountToRemove)
      if generated.removed == amountToRemove
        console.log "Removed exact amount #{amountToRemove}, stopping"
        best = generated
        break

      if best == null
        best = generated
      else if best.removed < generated.removed
        best = generated
      console.log "current best #{best.removed} / #{amountToRemove}"

    console.log "giving user board: #{best.removed} / #{amountToRemove}"
    return @boardToGrid(best.board)

  solveString: (importString) ->
    if importString.indexOf("SD") != 0
      return false
    importString = importString.substr(2)
    importString = importString.replace(/[^0-9]/g, "")
    if importString.length != 81
      return false

    board = new Board()

    index = 0
    zeroCharCode = "0".charCodeAt(0)
    for j in [0...9]
      for i in [0...9]
        v = importString.charCodeAt(index) - zeroCharCode
        index += 1
        if v > 0
          board.grid[j][i] = v
          board.lock(j, i)

    solved = @solve(board)
    if solved == null
      console.log "ERROR: Can't be solved."
      return false

    for x in [0...50] # 50 is excessive
      anotherSolve = @solve(board)
      if not anotherSolve.matches(solved)
        console.log "ERROR: Board solve not unique."
        return false

    answerString = ""
    for j in [0...9]
      for i in [0...9]
        answerString += "#{solved.grid[j][i]} "
      answerString += "\n"

    return answerString

module.exports = SudokuGenerator
