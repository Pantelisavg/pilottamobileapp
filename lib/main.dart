import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PilottaApp());
}

class PilottaApp extends StatelessWidget {
  const PilottaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Πιλόττα',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3D2E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
