import 'package:just_audio/just_audio.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal() {
    _initializePlayers();
  }

  bool _soundEnabled = true;
  AudioPlayer? _tapPlayer;
  AudioPlayer? _mergePlayer;
  AudioPlayer? _comboPlayer;
  AudioPlayer? _gameOverPlayer;
  bool _initialized = false;

  // フリーの効果音URL（Mixkit - https://mixkit.co/）
  static const String _tapSound = 'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3';
  static const String _mergeSound = 'https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3';
  static const String _comboSound = 'https://assets.mixkit.co/active_storage/sfx/2018/2018-preview.mp3';
  static const String _gameOverSound = 'https://assets.mixkit.co/active_storage/sfx/2001/2001-preview.mp3';

  Future<void> _initializePlayers() async {
    if (_initialized) return;

    try {
      _tapPlayer = AudioPlayer();
      _mergePlayer = AudioPlayer();
      _comboPlayer = AudioPlayer();
      _gameOverPlayer = AudioPlayer();

      // 事前にURLを設定
      await _tapPlayer?.setUrl(_tapSound);
      await _mergePlayer?.setUrl(_mergeSound);
      await _comboPlayer?.setUrl(_comboSound);
      await _gameOverPlayer?.setUrl(_gameOverSound);

      // 音量を設定
      await _tapPlayer?.setVolume(0.2);
      await _mergePlayer?.setVolume(0.3);
      await _comboPlayer?.setVolume(0.4);
      await _gameOverPlayer?.setVolume(0.4);

      _initialized = true;
    } catch (e) {
      // 初期化エラーを無視
    }
  }

  Future<void> playTap() async {
    if (!_soundEnabled || !_initialized || _tapPlayer == null) return;
    try {
      await _tapPlayer!.seek(Duration.zero);
      _tapPlayer!.play();
    } catch (e) {
      // エラーを無視
    }
  }

  Future<void> playMerge(int level) async {
    if (!_soundEnabled || !_initialized || _mergePlayer == null) return;
    try {
      await _mergePlayer!.seek(Duration.zero);
      _mergePlayer!.play();
    } catch (e) {
      // エラーを無視
    }
  }

  Future<void> playCombo(int combo) async {
    if (!_soundEnabled || !_initialized || _comboPlayer == null) return;
    try {
      await _comboPlayer!.seek(Duration.zero);
      _comboPlayer!.play();
    } catch (e) {
      // エラーを無視
    }
  }

  Future<void> playGameOver() async {
    if (!_soundEnabled || !_initialized || _gameOverPlayer == null) return;
    try {
      await _gameOverPlayer!.seek(Duration.zero);
      _gameOverPlayer!.play();
    } catch (e) {
      // エラーを無視
    }
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  bool get isSoundEnabled => _soundEnabled;

  void dispose() {
    _tapPlayer?.dispose();
    _mergePlayer?.dispose();
    _comboPlayer?.dispose();
    _gameOverPlayer?.dispose();
  }
}
