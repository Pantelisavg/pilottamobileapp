import 'package:pilotta_engine/pilotta_engine.dart';

/// A short Greek label for a declaration, e.g. "Καρέ J" or "Σκάλα 4".
String declarationLabel(Declaration d) {
  if (d.kind == DeclarationKind.carre) {
    return 'Καρέ ${d.carreRank.short}';
  }
  return 'Σκάλα ${d.length}';
}

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
