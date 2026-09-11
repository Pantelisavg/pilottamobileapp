/// Pure-Dart rules engine for Pilotta (Παλαριστή): cards, auction/bidding,
/// declarations, trick-taking, scoring, and a full hand/match orchestrator.
/// Has no Flutter dependency so it can be shared by the mobile app, a
/// future web build, and a server (e.g. for online multiplayer or bots).
library pilotta_engine;

export 'src/auction.dart';
export 'src/bot.dart';
export 'src/card.dart';
export 'src/dealer.dart';
export 'src/declaration.dart';
export 'src/match.dart';
export 'src/round.dart';
export 'src/scoring.dart';
export 'src/seat.dart';
export 'src/trick.dart';
