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
      var board, i, indexesToRemove, j, l, m, nextBoard, removeIndex, removed, rx, ry;
      board = this.solve(new Board());
// hack
      for (j = l = 0; l < 9; j = ++l) {
        for (i = m = 0; m < 9; i = ++m) {
          board.lock(i, j);
        }
      }
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
      return {
        // console.log "failed to remove #{rx},#{ry}, creates non-unique solution"
        // console.log "successfully removed #{rx},#{ry}"
        board: board,
        removed: removed
      };
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
      return this.boardToGrid(best.board);
    }

    validateGrid(grid) {
      return this.hasUniqueSolution(this.gridToBoard(grid));
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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJnYW1lL3NyYy9TdWRva3VHZW5lcmF0b3IuY29mZmVlIiwiZ2FtZS9zcmMvd2Vic29sdmVyLmNvZmZlZSJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBLElBQUEsS0FBQSxFQUFBLGVBQUEsRUFBQTs7QUFBQSxPQUFBLEdBQVUsUUFBQSxDQUFDLENBQUQsQ0FBQTtBQUNWLE1BQUEsQ0FBQSxFQUFBLENBQUEsRUFBQTtFQUFJLENBQUEsR0FBSSxDQUFDLENBQUM7QUFDTixTQUFNLEVBQUUsQ0FBRixHQUFNLENBQVo7SUFDSSxDQUFBLEdBQUksQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLE1BQUwsQ0FBQSxDQUFBLEdBQWdCLENBQUMsQ0FBQSxHQUFJLENBQUwsQ0FBakI7SUFDTixDQUFBLEdBQUksQ0FBQyxDQUFDLENBQUQ7SUFDTCxDQUFDLENBQUMsQ0FBRCxDQUFELEdBQU8sQ0FBQyxDQUFDLENBQUQ7SUFDUixDQUFDLENBQUMsQ0FBRCxDQUFELEdBQU87RUFKWDtBQUtBLFNBQU87QUFQRDs7QUFTSixRQUFOLE1BQUEsTUFBQTtFQUNFLFdBQWEsQ0FBQyxhQUFhLElBQWQsQ0FBQTtBQUNmLFFBQUEsQ0FBQSxFQUFBLENBQUEsRUFBQSxDQUFBLEVBQUEsQ0FBQSxFQUFBO0lBQUksSUFBQyxDQUFBLFdBQUQsR0FBZTtJQUNmLElBQUMsQ0FBQSxJQUFELEdBQVEsSUFBSSxLQUFKLENBQVUsQ0FBVixDQUFZLENBQUMsSUFBYixDQUFrQixJQUFsQjtJQUNSLElBQUMsQ0FBQSxNQUFELEdBQVUsSUFBSSxLQUFKLENBQVUsQ0FBVixDQUFZLENBQUMsSUFBYixDQUFrQixJQUFsQjtJQUNWLEtBQVMseUJBQVQ7TUFDRSxJQUFDLENBQUEsSUFBSSxDQUFDLENBQUQsQ0FBTCxHQUFXLElBQUksS0FBSixDQUFVLENBQVYsQ0FBWSxDQUFDLElBQWIsQ0FBa0IsQ0FBbEI7TUFDWCxJQUFD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T0FBQSxHQUFVLEtBQUssQ0FBQyxJQUFOLENBQVcsR0FBWDtFQUNWLElBQUcsQ0FBSSxPQUFKLElBQWUsQ0FBSSxPQUFPLENBQUMsQ0FBRCxDQUE3QjtBQUNFLFdBQU8sS0FEVDs7QUFFQSxTQUFPLGtCQUFBLENBQW1CLE9BQU8sQ0FBQyxDQUFELENBQUcsQ0FBQyxPQUFYLENBQW1CLEtBQW5CLEVBQTBCLEdBQTFCLENBQW5CO0FBUEciLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIihmdW5jdGlvbigpe2Z1bmN0aW9uIHIoZSxuLHQpe2Z1bmN0aW9uIG8oaSxmKXtpZighbltpXSl7aWYoIWVbaV0pe3ZhciBjPVwiZnVuY3Rpb25cIj09dHlwZW9mIHJlcXVpcmUmJnJlcXVpcmU7aWYoIWYmJmMpcmV0dXJuIGMoaSwhMCk7aWYodSlyZXR1cm4gdShpLCEwKTt2YXIgYT1uZXcgRXJyb3IoXCJDYW5ub3QgZmluZCBtb2R1bGUgJ1wiK2krXCInXCIpO3Rocm93IGEuY29kZT1cIk1PRFVMRV9OT1RfRk9VTkRcIixhfXZhciBwPW5baV09e2V4cG9ydHM6e319O2VbaV1bMF0uY2FsbChwLmV4cG9ydHMsZnVuY3Rpb24ocil7dmFyIG49ZVtpXVsxXVtyXTtyZXR1cm4gbyhufHxyKX0scCxwLmV4cG9ydHMscixlLG4sdCl9cmV0dXJuIG5baV0uZXhwb3J0c31mb3IodmFyIHU9XCJmdW5jdGlvblwiPT10eXBlb2YgcmVxdWlyZSYmcmVxdWlyZSxpPTA7aTx0Lmxlbmd0aDtpKyspbyh0W2ldKTtyZXR1cm4gb31yZXR1cm4gcn0pKCkiLCJzaHVmZmxlID0gKGEpIC0+XG4gICAgaSA9IGEubGVuZ3RoXG4gICAgd2hpbGUgLS1pID4gMFxuICAgICAgICBqID0gfn4oTWF0aC5yYW5kb20oKSAqIChpICsgMSkpXG4gICAgICAgIHQgPSBhW2pdXG4gICAgICAgIGFbal0gPSBhW2ldXG4gICAgICAgIGFbaV0gPSB0XG4gICAgcmV0dXJuIGFcblxuY2xhc3MgQm9hcmRcbiAgY29uc3RydWN0b3I6IChvdGhlckJvYXJkID0gbnVsbCkgLT5cbiAgICBAbG9ja2VkQ291bnQgPSAwO1xuICAgIEBncmlkID0gbmV3IEFycmF5KDkpLmZpbGwobnVsbClcbiAgICBAbG9ja2VkID0gbmV3IEFycmF5KDkpLmZpbGwobnVsbClcbiAgICBmb3IgaSBpbiBbMC4uLjldXG4gICAgICBAZ3JpZFtpXSA9IG5ldyBBcnJheSg5KS5maWxsKDApXG4gICAgICBAbG9ja2VkW2ldID0gbmV3IEFycmF5KDkpLmZpbGwoZmFsc2UpXG4gICAgaWYgb3RoZXJCb2FyZCAhPSBudWxsXG4gICAgICBmb3IgaiBpbiBbMC4uLjldXG4gICAgICAgIGZvciBpIGluIFswLi4uOV1cbiAgICAgICAgICBAZ3JpZFtpXVtqXSA9IG90aGVyQm9hcmQuZ3JpZFtpXVtqXVxuICAgICAgICAgIEBsb2NrKGksIGosIG90aGVyQm9hcmQubG9ja2VkW2ldW2pdKVxuICAgIHJldHVyblxuXG4gIG1hdGNoZXM6IChvdGhlckJvYXJkKSAtPlxuICAgIGZvciBqIGluIFswLi4uOV1cbiAgICAgIGZvciBpIGluIFswLi4uOV1cbiAgICAgICAgaWYgQGdyaWRbaV1bal0gIT0gb3RoZXJCb2FyZC5ncmlkW2ldW2pdXG4gICAgICAgICAgcmV0dXJuIGZhbHNlXG4gICAgcmV0dXJuIHRydWVcblxuICBsb2NrOiAoeCwgeSwgdiA9IHRydWUpIC0+XG4gICAgaWYgdlxuICAgICAgQGxvY2tlZENvdW50ICs9IDEgaWYgbm90IEBsb2NrZWRbeF1beV1cbiAgICBlbHNlXG4gICAgICBAbG9ja2VkQ291bnQgLT0gMSBpZiBAbG9ja2VkW3hdW3ldXG4gICAgQGxvY2tlZFt4XVt5XSA9IHY7XG5cblxuY2xhc3MgU3Vkb2t1R2VuZXJhdG9yXG4gIEBkaWZmaWN1bHR5OlxuICAgIGVhc3k6IDFcbiAgICBtZWRpdW06IDJcbiAgICBoYXJkOiAzXG4gICAgZXh0cmVtZTogNFxuXG4gIGNvbnN0cnVjdG9yOiAtPlxuXG4gIGJvYXJkVG9HcmlkOiAoYm9hcmQpIC0+XG4gICAgbmV3Qm9hcmQgPSBuZXcgQXJyYXkoOSkuZmlsbChudWxsKVxuICAgIGZvciBpIGluIFswLi4uOV1cbiAgICAgIG5ld0JvYXJkW2ldID0gbmV3IEFycmF5KDkpLmZpbGwoMClcbiAgICBmb3IgaiBpbiBbMC4uLjldXG4gICAgICBmb3IgaSBpbiBbMC4uLjldXG4gICAgICAgIGlmIGJvYXJkLmxvY2tlZFtpXVtqXVxuICAgICAgICAgIG5ld0JvYXJkW2ldW2pdID0gYm9hcmQuZ3JpZFtpXVtqXVxuICAgIHJldHVybiBuZXdCb2FyZFxuXG4gIGdyaWRUb0JvYXJkOiAoZ3JpZCkgLT5cbiAgICBib2FyZCA9IG5ldyBCb2FyZFxuICAgIGZvciB5IGluIFswLi4uOV1cbiAgICAgIGZvciB4IGluIFswLi4uOV1cbiAgICAgICAgaWYgZ3JpZFt4XVt5XSA+IDBcbiAgICAgICAgICBib2FyZC5ncmlkW3hdW3ldID0gZ3JpZFt4XVt5XVxuICAgICAgICAgIGJvYXJkLmxvY2soeCwgeSlcbiAgICByZXR1cm4gYm9hcmRcblxuICBjZWxsVmFsaWQ6IChib2FyZCwgeCwgeSwgdikgLT5cbiAgICBpZiBib2FyZC5sb2NrZWRbeF1beV1cbiAgICAgIHJldHVybiBib2FyZC5ncmlkW3hdW3ldID09IHZcblxuICAgIGZvciBpIGluIFswLi4uOV1cbiAgICAgIGlmICh4ICE9IGkpIGFuZCAoYm9hcmQuZ3JpZFtpXVt5XSA9PSB2KVxuICAgICAgICAgIHJldHVybiBmYWxzZVxuICAgICAgaWYgKHkgIT0gaSkgYW5kIChib2FyZC5ncmlkW3hdW2ldID09IHYpXG4gICAgICAgICAgcmV0dXJuIGZhbHNlXG5cbiAgICBzeCA9IE1hdGguZmxvb3IoeCAvIDMpICogM1xuICAgIHN5ID0gTWF0aC5mbG9vcih5IC8gMykgKiAzXG4gICAgZm9yIGogaW4gWzAuLi4zXVxuICAgICAgZm9yIGkgaW4gWzAuLi4zXVxuICAgICAgICBpZiAoeCAhPSAoc3ggKyBpKSkgJiYgKHkgIT0gKHN5ICsgaikpXG4gICAgICAgICAgaWYgYm9hcmQuZ3JpZFtzeCArIGldW3N5ICsgal0gPT0gdlxuICAgICAgICAgICAgcmV0dXJuIGZhbHNlXG4gICAgcmV0dXJuIHRydWVcblxuICBwZW5jaWxNYXJrczogKGJvYXJkLCB4LCB5KSAtPlxuICAgIGlmIGJvYXJkLmxvY2tlZFt4XVt5XVxuICAgICAgcmV0dXJuIFsgYm9hcmQuZ3JpZFt4XVt5XSBdXG4gICAgbWFya3MgPSBbXVxuICAgIGZvciB2IGluIFsxLi45XVxuICAgICAgaWYgQGNlbGxWYWxpZChib2FyZCwgeCwgeSwgdilcbiAgICAgICAgbWFya3MucHVzaCB2XG4gICAgaWYgbWFya3MubGVuZ3RoID4gMVxuICAgICAgc2h1ZmZsZShtYXJrcylcbiAgICByZXR1cm4gbWFya3NcblxuICBuZXh0QXR0ZW1wdDogKGJvYXJkLCBhdHRlbXB0cykgLT5cbiAgICByZW1haW5pbmdJbmRleGVzID0gWzAuLi44MV1cblxuICAgICMgc2tpcCBsb2NrZWQgY2VsbHNcbiAgICBmb3IgaW5kZXggaW4gWzAuLi44MV1cbiAgICAgIHggPSBpbmRleCAlIDlcbiAgICAgIHkgPSBpbmRleCAvLyA5XG4gICAgICBpZiBib2FyZC5sb2NrZWRbeF1beV1cbiAgICAgICAgayA9IHJlbWFpbmluZ0luZGV4ZXMuaW5kZXhPZihpbmRleClcbiAgICAgICAgcmVtYWluaW5nSW5kZXhlcy5zcGxpY2UoaywgMSkgaWYgayA+PSAwXG5cbiAgICAjIHNraXAgY2VsbHMgdGhhdCBhcmUgYWxyZWFkeSBiZWluZyB0cmllZFxuICAgIGZvciBhIGluIGF0dGVtcHRzXG4gICAgICBrID0gcmVtYWluaW5nSW5kZXhlcy5pbmRleE9mKGEuaW5kZXgpXG4gICAgICByZW1haW5pbmdJbmRleGVzLnNwbGljZShrLCAxKSBpZiBrID49IDBcblxuICAgIHJldHVybiBudWxsIGlmIHJlbWFpbmluZ0luZGV4ZXMubGVuZ3RoID09IDAgIyBhYm9ydCBpZiB0aGVyZSBhcmUgbm8gY2VsbHMgKHNob3VsZCBuZXZlciBoYXBwZW4pXG5cbiAgICBmZXdlc3RJbmRleCA9IC0xXG4gICAgZmV3ZXN0TWFya3MgPSBbMC4uOV1cbiAgICBmb3IgaW5kZXggaW4gcmVtYWluaW5nSW5kZXhlc1xuICAgICAgeCA9IGluZGV4ICUgOVxuICAgICAgeSA9IGluZGV4IC8vIDlcbiAgICAgIG1hcmtzID0gQHBlbmNpbE1hcmtzKGJvYXJkLCB4LCB5KVxuXG4gICAgICAjIGFib3J0IGlmIHRoZXJlIGlzIGEgY2VsbCB3aXRoIG5vIHBvc3NpYmlsaXRpZXNcbiAgICAgIHJldHVybiBudWxsIGlmIG1hcmtzLmxlbmd0aCA9PSAwXG5cbiAgICAgICMgZG9uZSBpZiB0aGVyZSBpcyBhIGNlbGwgd2l0aCBvbmx5IG9uZSBwb3NzaWJpbGl0eSAoKVxuICAgICAgcmV0dXJuIHsgaW5kZXg6IGluZGV4LCByZW1haW5pbmc6IG1hcmtzIH0gaWYgbWFya3MubGVuZ3RoID09IDFcblxuICAgICAgIyByZW1lbWJlciB0aGlzIGNlbGwgaWYgaXQgaGFzIHRoZSBmZXdlc3QgbWFya3Mgc28gZmFyXG4gICAgICBpZiBtYXJrcy5sZW5ndGggPCBmZXdlc3RNYXJrcy5sZW5ndGhcbiAgICAgICAgZmV3ZXN0SW5kZXggPSBpbmRleFxuICAgICAgICBmZXdlc3RNYXJrcyA9IG1hcmtzXG4gICAgcmV0dXJuIHsgaW5kZXg6IGZld2VzdEluZGV4LCByZW1haW5pbmc6IGZld2VzdE1hcmtzIH1cblxuICBzb2x2ZTogKGJvYXJkKSAtPlxuICAgIHNvbHZlZCA9IG5ldyBCb2FyZChib2FyZClcbiAgICBhdHRlbXB0cyA9IFtdXG4gICAgcmV0dXJuIEBzb2x2ZUludGVybmFsKHNvbHZlZCwgYXR0ZW1wdHMpXG5cbiAgaGFzVW5pcXVlU29sdXRpb246IChib2FyZCkgLT5cbiAgICBzb2x2ZWQgPSBuZXcgQm9hcmQoYm9hcmQpXG4gICAgYXR0ZW1wdHMgPSBbXVxuXG4gICAgIyBpZiB0aGVyZSBpcyBubyBzb2x1dGlvbiwgcmV0dXJuIGZhbHNlXG4gICAgcmV0dXJuIGZhbHNlIGlmIEBzb2x2ZUludGVybmFsKHNvbHZlZCwgYXR0ZW1wdHMpID09IG51bGxcblxuICAgIHVubG9ja2VkQ291bnQgPSA4MSAtIHNvbHZlZC5sb2NrZWRDb3VudFxuXG4gICAgIyBpZiB0aGVyZSBhcmUgbm8gdW5sb2NrZWQgY2VsbHMsIHRoZW4gdGhpcyBzb2x1dGlvbiBtdXN0IGJlIHVuaXF1ZVxuICAgIHJldHVybiB0cnVlIGlmIHVubG9ja2VkQ291bnQgPT0gMFxuXG4gICAgIyBjaGVjayBmb3IgYSBzZWNvbmQgc29sdXRpb25cbiAgICByZXR1cm4gQHNvbHZlSW50ZXJuYWwoc29sdmVkLCBhdHRlbXB0cywgdW5sb2NrZWRDb3VudC0xKSA9PSBudWxsXG5cbiAgc29sdmVJbnRlcm5hbDogKHNvbHZlZCwgYXR0ZW1wdHMsIHdhbGtJbmRleCA9IDApIC0+XG4gICAgdW5sb2NrZWRDb3VudCA9IDgxIC0gc29sdmVkLmxvY2tlZENvdW50XG4gICAgd2hpbGUgd2Fsa0luZGV4IDwgdW5sb2NrZWRDb3VudFxuICAgICAgaWYgd2Fsa0luZGV4ID49IGF0dGVtcHRzLmxlbmd0aFxuICAgICAgICBhdHRlbXB0ID0gQG5leHRBdHRlbXB0KHNvbHZlZCwgYXR0ZW1wdHMpXG4gICAgICAgIGF0dGVtcHRzLnB1c2goYXR0ZW1wdCkgaWYgYXR0ZW1wdCAhPSBudWxsXG4gICAgICBlbHNlXG4gICAgICAgIGF0dGVtcHQgPSBhdHRlbXB0c1t3YWxrSW5kZXhdXG5cbiAgICAgIGlmIGF0dGVtcHQgIT0gbnVsbFxuICAgICAgICB4ID0gYXR0ZW1wdC5pbmRleCAlIDlcbiAgICAgICAgeSA9IGF0dGVtcHQuaW5kZXggLy8gOVxuICAgICAgICBpZiBhdHRlbXB0LnJlbWFpbmluZy5sZW5ndGggPiAwXG4gICAgICAgICAgc29sdmVkLmdyaWRbeF1beV0gPSBhdHRlbXB0LnJlbWFpbmluZy5wb3AoKVxuICAgICAgICAgIHdhbGtJbmRleCArPSAxXG4gICAgICAgIGVsc2VcbiAgICAgICAgICBhdHRlbXB0cy5wb3AoKVxuICAgICAgICAgIHNvbHZlZC5ncmlkW3hdW3ldID0gMFxuICAgICAgICAgIHdhbGtJbmRleCAtPSAxXG4gICAgICBlbHNlXG4gICAgICAgIHdhbGtJbmRleCAtPSAxXG5cbiAgICAgIGlmIHdhbGtJbmRleCA8IDBcbiAgICAgICAgcmV0dXJuIG51bGxcblxuICAgIHJldHVybiBzb2x2ZWRcblxuICBnZW5lcmF0ZUludGVybmFsOiAoYW1vdW50VG9SZW1vdmUpIC0+XG4gICAgYm9hcmQgPSBAc29sdmUobmV3IEJvYXJkKCkpXG4gICAgIyBoYWNrXG4gICAgZm9yIGogaW4gWzAuLi45XVxuICAgICAgZm9yIGkgaW4gWzAuLi45XVxuICAgICAgICBib2FyZC5sb2NrKGksIGopXG5cbiAgICBpbmRleGVzVG9SZW1vdmUgPSBzaHVmZmxlKFswLi4uODFdKVxuICAgIHJlbW92ZWQgPSAwXG4gICAgd2hpbGUgcmVtb3ZlZCA8IGFtb3VudFRvUmVtb3ZlXG4gICAgICBpZiBpbmRleGVzVG9SZW1vdmUubGVuZ3RoID09IDBcbiAgICAgICAgYnJlYWtcblxuICAgICAgcmVtb3ZlSW5kZXggPSBpbmRleGVzVG9SZW1vdmUucG9wKClcbiAgICAgIHJ4ID0gcmVtb3ZlSW5kZXggJSA5XG4gICAgICByeSA9IE1hdGguZmxvb3IocmVtb3ZlSW5kZXggLyA5KVxuXG4gICAgICBuZXh0Qm9hcmQgPSBuZXcgQm9hcmQoYm9hcmQpXG4gICAgICBuZXh0Qm9hcmQuZ3JpZFtyeF1bcnldID0gMFxuICAgICAgbmV4dEJvYXJkLmxvY2socngsIHJ5LCBmYWxzZSlcblxuICAgICAgaWYgQGhhc1VuaXF1ZVNvbHV0aW9uKG5leHRCb2FyZClcbiAgICAgICAgYm9hcmQgPSBuZXh0Qm9hcmRcbiAgICAgICAgcmVtb3ZlZCArPSAxXG4gICAgICAgICMgY29uc29sZS5sb2cgXCJzdWNjZXNzZnVsbHkgcmVtb3ZlZCAje3J4fSwje3J5fVwiXG4gICAgICBlbHNlXG4gICAgICAgICMgY29uc29sZS5sb2cgXCJmYWlsZWQgdG8gcmVtb3ZlICN7cnh9LCN7cnl9LCBjcmVhdGVzIG5vbi11bmlxdWUgc29sdXRpb25cIlxuXG4gICAgcmV0dXJuIHtcbiAgICAgIGJvYXJkOiBib2FyZFxuICAgICAgcmVtb3ZlZDogcmVtb3ZlZFxuICAgIH1cblxuICBnZW5lcmF0ZTogKGRpZmZpY3VsdHkpIC0+XG4gICAgYW1vdW50VG9SZW1vdmUgPSBzd2l0Y2ggZGlmZmljdWx0eVxuICAgICAgd2hlbiBTdWRva3VHZW5lcmF0b3IuZGlmZmljdWx0eS5leHRyZW1lIHRoZW4gNjBcbiAgICAgIHdoZW4gU3Vkb2t1R2VuZXJhdG9yLmRpZmZpY3VsdHkuaGFyZCAgICB0aGVuIDUyXG4gICAgICB3aGVuIFN1ZG9rdUdlbmVyYXRvci5kaWZmaWN1bHR5Lm1lZGl1bSAgdGhlbiA0NlxuICAgICAgZWxzZSA0MCAjIGVhc3kgLyB1bmtub3duXG5cbiAgICBiZXN0ID0gbnVsbFxuICAgIGZvciBhdHRlbXB0IGluIFswLi4uMl1cbiAgICAgIGdlbmVyYXRlZCA9IEBnZW5lcmF0ZUludGVybmFsKGFtb3VudFRvUmVtb3ZlKVxuICAgICAgaWYgZ2VuZXJhdGVkLnJlbW92ZWQgPT0gYW1vdW50VG9SZW1vdmVcbiAgICAgICAgY29uc29sZS5sb2cgXCJSZW1vdmVkIGV4YWN0IGFtb3VudCAje2Ftb3VudFRvUmVtb3ZlfSwgc3RvcHBpbmdcIlxuICAgICAgICBiZXN0ID0gZ2VuZXJhdGVkXG4gICAgICAgIGJyZWFrXG5cbiAgICAgIGlmIGJlc3QgPT0gbnVsbFxuICAgICAgICBiZXN0ID0gZ2VuZXJhdGVkXG4gICAgICBlbHNlIGlmIGJlc3QucmVtb3ZlZCA8IGdlbmVyYXRlZC5yZW1vdmVkXG4gICAgICAgIGJlc3QgPSBnZW5lcmF0ZWRcbiAgICAgIGNvbnNvbGUubG9nIFwiY3VycmVudCBiZXN0ICN7YmVzdC5yZW1vdmVkfSAvICN7YW1vdW50VG9SZW1vdmV9XCJcblxuICAgIGNvbnNvbGUubG9nIFwiZ2l2aW5nIHVzZXIgYm9hcmQ6ICN7YmVzdC5yZW1vdmVkfSAvICN7YW1vdW50VG9SZW1vdmV9XCJcbiAgICByZXR1cm4gQGJvYXJkVG9HcmlkKGJlc3QuYm9hcmQpXG5cbiAgdmFsaWRhdGVHcmlkOiAoZ3JpZCkgLT5cbiAgICByZXR1cm4gQGhhc1VuaXF1ZVNvbHV0aW9uKEBncmlkVG9Cb2FyZChncmlkKSlcblxuICBzb2x2ZVN0cmluZzogKGltcG9ydFN0cmluZykgLT5cbiAgICBpZiBpbXBvcnRTdHJpbmcuaW5kZXhPZihcIlNEXCIpICE9IDBcbiAgICAgIHJldHVybiBmYWxzZVxuICAgIGltcG9ydFN0cmluZyA9IGltcG9ydFN0cmluZy5zdWJzdHIoMilcbiAgICBpbXBvcnRTdHJpbmcgPSBpbXBvcnRTdHJpbmcucmVwbGFjZSgvW14wLTldL2csIFwiXCIpXG4gICAgaWYgaW1wb3J0U3RyaW5nLmxlbmd0aCAhPSA4MVxuICAgICAgcmV0dXJuIGZhbHNlXG5cbiAgICBib2FyZCA9IG5ldyBCb2FyZCgpXG5cbiAgICBpbmRleCA9IDBcbiAgICB6ZXJvQ2hhckNvZGUgPSBcIjBcIi5jaGFyQ29kZUF0KDApXG4gICAgZm9yIGogaW4gWzAuLi45XVxuICAgICAgZm9yIGkgaW4gWzAuLi45XVxuICAgICAgICB2ID0gaW1wb3J0U3RyaW5nLmNoYXJDb2RlQXQoaW5kZXgpIC0gemVyb0NoYXJDb2RlXG4gICAgICAgIGluZGV4ICs9IDFcbiAgICAgICAgaWYgdiA+IDBcbiAgICAgICAgICBib2FyZC5ncmlkW2pdW2ldID0gdlxuICAgICAgICAgIGJvYXJkLmxvY2soaiwgaSlcblxuICAgIHNvbHZlZCA9IEBzb2x2ZShib2FyZClcbiAgICBpZiBzb2x2ZWQgPT0gbnVsbFxuICAgICAgY29uc29sZS5sb2cgXCJFUlJPUjogQ2FuJ3QgYmUgc29sdmVkLlwiXG4gICAgICByZXR1cm4gZmFsc2VcblxuICAgIGlmIG5vdCBAaGFzVW5pcXVlU29sdXRpb24oYm9hcmQpXG4gICAgICBjb25zb2xlLmxvZyBcIkVSUk9SOiBCb2FyZCBzb2x2ZSBub3QgdW5pcXVlLlwiXG4gICAgICByZXR1cm4gZmFsc2VcblxuICAgIGFuc3dlclN0cmluZyA9IFwiXCJcbiAgICBmb3IgaiBpbiBbMC4uLjldXG4gICAgICBmb3IgaSBpbiBbMC4uLjldXG4gICAgICAgIGFuc3dlclN0cmluZyArPSBcIiN7c29sdmVkLmdyaWRbal1baV19IFwiXG4gICAgICBhbnN3ZXJTdHJpbmcgKz0gXCJcXG5cIlxuXG4gICAgcmV0dXJuIGFuc3dlclN0cmluZ1xuXG5tb2R1bGUuZXhwb3J0cyA9IFN1ZG9rdUdlbmVyYXRvclxuIiwiU3Vkb2t1R2VuZXJhdG9yID0gcmVxdWlyZSAnLi9TdWRva3VHZW5lcmF0b3InXG5cbndpbmRvdy5zb2x2ZSA9IChhcmcpIC0+XG4gIGdlbiA9IG5ldyBTdWRva3VHZW5lcmF0b3JcbiAgcmV0dXJuIGdlbi5zb2x2ZVN0cmluZyhhcmcpXG5cbndpbmRvdy5xcyA9IChuYW1lKSAtPlxuICB1cmwgPSB3aW5kb3cubG9jYXRpb24uaHJlZlxuICBuYW1lID0gbmFtZS5yZXBsYWNlKC9bXFxbXFxdXS9nLCAnXFxcXCQmJylcbiAgcmVnZXggPSBuZXcgUmVnRXhwKCdbPyZdJyArIG5hbWUgKyAnKD0oW14mI10qKXwmfCN8JCknKVxuICByZXN1bHRzID0gcmVnZXguZXhlYyh1cmwpO1xuICBpZiBub3QgcmVzdWx0cyBvciBub3QgcmVzdWx0c1syXVxuICAgIHJldHVybiBudWxsXG4gIHJldHVybiBkZWNvZGVVUklDb21wb25lbnQocmVzdWx0c1syXS5yZXBsYWNlKC9cXCsvZywgJyAnKSlcblxuIl19
