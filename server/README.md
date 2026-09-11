# Pilotta online server

A small Dart WebSocket server that hosts online Pilotta rooms. It shares its
game logic (`PilottaRoom`) with the rest of this repo via the
`pilotta_protocol` package, so the rules enforced here are identical to
local hotseat play in the app.

## Running it

```bash
cd server
dart pub get
dart run bin/server.dart
```

By default it listens on port 8080; override with the `PORT` environment
variable. It exposes:

- `GET /` — a plaintext health check.
- `ws://<host>:<port>/ws` — the game WebSocket endpoint.

## Pointing the app at it

In the app's "Online Παιχνίδι" lobby, enter the server's WebSocket address,
e.g.:

- `ws://10.0.2.2:8080/ws` if you're running the Android emulator and the
  server on the same machine (10.0.2.2 is the emulator's alias for the
  host's localhost).
- `ws://<your-computer's-LAN-IP>:8080/ws` for a real phone on the same
  Wi-Fi network as your computer.
- `wss://your-domain/ws` once you deploy this behind a real host with TLS.

## Deploying

This is a plain Dart application — any host that can run
`dart run bin/server.dart` (or `dart compile exe` it) and expose a port
works: a small VPS, Fly.io, Render, Cloud Run, etc. It keeps all rooms in
memory with no external database, so a restart drops in-progress games —
fine for a small-scale deployment, but worth knowing before you rely on it
for a tournament.

## Tests

```bash
dart test
```

Spins up the real server on an ephemeral port and drives it with real
WebSocket clients (room codes, per-player hand privacy, illegal-move
rejection).
