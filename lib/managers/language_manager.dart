import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  japanese,
  english,
}

class LanguageManager extends ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  static const String _languageKey = 'app_language';
  AppLanguage _currentLanguage = AppLanguage.japanese;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isJapanese => _currentLanguage == AppLanguage.japanese;
  bool get isEnglish => _currentLanguage == AppLanguage.english;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageIndex = prefs.getInt(_languageKey) ?? 0;
      _currentLanguage = AppLanguage.values[languageIndex];
    } catch (e) {
      _currentLanguage = AppLanguage.japanese;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_languageKey, language.index);
    } catch (e) {
      // エラーを無視
    }
  }

  // 言語名を取得
  String getLanguageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.japanese:
        return '日本語';
      case AppLanguage.english:
        return 'English';
    }
  }

  // テキストの翻訳
  String translate(String key) {
    final translations = _currentLanguage == AppLanguage.japanese
        ? _japaneseTranslations
        : _englishTranslations;
    return translations[key] ?? key;
  }

  // 日本語の翻訳
  static final Map<String, String> _japaneseTranslations = {
    // ホーム画面
    'play': 'PLAY',
    'ranking': 'ランキング',
    'settings': '設定',
    'rules': '遊び方',
    'change_skin': 'スキン変更',
    'tile_skin': 'タイルスキン',
    'select_skin': 'お好みのスキンを選択してください',
    'locked': 'ロック中',
    'unlock_skin_info': 'タップしてアンロック方法を確認',

    // ボードサイズ選択
    'standard': 'スタンダード',
    'challenge': 'チャレンジ',

    // ゲーム画面
    'score': 'SCORE',
    'best': 'BEST',
    'combo': 'COMBO',
    'swap': 'SWAP',
    'next': '次',
    'current': '現在',

    // ゲームオーバー
    'game_over': 'GAME OVER',
    'new_record': '新記録！',
    'your_score': 'あなたのスコア',
    'restart': 'RESTART',
    'view_ranking': 'ランキングを見る',
    'back_to_home': 'ホームに戻る',
    'new_record_achieved': '🎉 新記録達成！',
    'sent_to_ranking': 'ランキングに自動送信されました',

    // 設定画面
    'settings_title': '設定',
    'sound': 'サウンド',
    'volume': '音量',
    'skin': 'スキン',
    'language': '言語',
    'language_setting': '言語設定',
    'player_name': 'プレイヤー名',
    'classic': 'クラシック',
    'pastel': 'パステル',
    'unlock_pastel': 'パステルスキンを解放',
    'close': '閉じる',
    'rules_explanation': 'ルール説明',
    'replay': 'リプレイ',
    'language_select': '言語選択 / Select Language',

    // ランキング画面
    'ranking_title': 'ランキング',
    'rank': '順位',
    'player': 'プレイヤー',
    'loading': '読み込み中...',
    'no_rankings': 'まだランキングデータがありません',

    // ルール画面
    'rules_title': '遊び方',
    'rule_1': '1. 同じ数字のタイルを3つ揃えてマージ',
    'rule_2': '2. マージすると次の数字になります',
    'rule_3': '3. 盤面がいっぱいになるとゲームオーバー',
    'rule_4': '4. SWAPボタンで次の数字を入れ替え可能',
    'rule_5': '5. 連続でマージするとコンボボーナス',
  };

  // 英語の翻訳
  static final Map<String, String> _englishTranslations = {
    // ホーム画面
    'play': 'PLAY',
    'ranking': 'RANKING',
    'settings': 'SETTINGS',
    'rules': 'HOW TO PLAY',
    'change_skin': 'Change Skin',
    'tile_skin': 'Tile Skin',
    'select_skin': 'Please select your preferred skin',
    'locked': 'Locked',
    'unlock_skin_info': 'Tap to see how to unlock',

    // ボードサイズ選択
    'standard': 'Standard',
    'challenge': 'Challenge',

    // ゲーム画面
    'score': 'SCORE',
    'best': 'BEST',
    'combo': 'COMBO',
    'swap': 'SWAP',
    'next': 'NEXT',
    'current': 'Current',

    // ゲームオーバー
    'game_over': 'GAME OVER',
    'new_record': 'NEW RECORD!',
    'your_score': 'Your Score',
    'restart': 'RESTART',
    'view_ranking': 'View Ranking',
    'back_to_home': 'Back to Home',
    'new_record_achieved': '🎉 New Record Achieved!',
    'sent_to_ranking': 'Automatically sent to ranking',

    // 設定画面
    'settings_title': 'Settings',
    'sound': 'Sound',
    'volume': 'Volume',
    'skin': 'Skin',
    'language': 'Language',
    'language_setting': 'Language Setting',
    'player_name': 'Player Name',
    'classic': 'Classic',
    'pastel': 'Pastel',
    'unlock_pastel': 'Unlock Pastel Skin',
    'close': 'Close',
    'rules_explanation': 'How to Play',
    'replay': 'Replay',
    'language_select': '言語選択 / Select Language',

    // ランキング画面
    'ranking_title': 'Ranking',
    'rank': 'Rank',
    'player': 'Player',
    'loading': 'Loading...',
    'no_rankings': 'No ranking data yet',

    // ルール画面
    'rules_title': 'How to Play',
    'rule_1': '1. Match 3 tiles with the same number to merge',
    'rule_2': '2. Merged tiles become the next number',
    'rule_3': '3. Game over when the board is full',
    'rule_4': '4. Use SWAP to change the next number',
    'rule_5': '5. Get combo bonus for consecutive merges',
  };
}
