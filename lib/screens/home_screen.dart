import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'bluetooth_lobby_screen.dart';
import 'local_game_screen.dart';
import 'online_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _targetScore = 101;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ΠΙΛΟΤΤΑ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    )),
                const SizedBox(height: 4),
                const Text('Παλαριστή',
                    style: TextStyle(color: Colors.white60, fontSize: 16, letterSpacing: 2)),
                const SizedBox(height: 40),
                _TargetScoreSelector(
                  value: _targetScore,
                  onChanged: (v) => setState(() => _targetScore = v),
                ),
                const SizedBox(height: 28),
                _MenuButton(
                  icon: Icons.smart_toy_outlined,
                  label: 'Παιχνίδι με Bots',
                  subtitle: 'Τοπικά, χωρίς σύνδεση',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LocalGameScreen(targetScore: _targetScore),
                  )),
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  icon: Icons.public,
                  label: 'Online Παιχνίδι',
                  subtitle: 'Παίξε με φίλους μέσω server',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const OnlineLobbyScreen(),
                  )),
                ),
                // Nearby Connections (the Bluetooth/local-network backend)
                // is an Android-only plugin.
                if (!kIsWeb && Platform.isAndroid) ...[
                  const SizedBox(height: 12),
                  _MenuButton(
                    icon: Icons.bluetooth,
                    label: 'Bluetooth / Τοπικό δίκτυο',
                    subtitle: 'Παίξε χωρίς internet',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const BluetoothLobbyScreen(),
                    )),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetScoreSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TargetScoreSelector({required this.value, required this.onChanged});

  static const options = [101, 151, 201];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Πόντοι νίκης', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (final option in options)
              ButtonSegment(value: option, label: Text('$option')),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
          style: SegmentedButton.styleFrom(
            foregroundColor: Colors.white,
            selectedForegroundColor: Colors.black,
            selectedBackgroundColor: Colors.amber,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Material(
        color: const Color(0xFF13543F),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.amber, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          )),
                      Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
