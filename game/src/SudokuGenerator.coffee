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
    @lockedCount = 0
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
    @locked[x][y] = v


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

  gridToBoard: (grid) ->
    board = new Board
    for y in [0...9]
      for x in [0...9]
        if grid[x][y] > 0
          board.grid[x][y] = grid[x][y]
          board.lock(x, y)
    return board

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

  nextAttempt: (board, attempts) ->
    remainingIndexes = [0...81]

    # skip locked cells
    for index in [0...81]
      x = index % 9
      y = index // 9
      if board.locked[x][y]
        k = remainingIndexes.indexOf(index)
        remainingIndexes.splice(k, 1) if k >= 0

    # skip cells that are already being tried
    for a in attempts
      k = remainingIndexes.indexOf(a.index)
      remainingIndexes.splice(k, 1) if k >= 0

    return null if remainingIndexes.length == 0 # abort if there are no cells (should never happen)

    fewestIndex = -1
    fewestMarks = [0..9]
    for index in remainingIndexes
      x = index % 9
      y = index // 9
      marks = @pencilMarks(board, x, y)

      # abort if there is a cell with no possibilities
      return null if marks.length == 0

      # done if there is a cell with only one possibility ()
      return { index: index, remaining: marks } if marks.length == 1

      # remember this cell if it has the fewest marks so far
      if marks.length < fewestMarks.length
        fewestIndex = index
        fewestMarks = marks
    return { index: fewestIndex, remaining: fewestMarks }

  solve: (board) ->
    solved = new Board(board)
    attempts = []
    return @solveInternal(solved, attempts)

  hasUniqueSolution: (board) ->
    solved = new Board(board)
    attempts = []

    # if there is no solution, return false
    return false if @solveInternal(solved, attempts) == null

    unlockedCount = 81 - solved.lockedCount

    # if there are no unlocked cells, then this solution must be unique
    return true if unlockedCount == 0

    # check for a second solution
    return @solveInternal(solved, attempts, unlockedCount - 1) == null

  solveInternal: (solved, attempts, walkIndex = 0) ->
    unlockedCount = 81 - solved.lockedCount
    while walkIndex < unlockedCount
      if walkIndex >= attempts.length
        attempt = @nextAttempt(solved, attempts)
        attempts.push(attempt) if attempt != null
      else
        attempt = attempts[walkIndex]

      if attempt != null
        x = attempt.index % 9
        y = attempt.index // 9
        if attempt.remaining.length > 0
          solved.grid[x][y] = attempt.remaining.pop()
          walkIndex += 1
        else
          attempts.pop()
          solved.grid[x][y] = 0
          walkIndex -= 1
      else
        walkIndex -= 1

      if walkIndex < 0
        return null

    return solved

  generateInternal: (amountToRemove) ->
    board = @solve(new Board())
    # hack
    for j in [0...9]
      for i in [0...9]
        board.lock(i, j)

    solution = new Board(board)

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
      board
      removed
      solution
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
    return [@boardToGrid(best.board), @boardToGrid(best.solution)]

  validateGrid: (grid) ->
    return @hasUniqueSolution(@gridToBoard(grid))

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

    if not @hasUniqueSolution(board)
      console.log "ERROR: Board solve not unique."
      return false

    answerString = ""
    for j in [0...9]
      for i in [0...9]
        answerString += "#{solved.grid[j][i]} "
      answerString += "\n"

    return answerString

module.exports = SudokuGenerator
