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
    'neon': 'ネオン',
    'unlock_pastel': 'パステルスキンを解放',
    'unlock_neon_description': '友達を招待してネオンスキンをアンロックしよう！\n\nあなたの招待コードを友達にシェアして、友達がコードを入力するとカウントされます。\n\n※招待コードを入力した友達にも1カウントのボーナスが付与されます。',
    'share_progress': '招待進捗',
    'unlock_conditions': 'アンロック条件',
    'share_with_friends': '友達3人があなたの招待コードを使用',
    'neon_unlocked': 'ネオンスキンがアンロックされました！',
    'close': '閉じる',
    'rules_explanation': 'ルール説明',
    'replay': 'リプレイ',
    'language_select': '言語選択 / Select Language',
    'share_app': 'アプリを共有',
    'share_message': 'MERGE TRIO - 数字を3つ揃えてマージする中毒性のあるパズルゲーム！\n\nhttps://apps.apple.com/jp/app/%E3%83%9E%E3%83%BC%E3%82%B8%E3%83%88%E3%83%AA%E3%82%AA-merge-trio/id6755914647',

    // 招待コード関連
    'have_invite_code': '招待コードをお持ちですか？',
    'invite_code_description': '友達から招待コードをもらった場合は入力してください',
    'enter_invite_code': '招待コードを入力してください',
    'invalid_invite_code': '無効な招待コードです',
    'invite_code_success': '招待コードが適用されました！',
    'invite_code_success_message': 'ネオンスキンのアンロックに1歩近づきました！',
    'submit': '送信',
    'skip': 'スキップ',
    'my_invite_code': 'あなたの招待コード',
    'invite_friends': '友達を招待',
    'invite_count': '招待人数',
    'copy_code': 'コードをコピー',
    'code_copied': 'コピーしました！',

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
    'neon': 'Neon',
    'unlock_pastel': 'Unlock Pastel Skin',
    'unlock_neon_description': 'Invite your friends to unlock the Neon skin!\n\nShare your invite code with friends. When they enter your code in the app, it counts towards unlocking.\n\n※Friends who enter your code will also receive a +1 bonus count.',
    'share_progress': 'Invite Progress',
    'unlock_conditions': 'Unlock Conditions',
    'share_with_friends': '3 friends use your invite code',
    'neon_unlocked': 'Neon skin unlocked!',
    'close': 'Close',
    'rules_explanation': 'How to Play',
    'replay': 'Replay',
    'language_select': '言語選択 / Select Language',
    'share_app': 'Share App',
    'share_message': 'MERGE TRIO - Addictive puzzle game! Match 3 numbers to merge!\n\nhttps://apps.apple.com/jp/app/%E3%83%9E%E3%83%BC%E3%82%B8%E3%83%88%E3%83%AA%E3%82%AA-merge-trio/id6755914647',

    // 招待コード関連
    'have_invite_code': 'Have an invite code?',
    'invite_code_description': 'Enter it if you received one from a friend',
    'enter_invite_code': 'Please enter invite code',
    'invalid_invite_code': 'Invalid invite code',
    'invite_code_success': 'Invite code applied!',
    'invite_code_success_message': 'One step closer to unlocking the Neon skin!',
    'submit': 'Submit',
    'skip': 'Skip',
    'my_invite_code': 'Your Invite Code',
    'invite_friends': 'Invite Friends',
    'invite_count': 'Invites',
    'copy_code': 'Copy Code',
    'code_copied': 'Copied!',

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
