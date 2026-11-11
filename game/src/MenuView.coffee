SudokuGenerator = require './SudokuGenerator'

BUTTON_HEIGHT = 0.06
FIRST_BUTTON_Y = 0.22
BUTTON_SPACING = 0.08
BUTTON_SEPARATOR = 0.03

buttonPos = (index) ->
  y = FIRST_BUTTON_Y + (BUTTON_SPACING * index)
  if index > 3
    y += BUTTON_SEPARATOR
  if index > 4
    y += BUTTON_SEPARATOR
  if index > 6
    y += BUTTON_SEPARATOR
  return y

class MenuView
  constructor: (@app, @canvas) ->
    @buttons =
      newEasy:
        pos: buttonPos(0)
        text: "New Game: Easy"
        bgColor: "#337733"
        textColor: "#ffffff"
        click: @newEasy.bind(this)
      newMedium:
        pos: buttonPos(1)
        text: "New Game: Medium"
        bgColor: "#777733"
        textColor: "#ffffff"
        click: @newMedium.bind(this)
      newHard:
        pos: buttonPos(2)
        text: "New Game: Hard"
        bgColor: "#773333"
        textColor: "#ffffff"
        click: @newHard.bind(this)
      newExtreme:
        pos: buttonPos(3)
        text: "New Game: Extreme"
        bgColor: "#771111"
        textColor: "#ffffff"
        click: @newExtreme.bind(this)
      reset:
        pos: buttonPos(4)
        text: "Reset Puzzle"
        bgColor: "#773377"
        textColor: "#ffffff"
        click: @reset.bind(this)
      import:
        pos: buttonPos(5)
        text: "Load Puzzle"
        bgColor: "#336666"
        textColor: "#ffffff"
        click: @import.bind(this)
      export:
        pos: buttonPos(6)
        text: "Share Puzzle"
        bgColor: "#336666"
        textColor: "#ffffff"
        click: @export.bind(this)
      resume:
        pos: buttonPos(7)
        text: "Resume"
        bgColor: "#777777"
        textColor: "#ffffff"
        click: @resume.bind(this)

    return

  # Computes sizes and positions from the canvas size
  layout: ->
    buttonWidth = @canvas.width * 0.8
    buttonHeight = @canvas.height * BUTTON_HEIGHT
    buttonX = (@canvas.width - buttonWidth) / 2
    for buttonName, button of @buttons
      button.x = buttonX
      button.y = @canvas.height * button.pos
      button.w = buttonWidth
      button.h = buttonHeight

    @buttonFont = @app.font(buttonHeight * 0.4)
    @titleFont = @app.font(@canvas.height * 0.06)
    @subtitleFont = @app.font(@canvas.height * 0.02)
    return

  draw: ->
    @app.drawFill(0, 0, @canvas.width, @canvas.height, "#333333")

    x = @canvas.width / 2
    shadowOffset = @canvas.height * 0.005

    y1 = @canvas.height * 0.05
    y2 = y1 + @canvas.height * 0.06
    y3 = y2 + @canvas.height * 0.06
    @app.drawTextCentered("Bad Guy", x + shadowOffset, y1 + shadowOffset, @titleFont, "#000000")
    @app.drawTextCentered("Sudoku", x + shadowOffset, y2 + shadowOffset, @titleFont, "#000000")
    @app.drawTextCentered("Bad Guy", x, y1, @titleFont, "#ffffff")
    @app.drawTextCentered("Sudoku", x, y2, @titleFont, "#ffffff")
    @app.drawTextCentered("It's like Sudoku, but you are the bad guy.", x, y3, @subtitleFont, "#ffffff")

    lineWidth = Math.max(1, Math.round(@app.pixelRatio))
    for buttonName, button of @buttons
      r = button.h * 0.3
      @app.drawRoundedRect(button.x + shadowOffset, button.y + shadowOffset, button.w, button.h, r, "black", "black", lineWidth)
      @app.drawRoundedRect(button.x, button.y, button.w, button.h, r, button.bgColor, "#999999", lineWidth)
      @app.drawTextCentered(button.text, button.x + (button.w / 2), button.y + (button.h / 2), @buttonFont, button.textColor)

    @app.drawLowerLeft("#{@app.holeCount()}/81")
    @app.drawVersion()

  click: (x, y) ->
    for buttonName, button of @buttons
      if (x > button.x) && (x < (button.x + button.w)) && (y > button.y) && (y < (button.y + button.h))
        button.click()
        break
    return

  newEasy: ->
    @app.newGame(SudokuGenerator.difficulty.easy)

  newMedium: ->
    @app.newGame(SudokuGenerator.difficulty.medium)

  newHard: ->
    @app.newGame(SudokuGenerator.difficulty.hard)

  newExtreme: ->
    @app.newGame(SudokuGenerator.difficulty.extreme)

  reset: ->
    @app.reset()

  resume: ->
    @app.switchView("sudoku")

  export: ->
    if navigator.share?
      # A cancelled share is not an error
      navigator.share({ title: "Sudoku Shared Game", text: @app.export() }).catch(->)
      return
    window.prompt("Copy this and paste to a friend:", @app.export())

  import: ->
    importString = window.prompt("Paste an exported game here:", "")
    loop
      if importString == null
        return
      if @app.import(importString)
        @app.switchView("sudoku")
        return
      importString = window.prompt("Invalid game, try again:", "")

module.exports = MenuView
