SudokuGenerator = require './SudokuGenerator'
SudokuGame = require './SudokuGame'

PEN_POS_X = 1
PEN_POS_Y = 10
PEN_CLEAR_POS_X = 2
PEN_CLEAR_POS_Y = 13

PENCIL_POS_X = 5
PENCIL_POS_Y = 10
PENCIL_CLEAR_POS_X = 6
PENCIL_CLEAR_POS_Y = 13

MENU_POS_X = 4
MENU_POS_Y = 13

MODE_START_POS_X = 2
MODE_CENTER_POS_X = 4
MODE_END_POS_X = 6
MODE_POS_Y = 9

UNDO_POS_X = 0
UNDO_POS_Y = 13
REDO_POS_X = 8
REDO_POS_Y = 13

Color =
  value: "black"
  pencil: "#0000ff"
  error: "#ff0000"
  done: "#cccccc"
  menu: "#008833"
  links: "#cc3333"
  backgroundSelected: "#eeeeaa"
  backgroundLocked: "#eeeeee"
  backgroundLockedConflicted: "#ffffee"
  backgroundLockedSelected: "#eeeedd"
  backgroundConflicted: "#ffffdd"
  backgroundError: "#ffdddd"
  modeSelect: "#777744"
  modePen: "#000000"
  modePencil: "#0000ff"
  modeLinks: "#cc3333"

ActionType =
  SELECT: 0
  PENCIL: 1
  PEN: 2
  MENU: 3
  UNDO: 4
  REDO: 5
  MODE: 6

ModeType =
  VISIBILITY: 0
  PENCIL: 1
  PEN: 2
  LINKS: 3

# Special pen/pencil values
NONE = 0
CLEAR = 10

# If a second tap on a pen/pencil happens in this interval, toggle value highlighting instead of switching modes
DOUBLE_TAP_INTERVAL_MS = 500

now = ->
  return Math.floor(Date.now())

KEY_MAPPING =
  '0': { v: CLEAR, shift: false }
  '1': { v: 1, shift: false }
  '2': { v: 2, shift: false }
  '3': { v: 3, shift: false }
  '4': { v: 4, shift: false }
  '5': { v: 5, shift: false }
  '6': { v: 6, shift: false }
  '7': { v: 7, shift: false }
  '8': { v: 8, shift: false }
  '9': { v: 9, shift: false }
  ')': { v: CLEAR, shift: true }
  '!': { v: 1, shift: true }
  '@': { v: 2, shift: true }
  '#': { v: 3, shift: true }
  '$': { v: 4, shift: true }
  '%': { v: 5, shift: true }
  '^': { v: 6, shift: true }
  '&': { v: 7, shift: true }
  '*': { v: 8, shift: true }
  '(': { v: 9, shift: true }

# Celebration color palette
CELEBRATION_COLORS = [
  "#7f7fff",
  "#7fff7f",
  "#7fffff",
  "#7f7f3f",
  "#ff7f7f",
  "#ff7fff",
  "#ffff7f",
  "#ffffff"
]

CELEBRATION_STEPS = 30          # Number of color changes in a celebration
CELEBRATION_INTERVAL_MS = 33    # Time between celebration color changes

FLASH_INTERVAL_MS = 33          # Length of flash

class SudokuView
  # -------------------------------------------------------------------------------------
  # Init

  constructor: (@app, @canvas) ->
    console.log "canvas size #{@canvas.width}x#{@canvas.height}"

    widthBasedCellSize = @canvas.width / 9
    heightBasedCellSize = @canvas.height / 14
    console.log "widthBasedCellSize #{widthBasedCellSize} heightBasedCellSize #{heightBasedCellSize}"
    @cellSize = Math.min(widthBasedCellSize, heightBasedCellSize)

    # calc render constants
    @lineWidthThin = 1
    @lineWidthThick = Math.max(@cellSize / 20, 3)
    @linkDotRadius = @lineWidthThick
    @centerX = 4.5 * @cellSize
    @centerY = 4.5 * @cellSize

    fontPixelsS = Math.floor(@cellSize * 0.3)
    fontPixelsM = Math.floor(@cellSize * 0.5)
    fontPixelsL = Math.floor(@cellSize * 0.8)

    # init fonts
    @fonts =
      pencil:  @app.registerFont("pencil",  "#{fontPixelsS}px saxMono, monospace")
      menu:    @app.registerFont("menu",    "#{fontPixelsM}px saxMono, monospace")
      pen:     @app.registerFont("pen",     "#{fontPixelsL}px saxMono, monospace")

    @initActions()

    # init state
    @game = new SudokuGame()
    @resetState()

    @draw()

  initActions: ->
    @actions = new Array(9 * 15).fill(null)

    for j in [0...9]
      for i in [0...9]
        index = (j * 9) + i
        @actions[index] = { type: ActionType.SELECT, x: i, y: j }

    for j in [0...3]
      for i in [0...3]
        index = ((PEN_POS_Y + j) * 9) + (PEN_POS_X + i)
        @actions[index] = { type: ActionType.PEN, value: 1 + (j * 3) + i }

    for j in [0...3]
      for i in [0...3]
        index = ((PENCIL_POS_Y + j) * 9) + (PENCIL_POS_X + i)
        @actions[index] = { type: ActionType.PENCIL, value: 1 + (j * 3) + i }

    # Pen clear button
    index = (PEN_CLEAR_POS_Y * 9) + PEN_CLEAR_POS_X
    @actions[index] = { type: ActionType.PEN, value: CLEAR }

    # Pencil clear button
    index = (PENCIL_CLEAR_POS_Y * 9) + PENCIL_CLEAR_POS_X
    @actions[index] = { type: ActionType.PENCIL, value: CLEAR }

    # Menu button
    index = (MENU_POS_Y * 9) + MENU_POS_X
    @actions[index] = { type: ActionType.MENU }

    # Undo button
    index = (UNDO_POS_Y * 9) + UNDO_POS_X
    @actions[index] = { type: ActionType.UNDO }

    # Redo button
    index = (REDO_POS_Y * 9) + REDO_POS_X
    @actions[index] = { type: ActionType.REDO }

    # Mode switch
    for i in [(MODE_POS_Y * 9) + MODE_START_POS_X..(MODE_POS_Y * 9) + MODE_END_POS_X]
      @actions[i] = { type: ActionType.MODE }

    return

  resetState: ->
    @mode = ModeType.VISIBILITY
    @penValue = NONE
    @visibilityX = -1
    @visibilityY = -1
    @preferPencil = false
    @strongLinks = []
    @weakLinks = []
    @highlightingValues = false
    @lastValueTapMS = now() - DOUBLE_TAP_INTERVAL_MS  # Ensure the next tap is not a double tap
    @celebrationCount = -1                            # -1 = never run, 0 = done, > 0 = running

  # -------------------------------------------------------------------------------------
  # Rendering

  celebrate: ->
    @draw()
    if @celebrationCount > 0
      --@celebrationCount
      setTimeout =>
        @celebrate()
      , CELEBRATION_INTERVAL_MS

  chooseCelebrationColor: (value) ->
    color = null
    if value > 0 and @celebrationCount > 0
      index = (value + @celebrationCount - 2) % 8
      color = CELEBRATION_COLORS[index]
    return color

  chooseBackgroundColor: (i, j, value, locked, marks) ->
    color = null

    # Locked cells
    if locked
      color = Color.backgroundLocked

    # Override with any highlighting
    switch @mode
      when ModeType.VISIBILITY
        if (@visibilityX != -1) && (@visibilityY != -1)
          if (i == @visibilityX) && (j == @visibilityY)
            if locked
              color = Color.backgroundLockedSelected
            else
              color = Color.backgroundSelected
          else if @conflicts(i, j, @visibilityX, @visibilityY)
            if locked
              color = Color.backgroundLockedConflicted
            else
              color = Color.backgroundConflicted
      when ModeType.PEN
        if @highlightingValues and @penValue == value and value != 0
          color = Color.backgroundSelected
      when ModeType.PENCIL
        if @highlightingValues and value == 0 and @penValue in marks
          color = Color.backgroundSelected

    # Override if celebrating
    if @celebrationCount > 0
      color = @chooseCelebrationColor(value)

    return color

  markOffset: (v) ->
    {
      x: ((v - 1) % 3) * @cellSize / 3 + @cellSize / 6
      y: Math.floor((v - 1) / 3) * @cellSize / 3 + @cellSize / 6
    }

  drawCell: (x, y, backgroundColor, s, font, color) ->
    px = x * @cellSize
    py = y * @cellSize
    if backgroundColor != null
      @app.drawFill(px, py, @cellSize, @cellSize, backgroundColor)
    @app.drawTextCentered(s, px + (@cellSize / 2), py + (@cellSize / 2), font, color)
    return

  drawFlashCell: (x, y) ->
    px = x * @cellSize
    py = y * @cellSize
    @app.drawFill(px, py, @cellSize, @cellSize, "black")
    return

  drawUnsolvedCell: (x, y, backgroundColor, marks) ->
    px = x * @cellSize
    py = y * @cellSize
    if backgroundColor != null
      @app.drawFill(px, py, @cellSize, @cellSize, backgroundColor)
    for m in marks
      offset = @markOffset(m)
      mx = px + offset.x
      my = py + offset.y
      text = String(m)
      @app.drawTextCentered(text, mx, my, @fonts.pencil, Color.pencil)
    return

  drawSolvedCell: (x, y, backgroundColor, color, value) ->
    px = x * @cellSize
    py = y * @cellSize
    if backgroundColor != null
      @app.drawFill(px, py, @cellSize, @cellSize, backgroundColor)
    @app.drawTextCentered(String(value), px + (@cellSize / 2), py + (@cellSize / 2), @fonts.pen, color)
    return

  drawGrid: (originX, originY, size, solved = false) ->
    left = @cellSize * (originX + 0)
    right = @cellSize * (originX + size)
    top = @cellSize * (originY + 0)
    bottom = @cellSize * (originY + size)

    for i in [0..size]
      color = if solved then "green" else "black"
      lineWidth = @lineWidthThin
      if ((size == 1) || (i % 3) == 0)
        lineWidth = @lineWidthThick

      # Horizontal lines
      y = @cellSize * (originY + i)
      @app.drawLine(left, y, right, y, color, lineWidth)

      # Vertical lines
      x = @cellSize * (originX + i)
      @app.drawLine(x, top, x, bottom, color, lineWidth)
    return

  drawLink: (startX, startY, endX, endY, color, lineWidth, v) ->
    offset = @markOffset(v)
    x1 = startX * @cellSize + offset.x
    y1 = startY * @cellSize + offset.y
    x2 = endX * @cellSize + offset.x
    y2 = endY * @cellSize + offset.y

    # Ensure that the arc curves inward for marks nearer the outside and curves outward for marks nearer the center.
    
    # If the distance from the center to the midpoint of the line is greater than the distance from the center to the midpoint of
    # the squares, then the line curves toward the center.
    lineMidX = (x1 + x2) / 2
    lineMidY = (y1 + y2) / 2
    squaresMidX = @cellSize * (startX + endX + 1) / 2
    squaresMidY = @cellSize * (startY + endY + 1) / 2

    lineDist2 = (@centerX - lineMidX) * (@centerX - lineMidX) + (@centerY - lineMidY) * (@centerY - lineMidY)
    squaresDist2 = (@centerX - squaresMidX) * (@centerX - squaresMidX) + (@centerY - squaresMidY) * (@centerY - squaresMidY)

    centerIsLeft = (@centerX - x1) * (y2 - y1) - (@centerY - y1) * (x2 - x1) < 0

    # When the grid center is left of the line, then the curve is automatically outward, so we have to swap if we want an inward
    # curve, and vice versa
    if (centerIsLeft && lineDist2 > squaresDist2) || (!centerIsLeft && lineDist2 < squaresDist2)
      [x1, x2] = [x2, x1]
      [y1, y2] = [y2, y1]

    curvature = 2.5 # 2.5 gives the most curve without overlapping other cells
    r = curvature * Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
    @app.drawArc(x1, y1, x2, y2, r, color, lineWidth)
    @app.drawPoint(x1, y1, @linkDotRadius, color)
    @app.drawPoint(x2, y2, @linkDotRadius, color)

  draw: (flashX, flashY) ->
    console.log "draw()"

    # Clear screen to black
    @app.drawFill(0, 0, @canvas.width, @canvas.height, "black")

    # Make white phone-shaped background
    @app.drawFill(0, 0, @cellSize * 9, @canvas.height, "white")

    # Draw board numbers
    for j in [0...9]
      for i in [0...9]
        if (i == flashX) && (j == flashY)
          # Draw flash
          @drawFlashCell(i, j)
        else
          # Draw solved or unsolved cell
          cell = @game.grid[i][j]
          marks = @game.pencilMarks(i, j)

          # Determine background color
          backgroundColor = @chooseBackgroundColor(i, j, cell.value, cell.locked, marks)

          if cell.value == 0
            @drawUnsolvedCell(i, j, backgroundColor, marks)
          else
            textColor = if cell.error then Color.error else Color.value
            @drawSolvedCell(i, j, backgroundColor, textColor, cell.value)

    # Draw links in LINKS mode
    if @mode is ModeType.LINKS
      for link in @strongLinks
        @drawLink(link[0].x, link[0].y, link[1].x, link[1].y, Color.links, @lineWidthThick, @penValue)
      for link in @weakLinks
        @drawLink(link[0].x, link[0].y, link[1].x, link[1].y, Color.links, @lineWidthThin, @penValue)

    # Draw pen and pencil number buttons
    done = @game.done()
    for j in [0...3]
      for i in [0...3]
        currentValue = (j * 3) + i + 1
        currentValueString = String(currentValue)
        valueColor = Color.value
        pencilColor = Color.pencil
        if done[(j * 3) + i]
          valueColor = Color.done
          pencilColor = Color.done

        valueBackgroundColor = null
        pencilBackgroundColor = null
        if @penValue == currentValue
          if @mode is ModeType.PENCIL or @mode is ModeType.LINKS
            pencilBackgroundColor = Color.backgroundSelected
          else
            valueBackgroundColor = Color.backgroundSelected

        @drawCell(PEN_POS_X + i, PEN_POS_Y + j, valueBackgroundColor, currentValueString, @fonts.pen, valueColor)
        @drawCell(PENCIL_POS_X + i, PENCIL_POS_Y + j, pencilBackgroundColor, currentValueString, @fonts.pen, pencilColor)

    # Draw pen and pencil CLEAR buttons
    valueBackgroundColor = null
    pencilBackgroundColor = null
    if @penValue == CLEAR
        if @mode is ModeType.PENCIL
            pencilBackgroundColor = Color.backgroundSelected
        else
            valueBackgroundColor = Color.backgroundSelected

    @drawCell(PEN_CLEAR_POS_X, PEN_CLEAR_POS_Y, valueBackgroundColor, "C", @fonts.pen, Color.error)
    @drawCell(PENCIL_CLEAR_POS_X, PENCIL_CLEAR_POS_Y, pencilBackgroundColor, "C", @fonts.pen, Color.error)

    # Draw mode
    switch @mode
      when ModeType.VISIBILITY
        modeColor = Color.modeSelect
        modeText = "Highlighting"
      when ModeType.PENCIL
        modeColor = Color.modePencil
        modeText = "Pencil"
      when ModeType.PEN
        modeColor = Color.modePen
        modeText = "Pen"
      when ModeType.LINKS
        modeColor = Color.modeLinks
        modeText = "Links"
    @drawCell(MODE_CENTER_POS_X, MODE_POS_Y, null, modeText, @fonts.menu, modeColor)

    @drawCell(MENU_POS_X, MENU_POS_Y, null, "Menu", @fonts.menu, Color.menu)
    @drawCell(UNDO_POS_X, UNDO_POS_Y, null, "\u{25c4}", @fonts.menu, Color.menu) if (@game.undoJournal.length > 0)
    @drawCell(REDO_POS_X, REDO_POS_Y, null, "\u{25ba}", @fonts.menu, Color.menu) if (@game.redoJournal.length > 0)

    # Make the grids
    @drawGrid(0, 0, 9, @game.solved)
    @drawGrid(PEN_POS_X, PEN_POS_Y, 3)
    @drawGrid(PENCIL_POS_X, PENCIL_POS_Y, 3)
    @drawGrid(PEN_CLEAR_POS_X, PEN_CLEAR_POS_Y, 1)
    @drawGrid(PENCIL_CLEAR_POS_X, PENCIL_CLEAR_POS_Y, 1)

    # If the game is solved, then start the celebration
    if @game.solved and @celebrationCount < 0
      @celebrationCount = CELEBRATION_STEPS
      setTimeout =>
        @celebrate()
      , CELEBRATION_INTERVAL_MS


  # -------------------------------------------------------------------------------------
  # Input

  # Determines if the interval is short enough to consider an tap to be a double tap.
  doubleTapDetected: ->
    # Double tap also depends on other context. This just measures the time.
    dt = now() - @lastValueTapMS
    return dt < DOUBLE_TAP_INTERVAL_MS

  newGame: (difficulty) ->
    console.log "SudokuView.newGame(#{difficulty})"
    @resetState()
    @game.newGame(difficulty)

  reset: ->
    @resetState()
    @game.reset()

  import: (importString) ->
    @resetState()
    return @game.import(importString)

  export: ->
    return @game.export()

  holeCount: ->
    return @game.holeCount()

  handleSelectAction: (action) ->
    switch @mode
      when ModeType.VISIBILITY
        if (@visibilityX == action.x) && (@visibilityY == action.y)
          @visibilityX = -1
          @visibilityY = -1
        else
          @visibilityX = action.x
          @visibilityY = action.y
        return []
      when ModeType.PENCIL
        if @penValue == CLEAR
          @game.clearPencil(action.x, action.y)
        else if @penValue != NONE
          @game.togglePencil(action.x, action.y, @penValue)
        return [ action.x, action.y ]
      when ModeType.PEN
        if @penValue == CLEAR
          @game.setValue(action.x, action.y, 0)
        else if @penValue != NONE
          @game.setValue(action.x, action.y, @penValue)
        return [ action.x, action.y ]

  handlePencilAction: (action) ->
    # First, make sure any VISIBILITY and LINKS mode stuff is reset
    @visibilityX = -1
    @visibilityY = -1
    @strongLinks = []
    @weakLinks = []

    switch @mode
      # In LINKS, all links associated with the number are shown. CLEAR shows nothing.
      when ModeType.LINKS
        if (action.value == CLEAR)
          @penValue = NONE
          @strongLinks = []
          @weakLinks = []
        else
          @penValue = action.value
          { strong: @strongLinks, weak: @weakLinks } = @game.getLinks(action.value)

      # In PENCIL, the mode is changed to VISIBILITY if the selected value is already current unless double tap
      # Also, if double tap, then turn on highlighting values
      when ModeType.PENCIL
        if @penValue == action.value
          if @doubleTapDetected()
            @highlightingValues = true
          else
            @highlightingValues = false
            @lastValueTapMS = now()
            @mode = ModeType.VISIBILITY
            @penValue = NONE
        else
          @highlightingValues = false
          @lastValueTapMS = now()
          @penValue = action.value

      # Otherwise, switch to PENCIL
      else
        # It is possible that the first tap changed the mode to VISIBILITY so a double tap must pretend that it didn't
        if @mode is ModeType.VISIBILITY and @doubleTapDetected()
          @highlightingValues = true
        else
          @highlightingValues = false
          @lastValueTapMS = now()
        @mode = ModeType.PENCIL
        @penValue = action.value
    return

  handlePenAction: (action) ->
    switch @mode
      # In PEN, the mode is changed to VISIBILITY if the selected value is already current unless double tap
      # Also, if double tap, then turn on highlighting values
      when ModeType.PEN
        if (@penValue == action.value)
          if @doubleTapDetected()
            @highlightingValues = true
          else
            @highlightingValues = false
            @lastValueTapMS = now()
            @mode = ModeType.VISIBILITY
            @penValue = NONE
        else
          @highlightingValues = false
          @lastValueTapMS = now()
          @penValue = action.value

      # Ignored in LINKS
      when ModeType.LINKS
        return

      # Otherwise, the mode is switched to (or remains as) PEN using the selected value
      else
        # It is possible that the first tap changed the mode to VISIBILITY so a double tap must pretend that it didn't
        if @mode is ModeType.VISIBILITY and @doubleTapDetected()
          @highlightingValues = true
        else
          @highlightingValues = false
          @lastValueTapMS = now()
        @mode = ModeType.PEN
        @penValue = action.value

    # Make sure any visibility highlighting is off and links are cleared.
    @visibilityX = -1
    @visibilityY = -1
    @strongLinks = []
    @weakLinks = []
    return

  handleUndoAction: ->
    return @game.undo() if @mode isnt ModeType.LINKS

  handleRedoAction: ->
    return @game.redo() if @mode isnt ModeType.LINKS

  handleModeAction: ->
    switch @mode
      when ModeType.VISIBILITY
        @mode = ModeType.LINKS
      when ModeType.PENCIL
        @mode = ModeType.PEN
      when ModeType.PEN
        @mode = ModeType.VISIBILITY
      when ModeType.LINKS
        @mode = ModeType.PENCIL
    @visibilityX = -1
    @visibilityY = -1
    @penValue = NONE
    @strongLinks = []
    @weakLinks = []
    @highlightingValues = false
    @lastValueTapMS = now() - DOUBLE_TAP_INTERVAL_MS    # Ensure that the next tap is not a double tap
    return

  click: (x, y) ->
    # console.log "click #{x}, #{y}"
    x = Math.floor(x / @cellSize)
    y = Math.floor(y / @cellSize)

    flashX = null
    flashY = null
    if (x < 9) && (y < 15)
        index = (y * 9) + x
        action = @actions[index]
        if action != null
          console.log "Action: ", action

          if action.type is ActionType.MENU
            @app.switchView("menu")
            return

          switch action.type
            when ActionType.SELECT then [ flashX, flashY ] = @handleSelectAction(action)
            when ActionType.PENCIL then @handlePencilAction(action)
            when ActionType.PEN then @handlePenAction(action)
            when ActionType.UNDO then [ flashX, flashY ] = @handleUndoAction()
            when ActionType.REDO then [ flashX, flashY ] = @handleRedoAction()
            when ActionType.MODE then @handleModeAction()
        else
          # no action, default to VISIBILITY mode
          @mode = ModeType.VISIBILITY
          @visibilityX = -1
          @visibilityY = -1
          @penValue = NONE
          @strongLinks = []
          @weakLinks = []
          @highlightingValues = false
          @lastValueTapMS = now() - DOUBLE_TAP_INTERVAL_MS    # Ensure that the next tap is not a double tap

        @draw(flashX, flashY)
        if (flashX? && flashY?)
          setTimeout =>
            @draw()
          , FLASH_INTERVAL_MS
    return

  key: (k) ->
    if k == '.'
      @preferPencil = !@preferPencil
      if @mode == ModeType.PEN
        @handlePencilAction({ value: @penValue })
      else if @mode == ModeType.PENCIL
        @handlePenAction({ value: @penValue })
      else if @mode == ModeType.LINKS
        @handleModeAction()
      @draw()
    else if KEY_MAPPING[k]?
      mapping = KEY_MAPPING[k]
      usePencil = @preferPencil
      if mapping.shift
        usePencil = !usePencil
      if usePencil or @mode == ModeType.LINKS
        @handlePencilAction({ value: mapping.v })
      else
        @handlePenAction({ value: mapping.v })
      @draw()
      return

  # -------------------------------------------------------------------------------------
  # Helpers

  conflicts: (x1, y1, x2, y2) ->
    # same row or column?
    if (x1 == x2) || (y1 == y2)
      return true

    # same section?
    sx1 = Math.floor(x1 / 3) * 3
    sy1 = Math.floor(y1 / 3) * 3
    sx2 = Math.floor(x2 / 3) * 3
    sy2 = Math.floor(y2 / 3) * 3
    if (sx1 == sx2) && (sy1 == sy2)
      return true

    return false

  # -------------------------------------------------------------------------------------

module.exports = SudokuView
