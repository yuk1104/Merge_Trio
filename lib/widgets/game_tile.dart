import 'package:flutter/material.dart';
import 'game_colors.dart';

class GameTile extends StatelessWidget {
  final int number;
  final bool isAnimating;
  final AnimationController animationController;
  final VoidCallback onTap;

  const GameTile({
    super.key,
    required this.number,
    required this.isAnimating,
    required this.animationController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          final scale = isAnimating
              ? 1.0 + (animationController.value * 0.15 * (1 - animationController.value) * 4)
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                gradient: number == 0
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: GameColors.getTileGradient(number),
                      ),
                color: number == 0 ? Colors.white.withValues(alpha: 0.05) : null,
                borderRadius: BorderRadius.circular(16),
                border: number == 0
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      )
                    : null,
                boxShadow: number != 0
                    ? [
                        BoxShadow(
                          color: GameColors.getTileGlowColor(number).withValues(alpha: 0.6),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: number != 0
                    ? Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: GameColors.getTileTextColor(number),
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
