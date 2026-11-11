# Bad Guy Sudoku

*It's like Sudoku, but you are the bad guy.*

[![CI](https://github.com/jambolo/sudokujs/actions/workflows/ci.yml/badge.svg)](https://github.com/jambolo/sudokujs/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/jambolo/sudokujs/graph/badge.svg)](https://codecov.io/gh/jambolo/sudokujs)

A Sudoku game that runs in the browser. It is drawn on a single canvas, sized for a phone held upright, and can be installed as an
app that works offline.

- Four difficulty levels: easy, medium, hard, and extreme
- Pen for answers and pencil for notes
- Highlighting of a cell's row, column, and box, and of every copy of a number
- Checking of answers and notes against the solution
- Links between notes, for advanced solving techniques
- Unlimited undo and redo
- Automatic saving in the browser
- Sharing and loading of puzzles as text codes
- Keyboard shortcuts

Full instructions are in [game/help.html](game/help.html), which the `?` button in the game displays.

## Requirements

- Node.js 18 or later

## Build

```sh
npm install
npm run build
```

For a minified build without source maps:

```sh
NODE_ENV=production npm run build
```

The build produces these files, none of which are checked in:

| File | Purpose |
| --- | --- |
| `game/lib/index.js` | The game |
| `game/sw.js` | Service worker for offline play |
| `game/lib/websolver.js` | Solver used by `game/solver.html` |
| `solver.js` | Command line solver |

### Other commands

| Command | Purpose |
| --- | --- |
| `npm run watch` | Rebuild whenever a source file changes |
| `npm run serve` | Serve the game at <http://localhost:8080> and rebuild whenever a source file changes |
| `npm test` | Run the tests |
| `npm run coverage` | Run the tests and report coverage in `coverage/` |
| `npm run lint` | Check the source with CoffeeLint |

## Deploy

The game is a static site. Nothing runs on the server.

Pushing to `master` deploys the game to GitHub Pages with the [CD workflow](.github/workflows/cd.yml). Set `version` in
`package.json` first, as described below.

To deploy it elsewhere:

1. Set `version` in `package.json`. The version names the offline cache, so a new version replaces the files cached by installed
   copies.
2. Make a production build.
3. Copy the contents of `game/`, except `game/src/`, to any static web host.

The host must serve the site over HTTPS. Without it, the service worker does not register, and the game cannot be installed or
played offline. `localhost` is exempt, so `npm run serve` works for local testing.

The game can be served from any path. All of its URLs are relative.

## Solver

A solver for shared puzzle codes is included in two forms:

- `game/solver.html` — a web page, deployed with the game
- `solver.js` — a command line tool: `node solver.js <puzzle code>`

## License

[BSL-1.0](https://www.boost.org/LICENSE_1_0.txt)
