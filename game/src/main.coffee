App = require './App'

init = ->
  canvas = document.createElement("canvas")
  document.body.insertBefore(canvas, document.body.childNodes[0])

  app = window.app = new App(canvas)

  # Clicks are reported in canvas pixels
  canvas.addEventListener "pointerdown", (e) ->
    return if not e.isPrimary or e.button != 0
    rect = canvas.getBoundingClientRect()
    x = (e.clientX - rect.left) * canvas.width / rect.width
    y = (e.clientY - rect.top) * canvas.height / rect.height
    app.click(x, y)

  # The help popup closes with its button or a click outside of it
  help = document.getElementById("help")
  document.getElementById("helpClose").addEventListener "click", -> help.close()
  help.addEventListener "click", (e) -> help.close() if e.target is help

  document.addEventListener 'keydown', (e) ->
    return if e.ctrlKey or e.altKey or e.metaKey or help.open
    app.key(e.key)

  window.addEventListener 'resize', ->
    app.resize()

  if navigator.serviceWorker?
    navigator.serviceWorker.register('sw.js').catch (e) ->
      console.log "Service worker registration failed: #{e.message}"

window.addEventListener 'load', init, false
