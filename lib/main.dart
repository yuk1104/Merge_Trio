import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'managers/ad_manager.dart';
import 'managers/score_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const GameScreen(),
    );
  }
}
