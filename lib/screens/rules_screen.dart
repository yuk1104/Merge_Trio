import 'package:flutter/material.dart';
import '../widgets/game_colors.dart';
import '../widgets/rule_demo_tile.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F3460),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'HOW TO PLAY',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleWithDemo(
              'ルール',
              '3つ以上隣接でマージ',
            ),
            const SizedBox(height: 32),
            _buildScoreDemo(),
            const SizedBox(height: 32),
            _buildScoreColors(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleWithDemo(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: GameColors.accentPinkLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.3,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: GameColors.accentPinkLight,
                blurRadius: 20,
              ),
              Shadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RuleDemoTile(number: 2),
              const SizedBox(width: 4),
              const RuleDemoTile(number: 2),
              const SizedBox(width: 4),
              const RuleDemoTile(number: 2),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const RuleDemoTile(number: 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'スコア',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: GameColors.accentPinkLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildScoreExample('1回目', [2, 2, 2], 3, '×1', '+3点'),
        const SizedBox(height: 12),
        _buildScoreExample('2 combo', [3, 3, 3], 4, '×2', '+8点'),
        const SizedBox(height: 12),
        _buildScoreExample('3 combo', [4, 4, 4], 5, '×3', '+15点'),
        const SizedBox(height: 12),
        _buildScoreExample('4 combo', [5, 5, 5], 6, '×4', '+24点'),
      ],
    );
  }

  Widget _buildScoreExample(
    String label,
    List<int> tiles,
    int result,
    String multiplier,
    String score,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ...tiles.map((num) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: RuleDemoTile(number: num, size: 36),
                )),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            RuleDemoTile(number: result, size: 36),
            const SizedBox(width: 12),
            Text(
              multiplier,
              style: const TextStyle(
                fontSize: 16,
                color: GameColors.accentPinkLight,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              score,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreColors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'スコアカラー',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: GameColors.accentPinkLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _buildColorBar('0-99', Colors.white),
        const SizedBox(height: 8),
        _buildColorBar('100+', const Color(0xFFFF6B9D)),
        const SizedBox(height: 8),
        _buildColorBar('200+', const Color(0xFF9D4EDD)),
        const SizedBox(height: 8),
        _buildColorBar('300+', const Color(0xFFFFC738)),
      ],
    );
  }

  Widget _buildColorBar(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
