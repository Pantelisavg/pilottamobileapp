import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'settings/app_settings.dart';
import 'theme/pilotta_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(PilottaApp(settings: settings));
}

class PilottaApp extends StatelessWidget {
  final AppSettings settings;
  const PilottaApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: MaterialApp(
        title: 'Πιλόττα',
        debugShowCheckedModeBanner: false,
        theme: buildPilottaTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
