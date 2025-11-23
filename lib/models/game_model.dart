import 'dart:math';

class GameModel {
  final int boardSize;
  late List<List<int>> board;
  int score = 0;
  int currentNumber = 0;
  int nextNumber = 0;
  bool isGameOver = false;
  int comboCount = 0;
  int? lastPlacedRow;
  int? lastPlacedCol;
  final Random _random = Random();

  GameModel({this.boardSize = 4}) {
    reset();
  }

  void reset() {
    board = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    score = 0;
    isGameOver = false;
    comboCount = 0;
    generateNextNumber();
    shiftNextNumber();
  }

  int _generateRandomNumber() {
    final rand = _random.nextDouble();
    if (rand < 0.70) {
      return _random.nextInt(3) + 1;
    } else if (rand < 0.95) {
      return _random.nextInt(2) + 4;
    } else {
      return _random.nextInt(2) + 6;
    }
  }

  void generateNextNumber() {
    nextNumber = _generateRandomNumber();
  }

  void shiftNextNumber() {
    currentNumber = nextNumber;
    generateNextNumber();
  }

  bool placeTile(int row, int col) {
    if (isGameOver) return false;
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return false;
    if (board[row][col] != 0) return false;

    board[row][col] = currentNumber;
    lastPlacedRow = row;
    lastPlacedCol = col;
    comboCount = 0;

    bool merged = true;
    while (merged) {
      merged = processMerge();
      if (merged) comboCount++;
    }

    shiftNextNumber();
    checkGameOver();

    return true;
  }

  bool processMerge() {
    if (lastPlacedRow != null && lastPlacedCol != null) {
      final row = lastPlacedRow!;
      final col = lastPlacedCol!;
      if (board[row][col] != 0) {
        final number = board[row][col];
        final group = findConnectedGroup(row, col, number);

        if (group.length >= 3) {
          mergeGroup(group, row, col, number);
          return true;
        }
      }
    }

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (board[row][col] == 0) continue;
        if (row == lastPlacedRow && col == lastPlacedCol) continue;

        final number = board[row][col];
        final group = findConnectedGroup(row, col, number);

        if (group.length >= 3) {
          mergeGroup(group, row, col, number);
          lastPlacedRow = row;
          lastPlacedCol = col;
          return true;
        }
      }
    }
    return false;
  }

  List<Position> findConnectedGroup(int startRow, int startCol, int number) {
    final visited = List.generate(boardSize, (_) => List.filled(boardSize, false));
    final group = <Position>[];

    void dfs(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return;
      if (visited[row][col]) return;
      if (board[row][col] != number) return;

      visited[row][col] = true;
      group.add(Position(row, col));

      dfs(row - 1, col);
      dfs(row + 1, col);
      dfs(row, col - 1);
      dfs(row, col + 1);
    }

    dfs(startRow, startCol);
    return group;
  }

  void mergeGroup(List<Position> group, int tapRow, int tapCol, int number) {
    for (final pos in group) {
      if (pos.row == tapRow && pos.col == tapCol) {
        board[pos.row][pos.col] = number + 1;
        score += number + 1;
      } else {
        board[pos.row][pos.col] = 0;
      }
    }
  }

  void checkGameOver() {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (board[row][col] == 0) {
          isGameOver = false;
          return;
        }
      }
    }
    isGameOver = true;
  }
}

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && runtimeType == other.runtimeType && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}
