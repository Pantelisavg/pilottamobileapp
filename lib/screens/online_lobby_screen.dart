import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/online_game_controller.dart';
import '../controllers/room_client_controller.dart';
import '../settings/app_settings.dart';
import '../widgets/target_score_selector.dart';
import 'networked_game_screen.dart';

/// Lets the player point at a running Pilotta server, then either create a
/// new room or join one with a code a friend shared.
class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _serverController =
      TextEditingController(text: 'ws://10.0.2.2:8080/ws');
  final _nameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  int _targetScore = kTargetScorePresets.first;
  bool _mustOvertrumpAllSuits = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettings>();
    _mustOvertrumpAllSuits = settings.mustOvertrumpAllSuits;
    _nameController.text = settings.playerName;
  }

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
    controller.createRoom(
      playerName: _nameController.text.trim(),
      targetScore: _targetScore,
      mustOvertrumpAllSuits: _mustOvertrumpAllSuits,
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<RoomClientController>.value(
          value: controller, child: const NetworkedGameScreen()),
    ));
  }

  void _joinRoom() {
    final uri = _parseServerUri();
    if (uri == null) return _showBadServerError();
    final code = _roomCodeController.text.trim();
    if (code.isEmpty) return;
    final controller = OnlineGameController(serverUri: uri);
    controller.joinRoom(
        roomCode: code, playerName: _nameController.text.trim());
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<RoomClientController>.value(
          value: controller, child: const NetworkedGameScreen()),
    ));
  }

  void _showBadServerError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Δώσε μια έγκυρη διεύθυνση, π.χ. ws://192.168.1.5:8080/ws')),
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
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 10),
                    _label('Πόντοι νίκης'),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SegmentedButton<int>(
                          segments: [
                            for (final option in kTargetScorePresets)
                              ButtonSegment(
                                  value: option, label: Text('$option')),
                          ],
                          selected: {_targetScore},
                          onSelectionChanged: (s) =>
                              setState(() => _targetScore = s.first),
                          style: SegmentedButton.styleFrom(
                            foregroundColor: Colors.white,
                            selectedForegroundColor: Colors.black,
                            selectedBackgroundColor: Colors.amber,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final result = await showCustomTargetScoreDialog(
                              context,
                              current: _targetScore,
                            );
                            if (result != null) {
                              setState(() => _targetScore = result);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                !kTargetScorePresets.contains(_targetScore)
                                    ? Colors.black
                                    : Colors.white,
                            backgroundColor:
                                !kTargetScorePresets.contains(_targetScore)
                                    ? Colors.amber
                                    : null,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          child: Text(
                              !kTargetScorePresets.contains(_targetScore)
                                  ? 'Προσαρμογή: $_targetScore'
                                  : 'Προσαρμογή'),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _mustOvertrumpAllSuits,
                      onChanged: (v) =>
                          setState(() => _mustOvertrumpAllSuits = v ?? false),
                      title: const Text(
                          'Υποχρεωτικό ανέβασμα σε όλα τα χρώματα',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(height: 4),
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
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _roomCodeController,
                      style: const TextStyle(
                          color: Colors.white, letterSpacing: 4, fontSize: 20),
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
        child: Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      );

  InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
