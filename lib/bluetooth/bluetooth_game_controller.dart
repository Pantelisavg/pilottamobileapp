import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../controllers/room_client_controller.dart';
import 'nearby_transport.dart';

/// The guest side of a Bluetooth/local-network match: discovers nearby
/// hosts advertising a table, connects to one, and from then on speaks the
/// exact same [ClientMessage]/[ServerMessage] protocol as the online
/// client — just carried over a Nearby Connections link instead of a
/// WebSocket, which is why all the actual game-flow handling lives in the
/// shared [RoomClientController] base class.
class BluetoothGameController extends RoomClientController {
  final String playerName;
  final NearbyTransport _transport = NearbyTransport();

  bool discovering = false;
  String? _hostEndpointId;

  /// endpointId -> advertised host name, for the "pick a table" list.
  final Map<String, String> discoveredHosts = {};

  BluetoothGameController({required this.playerName});

  Future<void> startDiscovery() async {
    final granted = await _transport.ensurePermissions();
    if (!granted) {
      lastError = 'Χρειάζονται δικαιώματα Bluetooth/Τοποθεσίας για αναζήτηση.';
      notifyListeners();
      return;
    }
    try {
      discovering = await _transport.startDiscovery(
        userName: playerName,
        onHostFound: (endpointId, hostName) {
          discoveredHosts[endpointId] = hostName;
          notifyListeners();
        },
        onHostLost: (endpointId) {
          discoveredHosts.remove(endpointId);
          notifyListeners();
        },
      );
    } catch (_) {
      discovering = false;
      lastError = 'Δεν ήταν δυνατή η αναζήτηση μέσω Bluetooth.';
    }
    notifyListeners();
  }

  Future<void> stopDiscovery() async {
    await _transport.stopDiscovery();
    discovering = false;
    notifyListeners();
  }

  Future<void> connectToHost(String endpointId) async {
    await _transport.stopDiscovery();
    discovering = false;
    _hostEndpointId = endpointId;
    status = ConnectionStatus.connecting;
    notifyListeners();

    try {
      await _transport.requestConnection(
        userName: playerName,
        hostEndpointId: endpointId,
        onMessage: (fromId, raw) => _onMessage(raw),
        onConnectionResult: (id, connectionStatus) {
          if (connectionStatus == Status.CONNECTED) {
            status = ConnectionStatus.connected;
            sendMessage(JoinRoomMessage(roomCode: '', playerName: playerName));
          } else {
            status = ConnectionStatus.disconnected;
            lastError = 'Η σύνδεση απορρίφθηκε.';
          }
          notifyListeners();
        },
        onDisconnected: (id) {
          status = ConnectionStatus.disconnected;
          notifyListeners();
        },
      );
    } catch (_) {
      status = ConnectionStatus.disconnected;
      lastError = 'Αποτυχία σύνδεσης.';
      notifyListeners();
    }
  }

  void _onMessage(String raw) {
    try {
      handleServerMessage(ServerMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } catch (_) {
      // Malformed frame: ignore.
    }
  }

  @override
  @protected
  void sendMessage(ClientMessage message) {
    final id = _hostEndpointId;
    if (id == null) return;
    _transport.sendMessage(id, jsonEncode(message.toJson()));
  }

  @override
  void dispose() {
    _transport.stopDiscovery();
    final id = _hostEndpointId;
    if (id != null) _transport.disconnectFromEndpoint(id);
    super.dispose();
  }
}
