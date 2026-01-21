import 'package:shared_preferences/shared_preferences.dart';
import 'ranking_manager.dart';
import 'player_manager.dart';

class ScoreManager {
  static final ScoreManager _instance = ScoreManager._internal();
  factory ScoreManager() => _instance;
  ScoreManager._internal();

  static const String _bestScoreKey4x4 = 'best_score_4x4';
  static const String _bestScoreKey5x5 = 'best_score_5x5';
  static const String _legacyBestScoreKey = 'best_score'; // 旧バージョンとの互換性
  int _bestScore4x4 = 0;
  int _bestScore5x5 = 0;
  bool _initialized = false;

  int getBestScore(int boardSize) => boardSize == 4 ? _bestScore4x4 : _bestScore5x5;

  // 後方互換性のため
  int get bestScore => _bestScore4x4;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 旧バージョンのスコアを4x4に移行
      final legacyScore = prefs.getInt(_legacyBestScoreKey);
      if (legacyScore != null && legacyScore > 0) {
        _bestScore4x4 = legacyScore;
        await prefs.setInt(_bestScoreKey4x4, legacyScore);
        await prefs.remove(_legacyBestScoreKey);
      } else {
        _bestScore4x4 = prefs.getInt(_bestScoreKey4x4) ?? 0;
      }

      _bestScore5x5 = prefs.getInt(_bestScoreKey5x5) ?? 0;
      _initialized = true;
    } catch (e) {
      // エラーが発生しても続行（初期化失敗時はメモリ内のみで動作）
      _initialized = true;
    }
  }

  Future<bool> checkAndUpdateBestScore(int currentScore, int boardSize) async {
    if (!_initialized) {
      await initialize();
    }

    final currentBest = getBestScore(boardSize);
    if (currentScore > currentBest) {
      if (boardSize == 4) {
        _bestScore4x4 = currentScore;
      } else {
        _bestScore5x5 = currentScore;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final key = boardSize == 4 ? _bestScoreKey4x4 : _bestScoreKey5x5;
        await prefs.setInt(key, currentScore);
      } catch (e) {
        // 保存エラーを無視（メモリ内のみで保持）
      }

      // 最高スコア更新時に自動でランキングに送信
      _submitToRanking(currentScore, boardSize);

      return true; // 新記録
    }
    return false; // 新記録ではない
  }

  // ランキングに送信（非同期・バックグラウンド処理）
  void _submitToRanking(int score, int boardSize) async {
    try {
      print('[ScoreManager] Starting ranking submission for score: $score (boardSize: $boardSize)');
      final playerName = await PlayerManager().getPlayerName();
      print('[ScoreManager] Player name: $playerName');

      if (playerName != null && playerName.isNotEmpty) {
        print('[ScoreManager] Submitting to RankingManager...');
        // 通常ランキングに送信
        await RankingManager().submitScore(playerName, score, boardSize);
        print('[ScoreManager] All-time ranking submission completed successfully');

        // 週間ランキングにも送信
        await RankingManager().submitWeeklyScore(playerName, score, boardSize);
        print('[ScoreManager] Weekly ranking submission completed successfully');
      } else {
        print('[ScoreManager] Player name is null or empty, skipping ranking submission');
      }
    } catch (e, stackTrace) {
      // エラーを無視（ランキング送信失敗してもゲームは続行）
      print('[ScoreManager] Error submitting to ranking: $e');
      print('[ScoreManager] Stack trace: $stackTrace');
    }
  }

  // 開発用: スコアデータをリセット
  void clearScoreData() {
    _bestScore4x4 = 0;
    _bestScore5x5 = 0;
    _initialized = false;
  }

  // 全データをクリア（SharedPreferencesも含む）
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bestScoreKey4x4);
      await prefs.remove(_bestScoreKey5x5);
      await prefs.remove(_legacyBestScoreKey);
      _bestScore4x4 = 0;
      _bestScore5x5 = 0;
      _initialized = false;
      print('Score data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing score data: $e');
    }
  }
}
