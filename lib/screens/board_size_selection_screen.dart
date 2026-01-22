import 'package:flutter/material.dart';
import 'game_screen.dart';
import '../managers/language_manager.dart';

class BoardSizeSelectionScreen extends StatefulWidget {
  const BoardSizeSelectionScreen({super.key});

  @override
  State<BoardSizeSelectionScreen> createState() => _BoardSizeSelectionScreenState();
}

class _BoardSizeSelectionScreenState extends State<BoardSizeSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // LanguageManagerの変更をリッスン
    LanguageManager().addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageManager().removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // タイトル
              const Spacer(flex: 2),
              const Text(
                'MERGE TRIO',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black45,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),

              // ボタン
              Column(
                children: [
                  // 4x4ボタン
                  _buildSizeButton(
                    context: context,
                    size: 4,
                    label: '4 × 4',
                    subtitle: LanguageManager().translate('standard'),
                    color: const Color(0xFF6C5CE7),
                  ),

                  const SizedBox(height: 24),

                  // 5x5ボタン
                  _buildSizeButton(
                    context: context,
                    size: 5,
                    label: '5 × 5',
                    subtitle: LanguageManager().translate('challenge'),
                    color: const Color(0xFFFF6B9D),
                  ),
                ],
              ),
              const Spacer(flex: 2),

              // 戻るボタン（下部）
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  label: Text(
                    LanguageManager().translate('back'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeButton({
    required BuildContext context,
    required int size,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(boardSize: size),
          ),
        );
      },
      child: Container(
        width: 260,
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
