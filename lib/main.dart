import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/game_screen.dart';
import 'screens/name_registration_screen.dart';
import 'managers/ad_manager.dart';
import 'managers/score_manager.dart';
import 'managers/player_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseを初期化
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // AdMobを初期化（エラーを無視）
  try {
    await AdManager().initialize();
  } catch (e) {
    // Web環境などでエラーが発生しても続行
  }

  // スコアマネージャーを初期化
  await ScoreManager().initialize();

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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B9D),
          ),
        ),
      );
    }

    // 登録済みならゲーム画面、未登録なら名前登録画面
    return _isRegistered
        ? const GameScreen()
        : const NameRegistrationScreen();
  }
}
