import 'package:flutter/material.dart';

class RuleDemoTile extends StatelessWidget {
  final int number;
  final double size;

  const RuleDemoTile({
    super.key,
    required this.number,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: number == 0
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getTileColors(number),
              ),
        color: number == 0 ? Colors.white.withValues(alpha: 0.05) : null,
        borderRadius: BorderRadius.circular(8),
        border: number == 0
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              )
            : null,
        boxShadow: number != 0
            ? [
                BoxShadow(
                  color: _getTileColors(number).first.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: number != 0
            ? Text(
                '$number',
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w900,
                  color: number == 1 ? Colors.orange[800]! : Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  List<Color> _getTileColors(int number) {
    switch (number) {
      case 1:
        return [const Color(0xFFFFF9C4), const Color(0xFFFFF59D)];
      case 2:
        return [const Color(0xFFFFCC80), const Color(0xFFFFB74D)];
      case 3:
        return [const Color(0xFFFF9800), const Color(0xFFFB8C00)];
      case 4:
        return [const Color(0xFFEF5350), const Color(0xFFE53935)];
      case 5:
        return [const Color(0xFFAB47BC), const Color(0xFF8E24AA)];
      case 6:
        return [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
      case 7:
        return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
      default:
        return [const Color(0xFFEEEEEE), const Color(0xFFE0E0E0)];
    }
  }
}
