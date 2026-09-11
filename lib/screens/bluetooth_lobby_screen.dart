import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bluetooth/bluetooth_game_controller.dart';
import '../bluetooth/bluetooth_host_session.dart';
import '../controllers/room_client_controller.dart';
import 'networked_game_screen.dart';

/// Entry point for offline, no-internet multiplayer over Bluetooth/local
/// network (Nearby Connections): host a table for others to find, or
/// search for one nearby and join it.
class BluetoothLobbyScreen extends StatefulWidget {
  const BluetoothLobbyScreen({super.key});

  @override
  State<BluetoothLobbyScreen> createState() => _BluetoothLobbyScreenState();
}

class _BluetoothLobbyScreenState extends State<BluetoothLobbyScreen> {
  final _nameController = TextEditingController(text: 'Παίκτης');
  int _targetScore = 101;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _hostGame() {
    final name = _nameController.text.trim().isEmpty ? 'Οικοδεσπότης' : _nameController.text.trim();
    final session = BluetoothHostSession(targetScore: _targetScore, hostName: name);
    session.startAdvertising();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<RoomClientController>.value(
        value: session,
        child: const NetworkedGameScreen(),
      ),
    ));
  }

  void _findGame() {
    final name = _nameController.text.trim().isEmpty ? 'Παίκτης' : _nameController.text.trim();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BluetoothDiscoveryScreen(playerName: name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF082A20),
        foregroundColor: Colors.white,
        title: const Text('Bluetooth / Τοπικό δίκτυο'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Παίξτε χωρίς internet: μία συσκευή φιλοξενεί το τραπέζι, '
                'οι υπόλοιπες τη βρίσκουν κοντά τους μέσω Bluetooth/Wi-Fi.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
              const Text('Το όνομά σου', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    const Text('Φιλοξένησε παιχνίδι',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    const Text('Πόντοι νίκης', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
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
                      onPressed: _hostGame,
                      icon: const Icon(Icons.wifi_tethering),
                      label: const Text('Φιλοξένησε'),
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
                    const Text('Βρες παιχνίδι κοντά σου',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _findGame,
                      icon: const Icon(Icons.search),
                      label: const Text('Αναζήτηση'),
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
}

/// Live list of nearby hosts advertising a table; tap one to connect.
class BluetoothDiscoveryScreen extends StatefulWidget {
  final String playerName;
  const BluetoothDiscoveryScreen({super.key, required this.playerName});

  @override
  State<BluetoothDiscoveryScreen> createState() => _BluetoothDiscoveryScreenState();
}

class _BluetoothDiscoveryScreenState extends State<BluetoothDiscoveryScreen> {
  late final BluetoothGameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BluetoothGameController(playerName: widget.playerName);
    _controller.startDiscovery();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_controller.inRoom) {
      _controller.removeListener(_onControllerChanged);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<RoomClientController>.value(
          value: _controller,
          child: const NetworkedGameScreen(),
        ),
      ));
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (!_controller.inRoom) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF082A20),
        foregroundColor: Colors.white,
        title: const Text('Αναζήτηση τραπεζιών'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_controller.status == ConnectionStatus.connecting)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Σύνδεση...', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            if (_controller.lastError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_controller.lastError!, style: const TextStyle(color: Colors.redAccent)),
              ),
            Expanded(
              child: _controller.discoveredHosts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Αναζήτηση για κοντινά τραπέζια...\nΒεβαιώσου ότι το Bluetooth και η Τοποθεσία είναι ενεργά.',
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final entry in _controller.discoveredHosts.entries)
                          ListTile(
                            leading: const Icon(Icons.table_bar, color: Colors.amber),
                            title: Text(entry.value, style: const TextStyle(color: Colors.white)),
                            subtitle: const Text('Πάτησε για σύνδεση',
                                style: TextStyle(color: Colors.white38)),
                            onTap: () => _controller.connectToHost(entry.key),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
