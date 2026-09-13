import 'package:pilotta_engine/pilotta_engine.dart';

/// The point value spoken/shown for a declaration — 20, 50, 100, 150, or
/// 200. Per the rules, players call out this number, never a "type name"
/// like "sequence of 4" or "carre of Jacks", so this (not a description of
/// what kind of combination it is) is what the UI shows everywhere a
/// declaration's value is displayed.
String declarationPointsLabel(Declaration d) => '${d.pointValue()}';

/// A hand can hold more than one declaration at once (e.g. a 4-run in one
/// suit and a separate 3-run in another) — only the single best is
/// announced out loud, but *all* of them are shown and score once
/// revealed, so this joins their point values for display, e.g. "50 + 20".
String declarationsPointsLabel(List<Declaration> declarations) =>
    declarations.map(declarationPointsLabel).join(' + ');

/// Same as [declarationPointsLabel], but for the raw JSON shape a
/// networked snapshot carries a declaration in (see `declarationToJson` in
/// pilotta_protocol) — avoids a dependency on that package from here.
String declarationPointsLabelFromJson(Map<String, dynamic> json) =>
    '${json['pointValue']}';

/// Same as [declarationsPointsLabel], but for a list of the raw JSON shape
/// (see [declarationPointsLabelFromJson]).
String declarationsPointsLabelFromJsonList(
        List<Map<String, dynamic>> declarations) =>
    declarations.map(declarationPointsLabelFromJson).join(' + ');
