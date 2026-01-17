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
        child: SafeArea(
          child: Column(
            children: [
              // 戻るボタン
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ),
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
