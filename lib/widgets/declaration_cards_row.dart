import 'package:flutter/material.dart';
import 'package:pilotta_protocol/pilotta_protocol.dart';
import 'package:provider/provider.dart';

import '../settings/app_settings.dart';
import 'playing_card_widget.dart';

/// The actual cards behind one or more revealed declarations, as small
/// face-up cards — grouped per declaration (a hand can hold more than
/// one), wrapping to a new line if there isn't room for all of them.
class DeclarationCardsRow extends StatelessWidget {
  final List<Map<String, dynamic>> declarations;
  final double cardWidth;

  const DeclarationCardsRow({
    super.key,
    required this.declarations,
    this.cardWidth = 32,
  });

  @override
  Widget build(BuildContext context) {
    final deckStyle = context.watch<AppSettings>().deckStyle;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final declaration in declarations)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final cardJson in (declaration['cards'] as List)
                  .cast<Map<String, dynamic>>())
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: PlayingCardWidget(
                      card: cardFromJson(cardJson),
                      width: cardWidth,
                      style: deckStyle),
                ),
            ],
          ),
      ],
    );
  }
}
