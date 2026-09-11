import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around the `nearby_connections` plugin (Google's Nearby
/// Connections API): Bluetooth + Wi-Fi Direct peer-to-peer, no internet or
/// access point required — the offline fallback for when players have no
/// connectivity to reach an online server.
///
/// Android only, per the underlying plugin. iOS/web builds simply never
/// offer the Bluetooth mode in the UI.
///
/// This class only speaks bytes; [BluetoothHostSession] and
/// [BluetoothGameController] are the ones that know these bytes are UTF-8
/// JSON [ClientMessage]/[ServerMessage] payloads from pilotta_protocol.
class NearbyTransport {
  /// Identifies this app to Nearby Connections; arbitrary but must match
  /// between advertiser and discoverer to find each other.
  static const String serviceId = 'gr.pilottamobileapp.pilotta';

  /// Recommended by the plugin for small payloads and multiplayer games,
  /// and it's the shape we need: one host connected to up to three guests,
  /// who never need to connect to each other.
  static const Strategy strategy = Strategy.P2P_CLUSTER;

  final Nearby _nearby = Nearby();

  /// Requests every runtime permission Nearby Connections needs on this
  /// Android version. Returns true only if all of them were granted.
  Future<bool> ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  // ------------------------------------------------------------- hosting

  Future<bool> startAdvertising({
    required String userName,
    required void Function(String endpointId, String endpointName) onConnectionRequested,
    required void Function(String endpointId, Status status) onConnectionResult,
    required void Function(String endpointId) onDisconnected,
  }) {
    return _nearby.startAdvertising(
      userName,
      strategy,
      serviceId: serviceId,
      onConnectionInitiated: (id, info) => onConnectionRequested(id, info.endpointName),
      onConnectionResult: onConnectionResult,
      onDisconnected: onDisconnected,
    );
  }

  Future<void> stopAdvertising() => _nearby.stopAdvertising();

  // ------------------------------------------------------------ discovery

  Future<bool> startDiscovery({
    required String userName,
    required void Function(String endpointId, String hostName) onHostFound,
    required void Function(String endpointId) onHostLost,
  }) {
    return _nearby.startDiscovery(
      userName,
      strategy,
      serviceId: serviceId,
      onEndpointFound: (id, name, service) => onHostFound(id, name),
      onEndpointLost: (id) {
        if (id != null) onHostLost(id);
      },
    );
  }

  Future<void> stopDiscovery() => _nearby.stopDiscovery();

  Future<bool> requestConnection({
    required String userName,
    required String hostEndpointId,
    required void Function(String endpointId, String message) onMessage,
    required void Function(String endpointId, Status status) onConnectionResult,
    required void Function(String endpointId) onDisconnected,
  }) {
    return _nearby.requestConnection(
      userName,
      hostEndpointId,
      onConnectionInitiated: (id, info) {
        // We only ever request a connection to a host we deliberately
        // picked from the discovered list, so accept unconditionally.
        _nearby.acceptConnection(id, onPayLoadRecieved: (fromId, payload) {
          if (payload.type == PayloadType.BYTES && payload.bytes != null) {
            onMessage(fromId, utf8.decode(payload.bytes!));
          }
        });
      },
      onConnectionResult: onConnectionResult,
      onDisconnected: onDisconnected,
    );
  }

  // -------------------------------------------------------------- shared

  /// Accepts an incoming connection request (host side), wiring
  /// [onMessage] as the payload handler for that endpoint.
  Future<bool> acceptConnection(
    String endpointId, {
    required void Function(String endpointId, String message) onMessage,
  }) {
    return _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (fromId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          onMessage(fromId, utf8.decode(payload.bytes!));
        }
      },
    );
  }

  Future<void> rejectConnection(String endpointId) => _nearby.rejectConnection(endpointId);

  void sendMessage(String endpointId, String jsonMessage) {
    _nearby.sendBytesPayload(endpointId, Uint8List.fromList(utf8.encode(jsonMessage)));
  }

  Future<void> disconnectFromEndpoint(String endpointId) => _nearby.disconnectFromEndpoint(endpointId);

  Future<void> stopAllEndpoints() => _nearby.stopAllEndpoints();
}
