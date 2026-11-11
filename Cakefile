esbuild = require 'esbuild'
CoffeeScript = require 'coffeescript'
fs = require 'fs'

production = process.env.NODE_ENV == 'production'
{ version } = JSON.parse(fs.readFileSync('package.json', 'utf8'))

SERVE_DIR = 'game'
SERVE_PORT = 8080

# Bundles to build
targets = [
  { entryPoints: ['game/src/main.coffee'],      outfile: 'game/lib/index.js',     platform: 'browser' }
  { entryPoints: ['game/src/websolver.coffee'], outfile: 'game/lib/websolver.js', platform: 'browser' }
  { entryPoints: ['game/src/sw.coffee'],        outfile: 'game/sw.js',            platform: 'browser' }
  { entryPoints: ['game/src/solver.coffee'],    outfile: 'solver.js',             platform: 'node' }
]

# Compiles CoffeeScript sources for esbuild
coffeePlugin =
  name: 'coffee'
  setup: (build) ->
    build.onLoad { filter: /\.coffee$/ }, (args) ->
      source = fs.readFileSync(args.path, 'utf8')
      try
        contents = CoffeeScript.compile(source, { filename: args.path, bare: true, inlineMap: not production })
        return { contents, loader: 'js' }
      catch e
        location = { file: args.path }
        if e.location?
          location.line = e.location.first_line + 1
          location.column = e.location.first_column
        return { errors: [{ text: e.message, location }] }

# Returns the esbuild options for a target
buildOptions = (target) ->
  Object.assign {
    bundle: true
    minify: production
    sourcemap: if production then false else 'inline'
    resolveExtensions: ['.coffee', '.js']
    define: { VERSION: JSON.stringify(version) }
    plugins: [coffeePlugin]
    logLevel: 'info'
  }, target

# Builds everything once
build = ->
  Promise.all(esbuild.build(buildOptions(target)) for target in targets)

# Rebuilds whenever a source file changes
watch = ->
  contexts = await Promise.all(esbuild.context(buildOptions(target)) for target in targets)
  await Promise.all(context.watch() for context in contexts)
  return contexts

# Errors are already reported by esbuild
fail = ->
  process.exitCode = 1

task 'build', 'Build everything (set NODE_ENV=production to minify)', ->
  build().catch(fail)

task 'watch', 'Rebuild whenever a source file changes', ->
  watch().catch(fail)

task 'serve', 'Serve the game and rebuild whenever a source file changes', ->
  watch()
    .then (contexts) -> contexts[0].serve({ servedir: SERVE_DIR, port: SERVE_PORT })
    .catch(fail)
