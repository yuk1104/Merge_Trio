import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
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
