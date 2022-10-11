browserify = require 'browserify'
coffeeify = require 'coffeeify'
uglifyify = require 'uglifyify'
nodeStatic = require 'node-static'

fs = require 'fs'
path = require 'path'
{spawn} = require 'child_process'
util = require 'util'
watch = require 'node-watch'

coffeeName = 'coffee'
if process.platform == 'win32'
  coffeeName += '.cmd'

buildGame = (callback) ->
  # equal of command line $ "browserify --debug -t coffeeify ./src/main.coffee > bundle.js "
  productionBuild = (process.env.NODE_ENV == 'production')
  opts = {
    extensions: ['.coffee']
  }
  if not productionBuild
    opts.debug = true
  b = browserify opts
  b.add './game/src/main.coffee'
  b.transform coffeeify
  if productionBuild
    b.transform { global: true, ignore: ['**/main.*'] }, uglifyify
  b.bundle (err, result) ->
    if not err
      fs.writeFile "game/lib/index.js", result, (err) ->
        if not err
          util.log "Game compilation finished."
          callback?()
        else
          util.log "\x07Game bundle write failed: " + err
    else
      util.log "\x07Game compilation failed: " + err

buildWebSolver = (callback) ->
  # equal of command line $ "browserify --debug -t coffeeify ./src/websolver.coffee > bundle.js "
  productionBuild = (process.env.NODE_ENV == 'production')
  opts = {
    extensions: ['.coffee']
  }
  if not productionBuild
    opts.debug = true
  b = browserify opts
  b.add './game/src/websolver.coffee'
  b.transform coffeeify
  if productionBuild
    b.transform { global: true, ignore: ['**/websolver.*'] }, uglifyify
  b.bundle (err, result) ->
    if not err
      fs.writeFile "game/lib/websolver.js", result, (err) ->
        if not err
          util.log "Web solver compilation finished."
          callback?()
        else
          util.log "\x07Web solver bundle write failed: " + err
    else
      util.log "\x07Web solver compilation failed: " + err

buildSolver = (callback) ->
  # equal of command line $ "browserify --debug -t coffeeify ./src/main.coffee > bundle.js "
  productionBuild = (process.env.NODE_ENV == 'production')
  opts = {
    extensions: ['.coffee']
    detectGlobals: false
    insertGlobals: false
  }
  if not productionBuild
    opts.debug = true
  b = browserify opts
  b.add './game/src/solver.coffee'
  b.transform coffeeify
  if productionBuild
    b.transform { global: true, ignore: ['**/main.*'] }, uglifyify
  b.bundle (err, result) ->
    if not err
      fs.writeFile "solver.js", result, (err) ->
        if not err
          util.log "Solver compilation finished."
          callback?()
        else
          util.log "\x07Solver bundle write failed: " + err
    else
      util.log "\x07Solver compilation failed: " + err

buildVersion = (callback) ->
  gameVersion = getVersion()
  source = """
    module.exports = "#{gameVersion}"
  """
  versionFilename = "./game/src/version.coffee"
  sourceOnDisk = fs.readFileSync(versionFilename, "utf8")
  if source != sourceOnDisk
    fs.writeFileSync(versionFilename, source)
    util.log "Updated version to #{gameVersion}"
  callback?()

buildEverything = (callback) ->
  buildVersion ->
    buildGame ->
      buildWebSolver ->
        buildSolver ->
          buildAppCache ->
            callback?()

getVersion = ->
  return JSON.parse(fs.readFileSync("package.json", "utf8")).version

buildAppCache = (callback) ->
  callback?()

  # gameVersion = getVersion()
  # manifest = """
  #   CACHE MANIFEST

  #   # version #{gameVersion}

  #   CACHE:
  #   index.html
  #   lib/index.js

  # """
  # fs.writeFile "game/game.appcache", manifest, (err) ->
  #   if not err
  #     util.log "Appcache generation finished. (#{gameVersion})"
  #     callback?()
  #   else
  #     util.log "Appcache write failed: " + err

watchEverything = ->
  util.log "Watching for changes in src"
  watch ['game/src','package.json'], (filename) ->
    coffeeFileRegex = /\.coffee$/
    if coffeeFileRegex.test(filename) || (filename == 'package.json')
      util.log "Source code #{filename} changed."
      util.log "Regenerating bundle..."
      buildEverything()
  buildEverything()

task 'build', 'build game', (options) ->
  buildEverything()

task 'watch', 'Run dev server and watch for changed source files to automatically rebuild', (options) ->
  watchEverything()

task 'serve', 'serve game and watch', (options) ->
  console.log "nodeStatic #{Object.keys(nodeStatic)}"
  fileServer = new nodeStatic.Server('./game', { cache: 0 })
  require('http').createServer( (request, response) ->
    request.addListener('end', ->
      util.log "Serving #{request.url}"
      fileServer.serve(request, response)
    ).resume()
  ).listen(8080)
  util.log "Listening on port 8080"
  watchEverything()
