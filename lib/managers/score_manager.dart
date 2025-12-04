import 'package:shared_preferences/shared_preferences.dart';
import 'ranking_manager.dart';
import 'player_manager.dart';

class ScoreManager {
  static final ScoreManager _instance = ScoreManager._internal();
  factory ScoreManager() => _instance;
  ScoreManager._internal();

  static const String _bestScoreKey = 'best_score';
  int _bestScore = 0;
  bool _initialized = false;

  int get bestScore => _bestScore;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
      _initialized = true;
    } catch (e) {
      // エラーが発生しても続行（初期化失敗時はメモリ内のみで動作）
      _initialized = true;
    }
  }

  Future<bool> checkAndUpdateBestScore(int currentScore) async {
    if (!_initialized) {
      await initialize();
    }

    if (currentScore > _bestScore) {
      _bestScore = currentScore;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_bestScoreKey, _bestScore);
      } catch (e) {
        // 保存エラーを無視（メモリ内のみで保持）
      }

      // 最高スコア更新時に自動でランキングに送信
      _submitToRanking(currentScore);

      return true; // 新記録
    }
    return false; // 新記録ではない
  }

  // ランキングに送信（非同期・バックグラウンド処理）
  void _submitToRanking(int score) async {
    try {
      print('[ScoreManager] Starting ranking submission for score: $score');
      final playerName = await PlayerManager().getPlayerName();
      print('[ScoreManager] Player name: $playerName');

      if (playerName != null && playerName.isNotEmpty) {
        print('[ScoreManager] Submitting to RankingManager...');
        await RankingManager().submitScore(playerName, score);
        print('[ScoreManager] Ranking submission completed successfully');
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
    _bestScore = 0;
    _initialized = false;
  }

  // 全データをクリア（SharedPreferencesも含む）
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bestScoreKey);
      _bestScore = 0;
      _initialized = false;
      print('Score data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing score data: $e');
    }
  }
}
