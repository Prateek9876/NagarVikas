import 'dart:math';

class GameModel {
  static const int gridSize = 4;

  late List<List<int>> board;
  int score = 0;
  final Random random = Random();

  GameModel() {
    resetGame();
  }

  void resetGame() {
    board = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    score = 0;
    _spawnTile();
    _spawnTile();
  }

  List<List<int>> getBoard() {
    return List.generate(
        gridSize, (i) => List.from(board[i])); // deep copy for safe use
  }

  void _spawnTile() {
    final empty = <Point<int>>[];
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board[y][x] == 0) empty.add(Point(x, y));
      }
    }
    if (empty.isNotEmpty) {
      final pos = empty[random.nextInt(empty.length)];
      board[pos.y][pos.x] = random.nextDouble() < 0.9 ? 2 : 4;
    }
  }

  bool move(String direction) {
    final before = getBoard();
    switch (direction) {
      case 'up':
        _moveUp();
        break;
      case 'down':
        _moveDown();
        break;
      case 'left':
        _moveLeft();
        break;
      case 'right':
        _moveRight();
        break;
    }
    final after = getBoard();
    if (!_boardsEqual(before, after)) {
      _spawnTile();
      return true;
    }
    return false;
  }

  void _moveLeft() {
    for (int y = 0; y < gridSize; y++) {
      List<int> row = board[y].where((e) => e != 0).toList();
      for (int i = 0; i < row.length - 1; i++) {
        if (row[i] == row[i + 1]) {
          row[i] *= 2;
          score += row[i];
          row[i + 1] = 0;
        }
      }
      row = row.where((e) => e != 0).toList();
      while (row.length < gridSize) {
        row.add(0);
      }
      board[y] = row;
    }
  }

  void _moveRight() {
    for (int y = 0; y < gridSize; y++) {
      List<int> row = board[y].reversed.where((e) => e != 0).toList();
      for (int i = 0; i < row.length - 1; i++) {
        if (row[i] == row[i + 1]) {
          row[i] *= 2;
          score += row[i];
          row[i + 1] = 0;
        }
      }
      row = row.where((e) => e != 0).toList();
      while (row.length < gridSize) {
        row.add(0);
      }
      board[y] = row.reversed.toList();
    }
  }

  void _moveUp() {
    for (int x = 0; x < gridSize; x++) {
      List<int> col = [];
      for (int y = 0; y < gridSize; y++) {
        if (board[y][x] != 0) col.add(board[y][x]);
      }
      for (int i = 0; i < col.length - 1; i++) {
        if (col[i] == col[i + 1]) {
          col[i] *= 2;
          score += col[i];
          col[i + 1] = 0;
        }
      }
      col = col.where((e) => e != 0).toList();
      while (col.length < gridSize) {
        col.add(0);
      }
      for (int y = 0; y < gridSize; y++) {
        board[y][x] = col[y];
      }
    }
  }

  void _moveDown() {
    for (int x = 0; x < gridSize; x++) {
      List<int> col = [];
      for (int y = gridSize - 1; y >= 0; y--) {
        if (board[y][x] != 0) col.add(board[y][x]);
      }
      for (int i = 0; i < col.length - 1; i++) {
        if (col[i] == col[i + 1]) {
          col[i] *= 2;
          score += col[i];
          col[i + 1] = 0;
        }
      }
      col = col.where((e) => e != 0).toList();
      while (col.length < gridSize) {
        col.add(0);
      }
      for (int y = gridSize - 1, k = 0; y >= 0; y--, k++) {
        board[y][x] = col[k];
      }
    }
  }

  bool _boardsEqual(List<List<int>> a, List<List<int>> b) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (a[y][x] != b[y][x]) return false;
      }
    }
    return true;
  }

  bool isGameOver() {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board[y][x] == 0) return false;
        if (x + 1 < gridSize && board[y][x] == board[y][x + 1]) return false;
        if (y + 1 < gridSize && board[y][x] == board[y + 1][x]) return false;
      }
    }
    return true;
  }
}
