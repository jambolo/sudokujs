(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
var Board, SudokuGenerator, shuffle;

shuffle = function(a) {
  var i, j, t;
  i = a.length;
  while (--i > 0) {
    j = ~~(Math.random() * (i + 1));
    t = a[j];
    a[j] = a[i];
    a[i] = t;
  }
  return a;
};

Board = class Board {
  constructor(otherBoard = null) {
    var i, j, l, m, n;
    this.lockedCount = 0;
    this.grid = new Array(9).fill(null);
    this.locked = new Array(9).fill(null);
    for (i = l = 0; l < 9; i = ++l) {
      this.grid[i] = new Array(9).fill(0);
      this.locked[i] = new Array(9).fill(false);
    }
    if (otherBoard !== null) {
      for (j = m = 0; m < 9; j = ++m) {
        for (i = n = 0; n < 9; i = ++n) {
          this.grid[i][j] = otherBoard.grid[i][j];
          this.lock(i, j, otherBoard.locked[i][j]);
        }
      }
    }
    return;
  }

  matches(otherBoard) {
    var i, j, l, m;
    for (j = l = 0; l < 9; j = ++l) {
      for (i = m = 0; m < 9; i = ++m) {
        if (this.grid[i][j] !== otherBoard.grid[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  lock(x, y, v = true) {
    if (v) {
      if (!this.locked[x][y]) {
        this.lockedCount += 1;
      }
    } else {
      if (this.locked[x][y]) {
        this.lockedCount -= 1;
      }
    }
    return this.locked[x][y] = v;
  }

};

SudokuGenerator = (function() {
  class SudokuGenerator {
    constructor() {}

    boardToGrid(board) {
      var i, j, l, m, n, newBoard;
      newBoard = new Array(9).fill(null);
      for (i = l = 0; l < 9; i = ++l) {
        newBoard[i] = new Array(9).fill(0);
      }
      for (j = m = 0; m < 9; j = ++m) {
        for (i = n = 0; n < 9; i = ++n) {
          if (board.locked[i][j]) {
            newBoard[i][j] = board.grid[i][j];
          }
        }
      }
      return newBoard;
    }

    gridToBoard(grid) {
      var board, l, m, x, y;
      board = new Board();
      for (y = l = 0; l < 9; y = ++l) {
        for (x = m = 0; m < 9; x = ++m) {
          if (grid[x][y] > 0) {
            board.grid[x][y] = grid[x][y];
            board.lock(x, y);
          }
        }
      }
      return board;
    }

    cellValid(board, x, y, v) {
      var i, j, l, m, n, sx, sy;
      if (board.locked[x][y]) {
        return board.grid[x][y] === v;
      }
      for (i = l = 0; l < 9; i = ++l) {
        if ((x !== i) && (board.grid[i][y] === v)) {
          return false;
        }
        if ((y !== i) && (board.grid[x][i] === v)) {
          return false;
        }
      }
      sx = Math.floor(x / 3) * 3;
      sy = Math.floor(y / 3) * 3;
      for (j = m = 0; m < 3; j = ++m) {
        for (i = n = 0; n < 3; i = ++n) {
          if ((x !== (sx + i)) && (y !== (sy + j))) {
            if (board.grid[sx + i][sy + j] === v) {
              return false;
            }
          }
        }
      }
      return true;
    }

    pencilMarks(board, x, y) {
      var l, marks, v;
      if (board.locked[x][y]) {
        return [board.grid[x][y]];
      }
      marks = [];
      for (v = l = 1; l <= 9; v = ++l) {
        if (this.cellValid(board, x, y, v)) {
          marks.push(v);
        }
      }
      if (marks.length > 1) {
        shuffle(marks);
      }
      return marks;
    }

    nextAttempt(board, attempts) {
      var a, fewestIndex, fewestMarks, index, k, l, len, len1, m, marks, n, remainingIndexes, x, y;
      remainingIndexes = (function() {
        var results = [];
        for (var l = 0; l < 81; l++){ results.push(l); }
        return results;
      }).apply(this);
// skip locked cells
      for (index = l = 0; l < 81; index = ++l) {
        x = index % 9;
        y = Math.floor(index / 9);
        if (board.locked[x][y]) {
          k = remainingIndexes.indexOf(index);
          if (k >= 0) {
            remainingIndexes.splice(k, 1);
          }
        }
      }
// skip cells that are already being tried
      for (m = 0, len = attempts.length; m < len; m++) {
        a = attempts[m];
        k = remainingIndexes.indexOf(a.index);
        if (k >= 0) {
          remainingIndexes.splice(k, 1);
        }
      }
      if (remainingIndexes.length === 0) { // abort if there are no cells (should never happen)
        return null;
      }
      fewestIndex = -1;
      fewestMarks = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
      for (n = 0, len1 = remainingIndexes.length; n < len1; n++) {
        index = remainingIndexes[n];
        x = index % 9;
        y = Math.floor(index / 9);
        marks = this.pencilMarks(board, x, y);
        if (marks.length === 0) {
          // abort if there is a cell with no possibilities
          return null;
        }
        if (marks.length === 1) {
          return {
            // done if there is a cell with only one possibility ()
            index: index,
            remaining: marks
          };
        }
        // remember this cell if it has the fewest marks so far
        if (marks.length < fewestMarks.length) {
          fewestIndex = index;
          fewestMarks = marks;
        }
      }
      return {
        index: fewestIndex,
        remaining: fewestMarks
      };
    }

    solve(board) {
      var attempts, solved;
      solved = new Board(board);
      attempts = [];
      return this.solveInternal(solved, attempts);
    }

    hasUniqueSolution(board) {
      var attempts, solved, unlockedCount;
      solved = new Board(board);
      attempts = [];
      if (this.solveInternal(solved, attempts) === null) {
        // if there is no solution, return false
        return false;
      }
      unlockedCount = 81 - solved.lockedCount;
      if (unlockedCount === 0) {
        // if there are no unlocked cells, then this solution must be unique
        return true;
      }
      // check for a second solution
      return this.solveInternal(solved, attempts, unlockedCount - 1) === null;
    }

    solveInternal(solved, attempts, walkIndex = 0) {
      var attempt, unlockedCount, x, y;
      unlockedCount = 81 - solved.lockedCount;
      while (walkIndex < unlockedCount) {
        if (walkIndex >= attempts.length) {
          attempt = this.nextAttempt(solved, attempts);
          if (attempt !== null) {
            attempts.push(attempt);
          }
        } else {
          attempt = attempts[walkIndex];
        }
        if (attempt !== null) {
          x = attempt.index % 9;
          y = Math.floor(attempt.index / 9);
          if (attempt.remaining.length > 0) {
            solved.grid[x][y] = attempt.remaining.pop();
            walkIndex += 1;
          } else {
            attempts.pop();
            solved.grid[x][y] = 0;
            walkIndex -= 1;
          }
        } else {
          walkIndex -= 1;
        }
        if (walkIndex < 0) {
          return null;
        }
      }
      return solved;
    }

    generateInternal(amountToRemove) {
      var board, i, indexesToRemove, j, l, m, nextBoard, removeIndex, removed, rx, ry, solution;
      board = this.solve(new Board());
// hack
      for (j = l = 0; l < 9; j = ++l) {
        for (i = m = 0; m < 9; i = ++m) {
          board.lock(i, j);
        }
      }
      solution = new Board(board);
      indexesToRemove = shuffle((function() {
        var results = [];
        for (var n = 0; n < 81; n++){ results.push(n); }
        return results;
      }).apply(this));
      removed = 0;
      while (removed < amountToRemove) {
        if (indexesToRemove.length === 0) {
          break;
        }
        removeIndex = indexesToRemove.pop();
        rx = removeIndex % 9;
        ry = Math.floor(removeIndex / 9);
        nextBoard = new Board(board);
        nextBoard.grid[rx][ry] = 0;
        nextBoard.lock(rx, ry, false);
        if (this.hasUniqueSolution(nextBoard)) {
          board = nextBoard;
          removed += 1;
        } else {

        }
      }
      // console.log "failed to remove #{rx},#{ry}, creates non-unique solution"
      // console.log "successfully removed #{rx},#{ry}"
      return {board, removed, solution};
    }

    generate(difficulty) {
      var amountToRemove, attempt, best, generated, l;
      amountToRemove = (function() {
        switch (difficulty) {
          case SudokuGenerator.difficulty.extreme:
            return 60;
          case SudokuGenerator.difficulty.hard:
            return 52;
          case SudokuGenerator.difficulty.medium:
            return 46;
          default:
            return 40; // easy / unknown
        }
      })();
      best = null;
      for (attempt = l = 0; l < 2; attempt = ++l) {
        generated = this.generateInternal(amountToRemove);
        if (generated.removed === amountToRemove) {
          console.log(`Removed exact amount ${amountToRemove}, stopping`);
          best = generated;
          break;
        }
        if (best === null) {
          best = generated;
        } else if (best.removed < generated.removed) {
          best = generated;
        }
        console.log(`current best ${best.removed} / ${amountToRemove}`);
      }
      console.log(`giving user board: ${best.removed} / ${amountToRemove}`);
      return [this.boardToGrid(best.board), this.boardToGrid(best.solution)];
    }

    // Returns true if any two locked cells in the same row, column, or box have the same value
    hasConflicts(board) {
      var bx, by_, i, l, m, n, sx, sy, v, x, y;
      for (y = l = 0; l < 9; y = ++l) {
        for (x = m = 0; m < 9; x = ++m) {
          if (!board.locked[x][y]) {
            continue;
          }
          v = board.grid[x][y];
          sx = Math.floor(x / 3) * 3;
          sy = Math.floor(y / 3) * 3;
          for (i = n = 0; n < 9; i = ++n) {
            if ((i !== x) && board.locked[i][y] && (board.grid[i][y] === v)) {
              return true;
            }
            if ((i !== y) && board.locked[x][i] && (board.grid[x][i] === v)) {
              return true;
            }
            bx = sx + (i % 3);
            by_ = sy + (Math.floor(i / 3));
            if (((bx !== x) || (by_ !== y)) && board.locked[bx][by_] && (board.grid[bx][by_] === v)) {
              return true;
            }
          }
        }
      }
      return false;
    }

    validateGrid(grid) {
      var board;
      board = this.gridToBoard(grid);
      if (this.hasConflicts(board)) {
        return false;
      }
      return this.hasUniqueSolution(board);
    }

    // Returns the solved grid, or null if there is no solution
    solveGrid(grid) {
      var board, column, solved;
      board = this.gridToBoard(grid);
      if (this.hasConflicts(board)) {
        return null;
      }
      solved = this.solve(board);
      if (solved === null) {
        return null;
      }
      return (function() {
        var l, len, ref, results;
        ref = solved.grid;
        results = [];
        for (l = 0, len = ref.length; l < len; l++) {
          column = ref[l];
          results.push(column.slice());
        }
        return results;
      })();
    }

    solveString(importString) {
      var answerString, board, i, index, j, l, m, n, o, solved, v, zeroCharCode;
      if (importString.indexOf("SD") !== 0) {
        return false;
      }
      importString = importString.substr(2);
      importString = importString.replace(/[^0-9]/g, "");
      if (importString.length !== 81) {
        return false;
      }
      board = new Board();
      index = 0;
      zeroCharCode = "0".charCodeAt(0);
      for (j = l = 0; l < 9; j = ++l) {
        for (i = m = 0; m < 9; i = ++m) {
          v = importString.charCodeAt(index) - zeroCharCode;
          index += 1;
          if (v > 0) {
            board.grid[j][i] = v;
            board.lock(j, i);
          }
        }
      }
      if (this.hasConflicts(board)) {
        console.log("ERROR: Conflicting givens.");
        return false;
      }
      solved = this.solve(board);
      if (solved === null) {
        console.log("ERROR: Can't be solved.");
        return false;
      }
      if (!this.hasUniqueSolution(board)) {
        console.log("ERROR: Board solve not unique.");
        return false;
      }
      answerString = "";
      for (j = n = 0; n < 9; j = ++n) {
        for (i = o = 0; o < 9; i = ++o) {
          answerString += `${solved.grid[j][i]} `;
        }
        answerString += "\n";
      }
      return answerString;
    }

  };

  SudokuGenerator.difficulty = {
    easy: 1,
    medium: 2,
    hard: 3,
    extreme: 4
  };

  return SudokuGenerator;

}).call(this);

module.exports = SudokuGenerator;


},{}],2:[function(require,module,exports){
var SudokuGenerator;

SudokuGenerator = require('./SudokuGenerator');

window.solve = function(arg) {
  var gen;
  gen = new SudokuGenerator();
  return gen.solveString(arg);
};

window.qs = function(name) {
  var regex, results, url;
  url = window.location.href;
  name = name.replace(/[\[\]]/g, '\\$&');
  regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)');
  results = regex.exec(url);
  if (!results || !results[2]) {
    return null;
  }
  return decodeURIComponent(results[2].replace(/\+/g, ' '));
};


},{"./SudokuGenerator":1}]},{},[2])
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJnYW1lL3NyYy9TdWRva3VHZW5lcmF0b3IuY29mZmVlIiwiZ2FtZS9zcmMvd2Vic29sdmVyLmNvZmZlZSJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBLElBQUEsS0FBQSxFQUFBLGVBQUEsRUFBQTs7QUFBQSxPQUFBLEdBQVUsUUFBQSxDQUFDLENBQUQsQ0FBQTtBQUNWLE1BQUEsQ0FBQSxFQUFBLENBQUEsRUFBQTtFQUFJLENBQUEsR0FBSSxDQUFDLENBQUM7QUFDTixTQUFNLEVBQUUsQ0FBRixHQUFNLENBQVo7SUFDSSxDQUFBLEdBQUksQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLE1BQUwsQ0FBQSxDQUFBLEdBQWdCLENBQUMsQ0FBQSxHQUFJLENBQUwsQ0FBakI7SUFDTixDQUFBLEdBQUksQ0FBQyxDQUFDLENBQUQ7SUFDTCxDQUFDLENBQUMsQ0FBRCxDQUFELEdBQU8sQ0FBQyxDQUFDLENBQUQ7SUFDUixDQUFDLENBQUMsQ0FBRCxDQUFELEdBQU87RUFKWDtBQUtBLFNBQU87QUFQRDs7QUFTSixRQUFOLE1BQUEsTUFBQTtFQUNFLFdBQWEsQ0FBQyxhQUFhLElBQWQsQ0FBQTtBQUNmLFFBQUEsQ0FBQSxFQUFBLENBQUEsRUFBQSxDQUFBLEVBQUEsQ0FBQSxFQUFBO0lBQUksSUFBQyxDQUFBLFdBQUQsR0FBZTtJQUNmLElBQUMsQ0FBQSxJQUFELEdBQVEsSUFBSSxLQUFKLENBQVUsQ0FBVixDQUFZLENBQUMsSUFBYixDQUFrQixJQUFsQjtJQUNSLElBQUMsQ0FBQSxNQUFELEdBQVUsSUFBSSxLQUFKLENBQVUsQ0FBVixDQUFZLENBQUMsSUFBYixDQUFrQixJQUFsQjtJQUNWLEtBQVMseUJBQVQ7TUFDRSxJQUFDLENBQUEsSUFBSSxDQUFDLENBQUQsQ0FBTCxHQUFXLElBQUksS0FBSixDQUFVLENBQVYsQ0FBWSxDQUFDLElBQWIsQ0FBa0IsQ0FBbEI7TUFDWCxJQUFD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QjtBQUNFLFdBQU8sS0FEVDs7QUFFQSxTQUFPLGtCQUFBLENBQW1CLE9BQU8sQ0FBQyxDQUFELENBQUcsQ0FBQyxPQUFYLENBQW1CLEtBQW5CLEVBQTBCLEdBQTFCLENBQW5CO0FBUEciLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIihmdW5jdGlvbigpe2Z1bmN0aW9uIHIoZSxuLHQpe2Z1bmN0aW9uIG8oaSxmKXtpZighbltpXSl7aWYoIWVbaV0pe3ZhciBjPVwiZnVuY3Rpb25cIj09dHlwZW9mIHJlcXVpcmUmJnJlcXVpcmU7aWYoIWYmJmMpcmV0dXJuIGMoaSwhMCk7aWYodSlyZXR1cm4gdShpLCEwKTt2YXIgYT1uZXcgRXJyb3IoXCJDYW5ub3QgZmluZCBtb2R1bGUgJ1wiK2krXCInXCIpO3Rocm93IGEuY29kZT1cIk1PRFVMRV9OT1RfRk9VTkRcIixhfXZhciBwPW5baV09e2V4cG9ydHM6e319O2VbaV1bMF0uY2FsbChwLmV4cG9ydHMsZnVuY3Rpb24ocil7dmFyIG49ZVtpXVsxXVtyXTtyZXR1cm4gbyhufHxyKX0scCxwLmV4cG9ydHMscixlLG4sdCl9cmV0dXJuIG5baV0uZXhwb3J0c31mb3IodmFyIHU9XCJmdW5jdGlvblwiPT10eXBlb2YgcmVxdWlyZSYmcmVxdWlyZSxpPTA7aTx0Lmxlbmd0aDtpKyspbyh0W2ldKTtyZXR1cm4gb31yZXR1cm4gcn0pKCkiLCJzaHVmZmxlID0gKGEpIC0+XG4gICAgaSA9IGEubGVuZ3RoXG4gICAgd2hpbGUgLS1pID4gMFxuICAgICAgICBqID0gfn4oTWF0aC5yYW5kb20oKSAqIChpICsgMSkpXG4gICAgICAgIHQgPSBhW2pdXG4gICAgICAgIGFbal0gPSBhW2ldXG4gICAgICAgIGFbaV0gPSB0XG4gICAgcmV0dXJuIGFcblxuY2xhc3MgQm9hcmRcbiAgY29uc3RydWN0b3I6IChvdGhlckJvYXJkID0gbnVsbCkgLT5cbiAgICBAbG9ja2VkQ291bnQgPSAwXG4gICAgQGdyaWQgPSBuZXcgQXJyYXkoOSkuZmlsbChudWxsKVxuICAgIEBsb2NrZWQgPSBuZXcgQXJyYXkoOSkuZmlsbChudWxsKVxuICAgIGZvciBpIGluIFswLi4uOV1cbiAgICAgIEBncmlkW2ldID0gbmV3IEFycmF5KDkpLmZpbGwoMClcbiAgICAgIEBsb2NrZWRbaV0gPSBuZXcgQXJyYXkoOSkuZmlsbChmYWxzZSlcbiAgICBpZiBvdGhlckJvYXJkICE9IG51bGxcbiAgICAgIGZvciBqIGluIFswLi4uOV1cbiAgICAgICAgZm9yIGkgaW4gWzAuLi45XVxuICAgICAgICAgIEBncmlkW2ldW2pdID0gb3RoZXJCb2FyZC5ncmlkW2ldW2pdXG4gICAgICAgICAgQGxvY2soaSwgaiwgb3RoZXJCb2FyZC5sb2NrZWRbaV1bal0pXG4gICAgcmV0dXJuXG5cbiAgbWF0Y2hlczogKG90aGVyQm9hcmQpIC0+XG4gICAgZm9yIGogaW4gWzAuLi45XVxuICAgICAgZm9yIGkgaW4gWzAuLi45XVxuICAgICAgICBpZiBAZ3JpZFtpXVtqXSAhPSBvdGhlckJvYXJkLmdyaWRbaV1bal1cbiAgICAgICAgICByZXR1cm4gZmFsc2VcbiAgICByZXR1cm4gdHJ1ZVxuXG4gIGxvY2s6ICh4LCB5LCB2ID0gdHJ1ZSkgLT5cbiAgICBpZiB2XG4gICAgICBAbG9ja2VkQ291bnQgKz0gMSBpZiBub3QgQGxvY2tlZFt4XVt5XVxuICAgIGVsc2VcbiAgICAgIEBsb2NrZWRDb3VudCAtPSAxIGlmIEBsb2NrZWRbeF1beV1cbiAgICBAbG9ja2VkW3hdW3ldID0gdlxuXG5cbmNsYXNzIFN1ZG9rdUdlbmVyYXRvclxuICBAZGlmZmljdWx0eTpcbiAgICBlYXN5OiAxXG4gICAgbWVkaXVtOiAyXG4gICAgaGFyZDogM1xuICAgIGV4dHJlbWU6IDRcblxuICBjb25zdHJ1Y3RvcjogLT5cblxuICBib2FyZFRvR3JpZDogKGJvYXJkKSAtPlxuICAgIG5ld0JvYXJkID0gbmV3IEFycmF5KDkpLmZpbGwobnVsbClcbiAgICBmb3IgaSBpbiBbMC4uLjldXG4gICAgICBuZXdCb2FyZFtpXSA9IG5ldyBBcnJheSg5KS5maWxsKDApXG4gICAgZm9yIGogaW4gWzAuLi45XVxuICAgICAgZm9yIGkgaW4gWzAuLi45XVxuICAgICAgICBpZiBib2FyZC5sb2NrZWRbaV1bal1cbiAgICAgICAgICBuZXdCb2FyZFtpXVtqXSA9IGJvYXJkLmdyaWRbaV1bal1cbiAgICByZXR1cm4gbmV3Qm9hcmRcblxuICBncmlkVG9Cb2FyZDogKGdyaWQpIC0+XG4gICAgYm9hcmQgPSBuZXcgQm9hcmRcbiAgICBmb3IgeSBpbiBbMC4uLjldXG4gICAgICBmb3IgeCBpbiBbMC4uLjldXG4gICAgICAgIGlmIGdyaWRbeF1beV0gPiAwXG4gICAgICAgICAgYm9hcmQuZ3JpZFt4XVt5XSA9IGdyaWRbeF1beV1cbiAgICAgICAgICBib2FyZC5sb2NrKHgsIHkpXG4gICAgcmV0dXJuIGJvYXJkXG5cbiAgY2VsbFZhbGlkOiAoYm9hcmQsIHgsIHksIHYpIC0+XG4gICAgaWYgYm9hcmQubG9ja2VkW3hdW3ldXG4gICAgICByZXR1cm4gYm9hcmQuZ3JpZFt4XVt5XSA9PSB2XG5cbiAgICBmb3IgaSBpbiBbMC4uLjldXG4gICAgICBpZiAoeCAhPSBpKSBhbmQgKGJvYXJkLmdyaWRbaV1beV0gPT0gdilcbiAgICAgICAgICByZXR1cm4gZmFsc2VcbiAgICAgIGlmICh5ICE9IGkpIGFuZCAoYm9hcmQuZ3JpZFt4XVtpXSA9PSB2KVxuICAgICAgICAgIHJldHVybiBmYWxzZVxuXG4gICAgc3ggPSBNYXRoLmZsb29yKHggLyAzKSAqIDNcbiAgICBzeSA9IE1hdGguZmxvb3IoeSAvIDMpICogM1xuICAgIGZvciBqIGluIFswLi4uM11cbiAgICAgIGZvciBpIGluIFswLi4uM11cbiAgICAgICAgaWYgKHggIT0gKHN4ICsgaSkpICYmICh5ICE9IChzeSArIGopKVxuICAgICAgICAgIGlmIGJvYXJkLmdyaWRbc3ggKyBpXVtzeSArIGpdID09IHZcbiAgICAgICAgICAgIHJldHVybiBmYWxzZVxuICAgIHJldHVybiB0cnVlXG5cbiAgcGVuY2lsTWFya3M6IChib2FyZCwgeCwgeSkgLT5cbiAgICBpZiBib2FyZC5sb2NrZWRbeF1beV1cbiAgICAgIHJldHVybiBbIGJvYXJkLmdyaWRbeF1beV0gXVxuICAgIG1hcmtzID0gW11cbiAgICBmb3IgdiBpbiBbMS4uOV1cbiAgICAgIGlmIEBjZWxsVmFsaWQoYm9hcmQsIHgsIHksIHYpXG4gICAgICAgIG1hcmtzLnB1c2ggdlxuICAgIGlmIG1hcmtzLmxlbmd0aCA+IDFcbiAgICAgIHNodWZmbGUobWFya3MpXG4gICAgcmV0dXJuIG1hcmtzXG5cbiAgbmV4dEF0dGVtcHQ6IChib2FyZCwgYXR0ZW1wdHMpIC0+XG4gICAgcmVtYWluaW5nSW5kZXhlcyA9IFswLi4uODFdXG5cbiAgICAjIHNraXAgbG9ja2VkIGNlbGxzXG4gICAgZm9yIGluZGV4IGluIFswLi4uODFdXG4gICAgICB4ID0gaW5kZXggJSA5XG4gICAgICB5ID0gaW5kZXggLy8gOVxuICAgICAgaWYgYm9hcmQubG9ja2VkW3hdW3ldXG4gICAgICAgIGsgPSByZW1haW5pbmdJbmRleGVzLmluZGV4T2YoaW5kZXgpXG4gICAgICAgIHJlbWFpbmluZ0luZGV4ZXMuc3BsaWNlKGssIDEpIGlmIGsgPj0gMFxuXG4gICAgIyBza2lwIGNlbGxzIHRoYXQgYXJlIGFscmVhZHkgYmVpbmcgdHJpZWRcbiAgICBmb3IgYSBpbiBhdHRlbXB0c1xuICAgICAgayA9IHJlbWFpbmluZ0luZGV4ZXMuaW5kZXhPZihhLmluZGV4KVxuICAgICAgcmVtYWluaW5nSW5kZXhlcy5zcGxpY2UoaywgMSkgaWYgayA+PSAwXG5cbiAgICByZXR1cm4gbnVsbCBpZiByZW1haW5pbmdJbmRleGVzLmxlbmd0aCA9PSAwICMgYWJvcnQgaWYgdGhlcmUgYXJlIG5vIGNlbGxzIChzaG91bGQgbmV2ZXIgaGFwcGVuKVxuXG4gICAgZmV3ZXN0SW5kZXggPSAtMVxuICAgIGZld2VzdE1hcmtzID0gWzAuLjldXG4gICAgZm9yIGluZGV4IGluIHJlbWFpbmluZ0luZGV4ZXNcbiAgICAgIHggPSBpbmRleCAlIDlcbiAgICAgIHkgPSBpbmRleCAvLyA5XG4gICAgICBtYXJrcyA9IEBwZW5jaWxNYXJrcyhib2FyZCwgeCwgeSlcblxuICAgICAgIyBhYm9ydCBpZiB0aGVyZSBpcyBhIGNlbGwgd2l0aCBubyBwb3NzaWJpbGl0aWVzXG4gICAgICByZXR1cm4gbnVsbCBpZiBtYXJrcy5sZW5ndGggPT0gMFxuXG4gICAgICAjIGRvbmUgaWYgdGhlcmUgaXMgYSBjZWxsIHdpdGggb25seSBvbmUgcG9zc2liaWxpdHkgKClcbiAgICAgIHJldHVybiB7IGluZGV4OiBpbmRleCwgcmVtYWluaW5nOiBtYXJrcyB9IGlmIG1hcmtzLmxlbmd0aCA9PSAxXG5cbiAgICAgICMgcmVtZW1iZXIgdGhpcyBjZWxsIGlmIGl0IGhhcyB0aGUgZmV3ZXN0IG1hcmtzIHNvIGZhclxuICAgICAgaWYgbWFya3MubGVuZ3RoIDwgZmV3ZXN0TWFya3MubGVuZ3RoXG4gICAgICAgIGZld2VzdEluZGV4ID0gaW5kZXhcbiAgICAgICAgZmV3ZXN0TWFya3MgPSBtYXJrc1xuICAgIHJldHVybiB7IGluZGV4OiBmZXdlc3RJbmRleCwgcmVtYWluaW5nOiBmZXdlc3RNYXJrcyB9XG5cbiAgc29sdmU6IChib2FyZCkgLT5cbiAgICBzb2x2ZWQgPSBuZXcgQm9hcmQoYm9hcmQpXG4gICAgYXR0ZW1wdHMgPSBbXVxuICAgIHJldHVybiBAc29sdmVJbnRlcm5hbChzb2x2ZWQsIGF0dGVtcHRzKVxuXG4gIGhhc1VuaXF1ZVNvbHV0aW9uOiAoYm9hcmQpIC0+XG4gICAgc29sdmVkID0gbmV3IEJvYXJkKGJvYXJkKVxuICAgIGF0dGVtcHRzID0gW11cblxuICAgICMgaWYgdGhlcmUgaXMgbm8gc29sdXRpb24sIHJldHVybiBmYWxzZVxuICAgIHJldHVybiBmYWxzZSBpZiBAc29sdmVJbnRlcm5hbChzb2x2ZWQsIGF0dGVtcHRzKSA9PSBudWxsXG5cbiAgICB1bmxvY2tlZENvdW50ID0gODEgLSBzb2x2ZWQubG9ja2VkQ291bnRcblxuICAgICMgaWYgdGhlcmUgYXJlIG5vIHVubG9ja2VkIGNlbGxzLCB0aGVuIHRoaXMgc29sdXRpb24gbXVzdCBiZSB1bmlxdWVcbiAgICByZXR1cm4gdHJ1ZSBpZiB1bmxvY2tlZENvdW50ID09IDBcblxuICAgICMgY2hlY2sgZm9yIGEgc2Vjb25kIHNvbHV0aW9uXG4gICAgcmV0dXJuIEBzb2x2ZUludGVybmFsKHNvbHZlZCwgYXR0ZW1wdHMsIHVubG9ja2VkQ291bnQgLSAxKSA9PSBudWxsXG5cbiAgc29sdmVJbnRlcm5hbDogKHNvbHZlZCwgYXR0ZW1wdHMsIHdhbGtJbmRleCA9IDApIC0+XG4gICAgdW5sb2NrZWRDb3VudCA9IDgxIC0gc29sdmVkLmxvY2tlZENvdW50XG4gICAgd2hpbGUgd2Fsa0luZGV4IDwgdW5sb2NrZWRDb3VudFxuICAgICAgaWYgd2Fsa0luZGV4ID49IGF0dGVtcHRzLmxlbmd0aFxuICAgICAgICBhdHRlbXB0ID0gQG5leHRBdHRlbXB0KHNvbHZlZCwgYXR0ZW1wdHMpXG4gICAgICAgIGF0dGVtcHRzLnB1c2goYXR0ZW1wdCkgaWYgYXR0ZW1wdCAhPSBudWxsXG4gICAgICBlbHNlXG4gICAgICAgIGF0dGVtcHQgPSBhdHRlbXB0c1t3YWxrSW5kZXhdXG5cbiAgICAgIGlmIGF0dGVtcHQgIT0gbnVsbFxuICAgICAgICB4ID0gYXR0ZW1wdC5pbmRleCAlIDlcbiAgICAgICAgeSA9IGF0dGVtcHQuaW5kZXggLy8gOVxuICAgICAgICBpZiBhdHRlbXB0LnJlbWFpbmluZy5sZW5ndGggPiAwXG4gICAgICAgICAgc29sdmVkLmdyaWRbeF1beV0gPSBhdHRlbXB0LnJlbWFpbmluZy5wb3AoKVxuICAgICAgICAgIHdhbGtJbmRleCArPSAxXG4gICAgICAgIGVsc2VcbiAgICAgICAgICBhdHRlbXB0cy5wb3AoKVxuICAgICAgICAgIHNvbHZlZC5ncmlkW3hdW3ldID0gMFxuICAgICAgICAgIHdhbGtJbmRleCAtPSAxXG4gICAgICBlbHNlXG4gICAgICAgIHdhbGtJbmRleCAtPSAxXG5cbiAgICAgIGlmIHdhbGtJbmRleCA8IDBcbiAgICAgICAgcmV0dXJuIG51bGxcblxuICAgIHJldHVybiBzb2x2ZWRcblxuICBnZW5lcmF0ZUludGVybmFsOiAoYW1vdW50VG9SZW1vdmUpIC0+XG4gICAgYm9hcmQgPSBAc29sdmUobmV3IEJvYXJkKCkpXG4gICAgIyBoYWNrXG4gICAgZm9yIGogaW4gWzAuLi45XVxuICAgICAgZm9yIGkgaW4gWzAuLi45XVxuICAgICAgICBib2FyZC5sb2NrKGksIGopXG5cbiAgICBzb2x1dGlvbiA9IG5ldyBCb2FyZChib2FyZClcblxuICAgIGluZGV4ZXNUb1JlbW92ZSA9IHNodWZmbGUoWzAuLi44MV0pXG4gICAgcmVtb3ZlZCA9IDBcbiAgICB3aGlsZSByZW1vdmVkIDwgYW1vdW50VG9SZW1vdmVcbiAgICAgIGlmIGluZGV4ZXNUb1JlbW92ZS5sZW5ndGggPT0gMFxuICAgICAgICBicmVha1xuXG4gICAgICByZW1vdmVJbmRleCA9IGluZGV4ZXNUb1JlbW92ZS5wb3AoKVxuICAgICAgcnggPSByZW1vdmVJbmRleCAlIDlcbiAgICAgIHJ5ID0gTWF0aC5mbG9vcihyZW1vdmVJbmRleCAvIDkpXG5cbiAgICAgIG5leHRCb2FyZCA9IG5ldyBCb2FyZChib2FyZClcbiAgICAgIG5leHRCb2FyZC5ncmlkW3J4XVtyeV0gPSAwXG4gICAgICBuZXh0Qm9hcmQubG9jayhyeCwgcnksIGZhbHNlKVxuXG4gICAgICBpZiBAaGFzVW5pcXVlU29sdXRpb24obmV4dEJvYXJkKVxuICAgICAgICBib2FyZCA9IG5leHRCb2FyZFxuICAgICAgICByZW1vdmVkICs9IDFcbiAgICAgICAgIyBjb25zb2xlLmxvZyBcInN1Y2Nlc3NmdWxseSByZW1vdmVkICN7cnh9LCN7cnl9XCJcbiAgICAgIGVsc2VcbiAgICAgICAgIyBjb25zb2xlLmxvZyBcImZhaWxlZCB0byByZW1vdmUgI3tyeH0sI3tyeX0sIGNyZWF0ZXMgbm9uLXVuaXF1ZSBzb2x1dGlvblwiXG5cbiAgICByZXR1cm4ge1xuICAgICAgYm9hcmRcbiAgICAgIHJlbW92ZWRcbiAgICAgIHNvbHV0aW9uXG4gICAgfVxuXG4gIGdlbmVyYXRlOiAoZGlmZmljdWx0eSkgLT5cbiAgICBhbW91bnRUb1JlbW92ZSA9IHN3aXRjaCBkaWZmaWN1bHR5XG4gICAgICB3aGVuIFN1ZG9rdUdlbmVyYXRvci5kaWZmaWN1bHR5LmV4dHJlbWUgdGhlbiA2MFxuICAgICAgd2hlbiBTdWRva3VHZW5lcmF0b3IuZGlmZmljdWx0eS5oYXJkICAgIHRoZW4gNTJcbiAgICAgIHdoZW4gU3Vkb2t1R2VuZXJhdG9yLmRpZmZpY3VsdHkubWVkaXVtICB0aGVuIDQ2XG4gICAgICBlbHNlIDQwICMgZWFzeSAvIHVua25vd25cblxuICAgIGJlc3QgPSBudWxsXG4gICAgZm9yIGF0dGVtcHQgaW4gWzAuLi4yXVxuICAgICAgZ2VuZXJhdGVkID0gQGdlbmVyYXRlSW50ZXJuYWwoYW1vdW50VG9SZW1vdmUpXG4gICAgICBpZiBnZW5lcmF0ZWQucmVtb3ZlZCA9PSBhbW91bnRUb1JlbW92ZVxuICAgICAgICBjb25zb2xlLmxvZyBcIlJlbW92ZWQgZXhhY3QgYW1vdW50ICN7YW1vdW50VG9SZW1vdmV9LCBzdG9wcGluZ1wiXG4gICAgICAgIGJlc3QgPSBnZW5lcmF0ZWRcbiAgICAgICAgYnJlYWtcblxuICAgICAgaWYgYmVzdCA9PSBudWxsXG4gICAgICAgIGJlc3QgPSBnZW5lcmF0ZWRcbiAgICAgIGVsc2UgaWYgYmVzdC5yZW1vdmVkIDwgZ2VuZXJhdGVkLnJlbW92ZWRcbiAgICAgICAgYmVzdCA9IGdlbmVyYXRlZFxuICAgICAgY29uc29sZS5sb2cgXCJjdXJyZW50IGJlc3QgI3tiZXN0LnJlbW92ZWR9IC8gI3thbW91bnRUb1JlbW92ZX1cIlxuXG4gICAgY29uc29sZS5sb2cgXCJnaXZpbmcgdXNlciBib2FyZDogI3tiZXN0LnJlbW92ZWR9IC8gI3thbW91bnRUb1JlbW92ZX1cIlxuICAgIHJldHVybiBbQGJvYXJkVG9HcmlkKGJlc3QuYm9hcmQpLCBAYm9hcmRUb0dyaWQoYmVzdC5zb2x1dGlvbildXG5cbiAgIyBSZXR1cm5zIHRydWUgaWYgYW55IHR3byBsb2NrZWQgY2VsbHMgaW4gdGhlIHNhbWUgcm93LCBjb2x1bW4sIG9yIGJveCBoYXZlIHRoZSBzYW1lIHZhbHVlXG4gIGhhc0NvbmZsaWN0czogKGJvYXJkKSAtPlxuICAgIGZvciB5IGluIFswLi4uOV1cbiAgICAgIGZvciB4IGluIFswLi4uOV1cbiAgICAgICAgY29udGludWUgaWYgbm90IGJvYXJkLmxvY2tlZFt4XVt5XVxuICAgICAgICB2ID0gYm9hcmQuZ3JpZFt4XVt5XVxuICAgICAgICBzeCA9IE1hdGguZmxvb3IoeCAvIDMpICogM1xuICAgICAgICBzeSA9IE1hdGguZmxvb3IoeSAvIDMpICogM1xuICAgICAgICBmb3IgaSBpbiBbMC4uLjldXG4gICAgICAgICAgcmV0dXJuIHRydWUgaWYgKGkgIT0geCkgYW5kIGJvYXJkLmxvY2tlZFtpXVt5XSBhbmQgKGJvYXJkLmdyaWRbaV1beV0gPT0gdilcbiAgICAgICAgICByZXR1cm4gdHJ1ZSBpZiAoaSAhPSB5KSBhbmQgYm9hcmQubG9ja2VkW3hdW2ldIGFuZCAoYm9hcmQuZ3JpZFt4XVtpXSA9PSB2KVxuICAgICAgICAgIGJ4ID0gc3ggKyAoaSAlIDMpXG4gICAgICAgICAgYnlfID0gc3kgKyAoaSAvLyAzKVxuICAgICAgICAgIHJldHVybiB0cnVlIGlmICgoYnggIT0geCkgb3IgKGJ5XyAhPSB5KSkgYW5kIGJvYXJkLmxvY2tlZFtieF1bYnlfXSBhbmQgKGJvYXJkLmdyaWRbYnhdW2J5X10gPT0gdilcbiAgICByZXR1cm4gZmFsc2VcblxuICB2YWxpZGF0ZUdyaWQ6IChncmlkKSAtPlxuICAgIGJvYXJkID0gQGdyaWRUb0JvYXJkKGdyaWQpXG4gICAgcmV0dXJuIGZhbHNlIGlmIEBoYXNDb25mbGljdHMoYm9hcmQpXG4gICAgcmV0dXJuIEBoYXNVbmlxdWVTb2x1dGlvbihib2FyZClcblxuICAjIFJldHVybnMgdGhlIHNvbHZlZCBncmlkLCBvciBudWxsIGlmIHRoZXJlIGlzIG5vIHNvbHV0aW9uXG4gIHNvbHZlR3JpZDogKGdyaWQpIC0+XG4gICAgYm9hcmQgPSBAZ3JpZFRvQm9hcmQoZ3JpZClcbiAgICByZXR1cm4gbnVsbCBpZiBAaGFzQ29uZmxpY3RzKGJvYXJkKVxuICAgIHNvbHZlZCA9IEBzb2x2ZShib2FyZClcbiAgICByZXR1cm4gbnVsbCBpZiBzb2x2ZWQgPT0gbnVsbFxuICAgIHJldHVybiAoY29sdW1uLnNsaWNlKCkgZm9yIGNvbHVtbiBpbiBzb2x2ZWQuZ3JpZClcblxuICBzb2x2ZVN0cmluZzogKGltcG9ydFN0cmluZykgLT5cbiAgICBpZiBpbXBvcnRTdHJpbmcuaW5kZXhPZihcIlNEXCIpICE9IDBcbiAgICAgIHJldHVybiBmYWxzZVxuICAgIGltcG9ydFN0cmluZyA9IGltcG9ydFN0cmluZy5zdWJzdHIoMilcbiAgICBpbXBvcnRTdHJpbmcgPSBpbXBvcnRTdHJpbmcucmVwbGFjZSgvW14wLTldL2csIFwiXCIpXG4gICAgaWYgaW1wb3J0U3RyaW5nLmxlbmd0aCAhPSA4MVxuICAgICAgcmV0dXJuIGZhbHNlXG5cbiAgICBib2FyZCA9IG5ldyBCb2FyZCgpXG5cbiAgICBpbmRleCA9IDBcbiAgICB6ZXJvQ2hhckNvZGUgPSBcIjBcIi5jaGFyQ29kZUF0KDApXG4gICAgZm9yIGogaW4gWzAuLi45XVxuICAgICAgZm9yIGkgaW4gWzAuLi45XVxuICAgICAgICB2ID0gaW1wb3J0U3RyaW5nLmNoYXJDb2RlQXQoaW5kZXgpIC0gemVyb0NoYXJDb2RlXG4gICAgICAgIGluZGV4ICs9IDFcbiAgICAgICAgaWYgdiA+IDBcbiAgICAgICAgICBib2FyZC5ncmlkW2pdW2ldID0gdlxuICAgICAgICAgIGJvYXJkLmxvY2soaiwgaSlcblxuICAgIGlmIEBoYXNDb25mbGljdHMoYm9hcmQpXG4gICAgICBjb25zb2xlLmxvZyBcIkVSUk9SOiBDb25mbGljdGluZyBnaXZlbnMuXCJcbiAgICAgIHJldHVybiBmYWxzZVxuXG4gICAgc29sdmVkID0gQHNvbHZlKGJvYXJkKVxuICAgIGlmIHNvbHZlZCA9PSBudWxsXG4gICAgICBjb25zb2xlLmxvZyBcIkVSUk9SOiBDYW4ndCBiZSBzb2x2ZWQuXCJcbiAgICAgIHJldHVybiBmYWxzZVxuXG4gICAgaWYgbm90IEBoYXNVbmlxdWVTb2x1dGlvbihib2FyZClcbiAgICAgIGNvbnNvbGUubG9nIFwiRVJST1I6IEJvYXJkIHNvbHZlIG5vdCB1bmlxdWUuXCJcbiAgICAgIHJldHVybiBmYWxzZVxuXG4gICAgYW5zd2VyU3RyaW5nID0gXCJcIlxuICAgIGZvciBqIGluIFswLi4uOV1cbiAgICAgIGZvciBpIGluIFswLi4uOV1cbiAgICAgICAgYW5zd2VyU3RyaW5nICs9IFwiI3tzb2x2ZWQuZ3JpZFtqXVtpXX0gXCJcbiAgICAgIGFuc3dlclN0cmluZyArPSBcIlxcblwiXG5cbiAgICByZXR1cm4gYW5zd2VyU3RyaW5nXG5cbm1vZHVsZS5leHBvcnRzID0gU3Vkb2t1R2VuZXJhdG9yXG4iLCJTdWRva3VHZW5lcmF0b3IgPSByZXF1aXJlICcuL1N1ZG9rdUdlbmVyYXRvcidcblxud2luZG93LnNvbHZlID0gKGFyZykgLT5cbiAgZ2VuID0gbmV3IFN1ZG9rdUdlbmVyYXRvclxuICByZXR1cm4gZ2VuLnNvbHZlU3RyaW5nKGFyZylcblxud2luZG93LnFzID0gKG5hbWUpIC0+XG4gIHVybCA9IHdpbmRvdy5sb2NhdGlvbi5ocmVmXG4gIG5hbWUgPSBuYW1lLnJlcGxhY2UoL1tcXFtcXF1dL2csICdcXFxcJCYnKVxuICByZWdleCA9IG5ldyBSZWdFeHAoJ1s/Jl0nICsgbmFtZSArICcoPShbXiYjXSopfCZ8I3wkKScpXG4gIHJlc3VsdHMgPSByZWdleC5leGVjKHVybClcbiAgaWYgbm90IHJlc3VsdHMgb3Igbm90IHJlc3VsdHNbMl1cbiAgICByZXR1cm4gbnVsbFxuICByZXR1cm4gZGVjb2RlVVJJQ29tcG9uZW50KHJlc3VsdHNbMl0ucmVwbGFjZSgvXFwrL2csICcgJykpXG5cbiJdfQ==
