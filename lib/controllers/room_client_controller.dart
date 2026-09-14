import 'package:flutter/foundation.dart';
import 'package:pilotta_engine/pilotta_engine.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';

import '../widgets/declaration_label.dart';
import '../widgets/table/game_table_data.dart';

enum ConnectionStatus { connecting, connected, disconnected }

/// The client side of the room protocol, transport-agnostic: everything a
/// UI needs to render a networked match and act on it, whether the bytes
/// underneath travel over a WebSocket ([OnlineGameController]) or a Nearby
/// Connections link to a host device on the same phone-to-phone network
/// ([BluetoothGameController]).
///
/// Holds no game logic of its own — the remote [PilottaRoom] (on a server,
/// or on the host device) is authoritative. The one exception is bidding:
/// [auction] is rebuilt locally by replaying the snapshot's public call
/// log, purely so [BiddingPanel] can be reused unmodified without the
/// transport needing to serialize anything auction-specific.
abstract class RoomClientController extends ChangeNotifier
    implements GameTableData {
  ConnectionStatus status = ConnectionStatus.connecting;
  String? roomCode;
  Seat? mySeat;
  RoomSnapshotMessage? snapshot;
  String? lastError;

  /// The name this player joined/created the room with — kept around
  /// purely so a UI can offer to reconnect with the same identity after a
  /// dropped connection (rejoining with the same name reclaims your seat,
  /// see [PilottaRoom.join]).
  String? playerName;

  /// Sends [message] to whoever is authoritative (server or host device).
  @protected
  void sendMessage(ClientMessage message);

  /// Subclasses call this with every decoded [ServerMessage] as it arrives.
  @protected
  void handleServerMessage(ServerMessage message) {
    switch (message) {
      case WelcomeMessage():
        roomCode = message.roomCode;
        mySeat = message.yourSeat;
        lastError = null;
      case RoomSnapshotMessage():
        snapshot = message;
        lastError = null;
      case ServerErrorMessage():
        lastError = message.message;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- actions

  void createRoom({
    required String playerName,
    required int targetScore,
    bool mustOvertrumpAllSuits = false,
  }) {
    this.playerName = playerName;
    sendMessage(CreateRoomMessage(
      playerName: playerName,
      targetScore: targetScore,
      mustOvertrumpAllSuits: mustOvertrumpAllSuits,
    ));
  }

  void joinRoom({required String roomCode, required String playerName}) {
    this.playerName = playerName;
    sendMessage(JoinRoomMessage(roomCode: roomCode, playerName: playerName));
  }

  void start() => sendMessage(const StartMessage());

  @override
  void submitBid(AuctionCall call) => sendMessage(BidMessage(call));

  @override
  void playCard(PlayingCard card) => sendMessage(PlayCardMessage(card));

  /// Announces this player's best declaration (only valid during trick 1).
  @override
  void announceDeclaration() => sendMessage(const AnnounceDeclarationMessage());

  /// Reveals a previously-announced declaration (must happen before this
  /// player's trick-2 card).
  @override
  void revealDeclaration() => sendMessage(const RevealDeclarationMessage());

  @override
  void continueAfterHand() => sendMessage(const ReadyForNextHandMessage());

  @override
  bool get viewerIsReadyForNextHand =>
      snapshot?.readyForNextHand.contains(mySeat) ?? false;

  /// Sends a free-text chat message, visible to every seat.
  @override
  void sendChat(String text) => sendMessage(SendChatMessage(text));

  void leaveRoom() => sendMessage(const LeaveMessage());

  // ------------------------------------------------------------ derived

  bool get inRoom => mySeat != null && snapshot != null;

  /// The room's shared chat/event log — player messages interleaved with
  /// declaration and Pilotta/Repilotta announcements, oldest first.
  @override
  List<ChatEntry> get chatLog => snapshot?.chatLog ?? const [];

  bool get isHost => mySeat == Seat.south;

  @override
  Auction? get auction {
    final calls = snapshot?.auctionCalls;
    if (calls == null) return null;
    final decoded = calls.map(auctionCallFromJson).toList();
    final startingSeat = decoded.isNotEmpty
        ? decoded.first.seat
        : (snapshot!.seatToAct ?? Seat.south);
    final rebuilt = Auction(startingSeat);
    for (final call in decoded) {
      rebuilt.apply(call);
    }
    return rebuilt;
  }

  bool get isMyTurnToBid =>
      snapshot?.phase == RoomPhase.bidding && snapshot?.seatToAct == mySeat;

  bool get isMyTurnToPlay =>
      snapshot?.phase == RoomPhase.playing && snapshot?.seatToAct == mySeat;

  /// Reconstructs the current trick as a real [Trick] from the snapshot's
  /// public state (leader, trump suit, cards played so far, house-rule
  /// flag). Legality only ever depends on this plus the viewer's own hand
  /// — never on other players' hidden cards — so this is exact, not a
  /// heuristic guess at what the server would accept.
  @override
  Trick? get currentTrick {
    final snap = snapshot;
    final contract = snap?.contract;
    final leader = snap?.trickLeader;
    if (snap == null || contract == null || leader == null) return null;
    final trick = Trick(
      leader: leader,
      trumpSuit: Suit.values.byName(contract['trumpSuit'] as String),
      mustOvertrumpAllSuits: snap.mustOvertrumpAllSuits,
    );
    for (final entry in snap.currentTrick ?? const <Map<String, dynamic>>[]) {
      trick.play(
        Seat.values.byName(entry['seat'] as String),
        cardFromJson(entry['card'] as Map<String, dynamic>),
      );
    }
    return trick;
  }

  /// The cards [mySeat] may legally play right now, computed client-side
  /// from [currentTrick] + the viewer's own hand (see [currentTrick]).
  List<PlayingCard> get legalPlaysForMe {
    final trick = currentTrick;
    final snap = snapshot;
    if (trick == null || snap == null) return const [];
    // A just-finished trick stays on the table for a few seconds (see
    // PilottaRoom.trickCollectDelay) before the server starts the next one
    // — nobody may play into it meanwhile.
    if (trick.isComplete) return const [];
    return trick.legalPlays(snap.yourHand);
  }

  // ------------------------------------------------------- GameTableData
  // Additive adapter members satisfying the shared table-widget interface
  // (see game_table_data.dart) — decoded from the JSON snapshot on access,
  // same approach as [auction]/[currentTrick] above. Only meaningful once
  // [inRoom] is true, same precondition every other member here already
  // has (a table-widget consumer is never built before then).

  @override
  RoomPhase get phase => snapshot!.phase;

  @override
  Seat get viewerSeat => mySeat!;

  @override
  String? get banner => snapshot?.banner;

  @override
  bool get isViewerTurnToBid => isMyTurnToBid;

  @override
  Seat? get seatToAct => snapshot?.seatToAct;

  @override
  Contract? get contract {
    final json = snapshot?.contract;
    return json == null ? null : contractFromJson(json);
  }

  @override
  List<PlayingCard> get myHand => snapshot?.yourHand ?? const [];

  @override
  int handSizeOf(Seat seat) =>
      seat == mySeat ? myHand.length : (snapshot?.handSizes[seat] ?? 0);

  @override
  bool isBotControlled(Seat seat) => snapshot?.seats[seat]?.isBot ?? false;

  @override
  bool get isViewerTurnToPlay => isMyTurnToPlay;

  @override
  List<PlayingCard> get viewerLegalPlays => legalPlaysForMe;

  @override
  List<({Seat seat, PlayingCard card})>? get lastCompletedTrickPlayed {
    final played = snapshot?.lastCompletedTrick;
    if (played == null) return null;
    return [
      for (final e in played)
        (
          seat: Seat.values.byName(e['seat'] as String),
          card: cardFromJson(e['card'] as Map<String, dynamic>),
        ),
    ];
  }

  @override
  Seat? get lastCompletedTrickWinner => snapshot?.lastCompletedTrickWinner;

  @override
  String? get myBestDeclarationLabel {
    final json = snapshot?.yourBestDeclaration;
    return json == null ? null : declarationPointsLabelFromJson(json);
  }

  @override
  bool get canAnnounceDeclaration => snapshot?.canAnnounceDeclaration ?? false;

  @override
  bool get canRevealDeclaration => snapshot?.canRevealDeclaration ?? false;

  @override
  DeclarationAnnounceState declarationStateOf(Seat seat) {
    final name = snapshot?.declarationStates[seat];
    return name == null
        ? DeclarationAnnounceState.none
        : DeclarationAnnounceState.values.byName(name);
  }

  @override
  String? revealedDeclarationsLabelOf(Seat seat) {
    final declarations = snapshot?.revealedDeclarations[seat];
    if (declarations == null || declarations.isEmpty) return null;
    return declarationsPointsLabelFromJsonList(declarations);
  }

  @override
  List<HandResult> get matchHistory =>
      snapshot?.matchHistory.map(handResultFromJson).toList() ?? const [];

  @override
  HandResult? get lastHandResult {
    final json = snapshot?.lastHandResult;
    return json == null ? null : handResultFromJson(json);
  }

  @override
  int get targetScore => snapshot?.targetScore ?? 0;

  @override
  Map<Team, int> get totals => {
        for (final e in (snapshot?.totals ?? const <String, int>{}).entries)
          Team.values.byName(e.key): e.value,
      };

  @override
  Team? get matchWinner {
    final name = snapshot?.winnerTeam;
    return name == null ? null : Team.values.byName(name);
  }
}
