import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/online_game_controller.dart';
import 'online_game_screen.dart';

/// Lets the player point at a running Pilotta server, then either create a
/// new room or join one with a code a friend shared.
class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _serverController = TextEditingController(text: 'ws://10.0.2.2:8080/ws');
  final _nameController = TextEditingController(text: 'Παίκτης');
  final _roomCodeController = TextEditingController();
  int _targetScore = 101;

  @override
  void dispose() {
    _serverController.dispose();
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Uri? _parseServerUri() {
    final text = _serverController.text.trim();
    final uri = Uri.tryParse(text);
    if (uri == null || (uri.scheme != 'ws' && uri.scheme != 'wss')) return null;
    return uri;
  }

  void _createRoom() {
    final uri = _parseServerUri();
    if (uri == null) return _showBadServerError();
    final controller = OnlineGameController(serverUri: uri);
    controller.createRoom(playerName: _nameController.text.trim(), targetScore: _targetScore);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(value: controller, child: const OnlineGameScreen()),
    ));
  }

  void _joinRoom() {
    final uri = _parseServerUri();
    if (uri == null) return _showBadServerError();
    final code = _roomCodeController.text.trim();
    if (code.isEmpty) return;
    final controller = OnlineGameController(serverUri: uri);
    controller.joinRoom(roomCode: code, playerName: _nameController.text.trim());
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(value: controller, child: const OnlineGameScreen()),
    ));
  }

  void _showBadServerError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Δώσε μια έγκυρη διεύθυνση, π.χ. ws://192.168.1.5:8080/ws')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF082A20),
        foregroundColor: Colors.white,
        title: const Text('Online Παιχνίδι'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Το όνομά σου'),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(),
              ),
              const SizedBox(height: 20),
              _label('Διεύθυνση διακομιστή'),
              TextField(
                controller: _serverController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(hint: 'ws://host:port/ws'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Χρειάζεται να τρέχει ο διακομιστής pilotta_server (δες server/README.md).',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13543F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Δημιουργία νέου δωματίου',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    _label('Πόντοι νίκης'),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 101, label: Text('101')),
                        ButtonSegment(value: 151, label: Text('151')),
                        ButtonSegment(value: 201, label: Text('201')),
                      ],
                      selected: {_targetScore},
                      onSelectionChanged: (s) => setState(() => _targetScore = s.first),
                      style: SegmentedButton.styleFrom(
                        foregroundColor: Colors.white,
                        selectedForegroundColor: Colors.black,
                        selectedBackgroundColor: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _createRoom,
                      icon: const Icon(Icons.add),
                      label: const Text('Δημιουργία δωματίου'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13543F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Συμμετοχή με κωδικό',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _roomCodeController,
                      style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 20),
                      textCapitalization: TextCapitalization.characters,
                      decoration: _fieldDecoration(hint: 'ΚΩΔΙΚΟΣ'),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _joinRoom,
                      icon: const Icon(Icons.login),
                      label: const Text('Συμμετοχή'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      );

  InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
