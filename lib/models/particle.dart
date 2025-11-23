import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.life = 1.0,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.2; // 重力
    life -= 0.02;
  }

  bool get isDead => life <= 0;
}
