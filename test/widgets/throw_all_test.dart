import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilotta/widgets/table/game_table_data.dart';
import 'package:pilotta/widgets/table/throw_all.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

/// A scriptable [GameTableData] double: only the members [throwAll] actually
/// touches (phase, isViewerTurnToPlay, viewerLegalPlays, playCard, plus the
/// Listenable machinery) are real; anything else throws if ever called,
/// via [noSuchMethod] — Dart's supported way to satisfy an interface
/// without hand-writing a stub for every one of its ~30 members.
class _FakeGameTableData extends ChangeNotifier implements GameTableData {
  @override
  RoomPhase phase = RoomPhase.playing;
  @override
  bool isViewerTurnToPlay = true;
  @override
  List<PlayingCard> viewerLegalPlays = const [];
  final List<PlayingCard> played = [];

  @override
  void playCard(PlayingCard card) {
    played.add(card);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

const _seven = PlayingCard(Suit.spades, Rank.seven);
const _eight = PlayingCard(Suit.spades, Rank.eight);
const _nine = PlayingCard(Suit.spades, Rank.nine);

void main() {
  test('does nothing when the viewer already has a real choice', () async {
    final fake = _FakeGameTableData()..viewerLegalPlays = [_seven, _eight];
    await throwAll(fake);
    expect(fake.played, isEmpty);
  });

  test('does nothing when it is not the viewer\'s turn to play', () async {
    final fake = _FakeGameTableData()
      ..isViewerTurnToPlay = false
      ..viewerLegalPlays = [_seven];
    await throwAll(fake);
    expect(fake.played, isEmpty);
  });

  test(
      'plays a forced card, then keeps going through further forced tricks, '
      'stopping the instant a real choice appears', () async {
    final fake = _FakeGameTableData()..viewerLegalPlays = [_seven];

    // Simulate the room settling after each forced play: still forced for
    // trick 2, then a real choice opens up for trick 3.
    var playCount = 0;
    fake.addListener(() {
      playCount++;
      if (playCount == 1) {
        fake.viewerLegalPlays = [_eight]; // still forced
      } else if (playCount == 2) {
        fake.viewerLegalPlays = [_nine, _seven]; // real choice now
      }
    });

    await throwAll(fake);

    expect(fake.played, [_seven, _eight]);
    expect(fake.viewerLegalPlays, [_nine, _seven]);
  });

  test(
      'waits asynchronously (across a real Future boundary, simulating a '
      'bot-play delay) before resuming the forced streak', () async {
    final fake = _FakeGameTableData()..viewerLegalPlays = [_seven];

    // Right after the first forced card, simulate the room going quiet
    // while a bot takes its turn: a real async gap (not a synchronous
    // re-notify) during which isViewerTurnToPlay is false, exercising the
    // _nextChange wait loop for real. Once the second forced card is
    // played, open up a real choice so the streak actually stops.
    var asyncGapStarted = false;
    fake.addListener(() {
      if (!asyncGapStarted && fake.played.length == 1) {
        asyncGapStarted = true;
        fake.isViewerTurnToPlay = false;
        Future.delayed(const Duration(milliseconds: 10), () {
          fake.isViewerTurnToPlay = true;
          fake.viewerLegalPlays = [_eight];
          fake.notifyListeners();
        });
      } else if (fake.played.length == 2) {
        fake.viewerLegalPlays = [_nine, _seven]; // real choice now
      }
    });

    await throwAll(fake);

    expect(fake.played, [_seven, _eight]);
    expect(fake.viewerLegalPlays, [_nine, _seven]);
  });

  test('stops as soon as the hand ends mid-streak', () async {
    final fake = _FakeGameTableData()..viewerLegalPlays = [_seven];

    fake.addListener(() {
      fake.phase = RoomPhase.handSummary;
    });

    await throwAll(fake);

    expect(fake.played, [_seven]);
  });
}
