import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/name_registration_screen.dart';
import 'managers/ad_manager.dart';
import 'managers/score_manager.dart';
import 'managers/player_manager.dart';
import 'managers/sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 画面の向きを縦のみに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebaseを初期化
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Firebase匿名認証を初期化（UIDの永続化）
    await _initializeAuth();
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // AdMobを初期化（エラーを無視）
  try {
    await AdManager().initialize();
  } catch (e) {
    // Web環境などでエラーが発生しても続行
  }

  // スコアマネージャーを初期化
  await ScoreManager().initialize();

  // サウンドマネージャーを初期化（効果音の準備）
  final soundManager = SoundManager();
  // 初期化完了を待つために少し待機
  await Future.delayed(const Duration(milliseconds: 500));

  runApp(const MergeTrioApp());
}

// Firebase匿名認証の初期化とUID永続化
Future<void> _initializeAuth() async {
  const storage = FlutterSecureStorage();
  const uidKey = 'firebase_uid';
  const customTokenKey = 'firebase_custom_token';

  try {
    // 保存されているUIDを取得
    final savedUid = await storage.read(key: uidKey);
    debugPrint('Saved UID: $savedUid');

    if (FirebaseAuth.instance.currentUser == null) {
      if (savedUid != null) {
        // 保存されているUIDがある場合、Firestoreからデータを復元
        debugPrint('Restoring data for UID: $savedUid');
        await _restoreUserData(savedUid);
      }

      // 匿名ログイン
      debugPrint('Signing in anonymously...');
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final newUid = userCredential.user?.uid;
      debugPrint('Signed in with UID: $newUid');

      // UIDを保存
      if (newUid != null) {
        await storage.write(key: uidKey, value: newUid);
        debugPrint('Saved UID to secure storage');
      }
    } else {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('Already signed in: $currentUid');

      // 現在のUIDを保存
      if (currentUid != null) {
        await storage.write(key: uidKey, value: currentUid);
      }
    }
  } catch (e, stackTrace) {
    debugPrint('Auth initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

// Firestoreからユーザーデータを復元
Future<void> _restoreUserData(String uid) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // 1. ランキングデータから名前を取得
    final leaderboardDoc = await firestore.collection('leaderboard').doc(uid).get();

    if (leaderboardDoc.exists) {
      final data = leaderboardDoc.data();
      final playerName = data?['playerName'] as String?;
      final bestScore = data?['score'] as int?;

      debugPrint('Restoring data: name=$playerName, score=$bestScore');

      // 2. プレイヤー名を復元
      if (playerName != null && playerName.isNotEmpty) {
        await PlayerManager().setPlayerName(playerName);
        debugPrint('Restored player name: $playerName');
      }

      // 3. ベストスコアを復元
      if (bestScore != null) {
        await ScoreManager().initialize();
        // ScoreManagerの内部データを更新
        await ScoreManager().checkAndUpdateBestScore(bestScore);
        debugPrint('Restored best score: $bestScore');
      }
    } else {
      debugPrint('No data found for UID: $uid');
    }
  } catch (e, stackTrace) {
    debugPrint('Error restoring user data: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

class MergeTrioApp extends StatelessWidget {
  const MergeTrioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merge Trio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isChecking = true;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final isRegistered = await PlayerManager().isPlayerNameRegistered();
    if (mounted) {
      setState(() {
        _isRegistered = isRegistered;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // ローディング画面
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6B9D),
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    // 登録済みならホーム画面、未登録なら名前登録画面
    return _isRegistered
        ? const HomeScreen()
        : const NameRegistrationScreen();
  }
}
