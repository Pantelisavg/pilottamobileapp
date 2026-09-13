/// Transport-agnostic wire protocol for multiplayer Pilotta, shared by the
/// online (WebSocket) server, the online client, and the Bluetooth/local
/// network peer-to-peer transport.
library pilotta_protocol;

export 'src/chat.dart';
export 'src/codec.dart';
export 'src/messages.dart';
export 'src/room.dart';
export 'src/save.dart';
