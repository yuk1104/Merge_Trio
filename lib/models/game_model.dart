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
  int swapsRemaining = 3; // 入れ替え可能な残り回数
  List<Position> pendingMergePositions = []; // マージ予定のタイルの位置
  int pendingMergeNumber = 0; // マージ予定のタイルの数字

  GameModel({this.boardSize = 4}) {
    reset();
  }

  void reset() {
    board = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    score = 0;
    isGameOver = false;
    comboCount = 0;
    swapsRemaining = 3; // リセット時に入れ替え回数も初期化
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

  // 現在のタイルと次のタイルを入れ替え
  bool swapNumbers() {
    if (swapsRemaining <= 0) return false;

    final temp = currentNumber;
    currentNumber = nextNumber;
    nextNumber = temp;
    swapsRemaining--;

    return true;
  }

  // タイル配置後にマージが発生するかチェック（演出用）
  bool checkWillMerge(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return false;
    if (board[row][col] != 0) return false;

    // ボードをコピーしてシミュレーション
    final tempBoard = List.generate(
      boardSize,
      (i) => List<int>.from(board[i]),
    );

    // タイルを配置
    tempBoard[row][col] = currentNumber;
    int tempRow = row;
    int tempCol = col;

    // 全てのマージで消えるタイルを収集
    final allMergedPositions = <Position>[];

    // マージをシミュレーション
    bool merged = true;
    while (merged) {
      merged = false;

      // 最後に配置した位置からマージをチェック
      if (tempBoard[tempRow][tempCol] != 0) {
        final number = tempBoard[tempRow][tempCol];
        final group = _findConnectedGroupInBoard(tempBoard, tempRow, tempCol, number);

        if (group.length >= 3) {
          // このグループを記録
          allMergedPositions.addAll(group);

          // グループを削除して1つ大きい数字に
          for (var pos in group) {
            tempBoard[pos.row][pos.col] = 0;
          }
          tempBoard[tempRow][tempCol] = number + 1;
          merged = true;
        }
      }

      // 他の場所もチェック
      if (!merged) {
        for (int r = 0; r < boardSize; r++) {
          for (int c = 0; c < boardSize; c++) {
            if (tempBoard[r][c] == 0) continue;
            if (r == tempRow && c == tempCol) continue;

            final number = tempBoard[r][c];
            final group = _findConnectedGroupInBoard(tempBoard, r, c, number);

            if (group.length >= 3) {
              allMergedPositions.addAll(group);
              for (var pos in group) {
                tempBoard[pos.row][pos.col] = 0;
              }
              tempBoard[r][c] = number + 1;
              tempRow = r;
              tempCol = c;
              merged = true;
              break;
            }
          }
          if (merged) break;
        }
      }
    }

    if (allMergedPositions.isNotEmpty) {
      pendingMergePositions = allMergedPositions;
      pendingMergeNumber = currentNumber;
      return true;
    }
    return false;
  }

  // 指定されたボードでグループを検索
  List<Position> _findConnectedGroupInBoard(
    List<List<int>> tempBoard,
    int startRow,
    int startCol,
    int number,
  ) {
    final visited = List.generate(boardSize, (_) => List.filled(boardSize, false));
    final group = <Position>[];

    void dfs(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return;
      if (visited[row][col]) return;
      if (tempBoard[row][col] != number) return;

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

  List<Position> findConnectedGroup(
    int startRow,
    int startCol,
    int number, {
    int? virtualRow,
    int? virtualCol,
    int? virtualNumber,
  }) {
    final visited = List.generate(boardSize, (_) => List.filled(boardSize, false));
    final group = <Position>[];

    void dfs(int row, int col) {
      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) return;
      if (visited[row][col]) return;

      // 仮想タイルの位置かチェック
      final cellNumber = (virtualRow != null &&
              virtualCol != null &&
              row == virtualRow &&
              col == virtualCol)
          ? virtualNumber
          : board[row][col];

      if (cellNumber != number) return;

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

        // 基本スコア
        int baseScore = number + 1;

        // コンボボーナス
        // 1コンボ（comboCount=0）: ボーナスなし
        // 2コンボ（comboCount=1）: 2倍
        // 3コンボ（comboCount=2）: 3倍
        // 4コンボ以上: 4倍
        int comboMultiplier = 1;
        if (comboCount >= 1) {
          comboMultiplier = (comboCount + 1).clamp(1, 4);
        }

        score += baseScore * comboMultiplier;
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
