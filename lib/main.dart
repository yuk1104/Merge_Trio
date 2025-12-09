import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Firebase匿名認証を初期化（少し待ってから実行）
    await Future.delayed(const Duration(milliseconds: 500));

    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('Attempting anonymous sign in...');
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint('Firebase anonymous auth initialized: ${userCredential.user?.uid}');
    } else {
      debugPrint('Already signed in: ${FirebaseAuth.instance.currentUser?.uid}');
    }
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
