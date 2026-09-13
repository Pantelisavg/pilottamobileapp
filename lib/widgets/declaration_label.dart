import 'package:pilotta_engine/pilotta_engine.dart';

/// A short Greek label for a declaration, e.g. "Καρέ J" or "Σκάλα 4".
String declarationLabel(Declaration d) {
  if (d.kind == DeclarationKind.carre) {
    return 'Καρέ ${d.carreRank.short}';
  }
  return 'Σκάλα ${d.length}';
}

/// A hand can hold more than one declaration at once (e.g. a 4-run in one
/// suit and a separate 3-run in another) — only the single best is
/// announced out loud, but *all* of them are shown and score once
/// revealed, so this joins their labels for display, e.g. "Σκάλα 4 + Σκάλα 3".
String declarationsLabel(List<Declaration> declarations) =>
    declarations.map(declarationLabel).join(' + ');

/// Same as [declarationLabel], but for the raw JSON shape a networked
/// snapshot carries a declaration in (see `declarationToJson` in
/// pilotta_protocol) — avoids a dependency on that package from here.
String declarationLabelFromJson(Map<String, dynamic> json) {
  final cards = (json['cards'] as List).cast<Map<String, dynamic>>();
  if (json['kind'] == 'carre') {
    return 'Καρέ ${Rank.values.byName(cards.first['rank'] as String).short}';
  }
  return 'Σκάλα ${cards.length}';
}

/// Same as [declarationsLabel], but for a list of the raw JSON shape (see
/// [declarationLabelFromJson]).
String declarationsLabelFromJsonList(List<Map<String, dynamic>> declarations) =>
    declarations.map(declarationLabelFromJson).join(' + ');
