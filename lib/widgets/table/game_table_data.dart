import 'package:flutter/foundation.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

/// Everything a shared table UI needs to render a match and act on it,
/// regardless of whether the game is local (a live [PilottaHand]/[Auction]
/// on this device) or networked (reconstructed from a JSON snapshot).
///
/// Implemented by both `LocalGameController` and `RoomClientController` as
/// additive adapter members — this lets `local_game_screen.dart` and
/// `networked_game_screen.dart` share one table widget tree instead of the
/// near-duplicate Stack/Column hierarchies they had before, while each
/// controller keeps its own existing API untouched for any other caller.
abstract interface class GameTableData implements Listenable {
  RoomPhase get phase;
  Seat get viewerSeat;

  /// Transient status text (e.g. "Όλοι πέρασαν — νέα μοιρασιά.").
  String? get banner;

  // --------------------------------------------------------------- bidding
  Auction? get auction;
  bool get isViewerTurnToBid;
  void submitBid(AuctionCall call);

  // --------------------------------------------------------------- playing
  Contract? get contract;
  Trick? get currentTrick;

  /// The viewer's own cards. Opponents' actual cards are never exposed here
  /// (a networked snapshot never carries them) — see [handSizeOf].
  List<PlayingCard> get myHand;
  int handSizeOf(Seat seat);
  bool isBotControlled(Seat seat);

  bool get isViewerTurnToPlay;
  List<PlayingCard> get viewerLegalPlays;
  void playCard(PlayingCard card);

  /// The most recently completed trick (before the current one), for a
  /// "peek last trick" affordance — null before any trick has finished.
  List<({Seat seat, PlayingCard card})>? get lastCompletedTrickPlayed;
  Seat? get lastCompletedTrickWinner;

  // ---------------------------------------------------------- declarations
  /// The viewer's own best declaration this hand, pre-formatted (e.g.
  /// "50") — always visible to them regardless of announce/reveal state.
  String? get myBestDeclarationLabel;
  bool get canAnnounceDeclaration;
  bool get canRevealDeclaration;
  void announceDeclaration();
  void revealDeclaration();

  DeclarationAnnounceState declarationStateOf(Seat seat);

  /// Pre-formatted label for every declaration [seat] has revealed this
  /// hand (e.g. "50 + 20"), or null if they've revealed nothing.
  String? revealedDeclarationsLabelOf(Seat seat);

  // -------------------------------------------------------- match/history
  List<HandResult> get matchHistory;
  HandResult? get lastHandResult;
  int get targetScore;
  Map<Team, int> get totals;
  Team? get matchWinner;

  // -------------------------------------------------------------- chat
  List<ChatEntry> get chatLog;
  void sendChat(String text);

  /// Acknowledges the hand summary, dealing the next hand (or ending the
  /// match if the target score has been reached).
  void continueAfterHand();
}
