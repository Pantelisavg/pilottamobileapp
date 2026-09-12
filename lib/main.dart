import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/pilotta_theme.dart';

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
      theme: buildPilottaTheme(),
      home: const HomeScreen(),
    );
  }
}
