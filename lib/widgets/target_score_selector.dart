import 'package:flutter/material.dart';

/// The preset "points to win" choices offered everywhere a match is set up
/// (local, online room creation, Bluetooth hosting) — alongside a custom
/// value via [showCustomTargetScoreDialog].
const List<int> kTargetScorePresets = [201, 251, 301, 351];

/// Prompts for a custom target score, pre-filled with [current] if it's
/// already a non-preset value. Returns the chosen value, or null if
/// cancelled or invalid.
Future<int?> showCustomTargetScoreDialog(
  BuildContext context, {
  required int current,
  Color backgroundColor = const Color(0xFF13543F),
  Color textColor = Colors.white,
  Color hintColor = Colors.white54,
}) async {
  final isCustom = !kTargetScorePresets.contains(current);
  final controller = TextEditingController(text: isCustom ? '$current' : '');
  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: backgroundColor,
      title: Text('Προσαρμοσμένοι πόντοι νίκης',
          style: TextStyle(color: textColor)),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
            hintText: 'π.χ. 275', hintStyle: TextStyle(color: hintColor)),
        onSubmitted: (text) =>
            Navigator.of(context).pop(int.tryParse(text.trim())),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Άκυρο')),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(int.tryParse(controller.text.trim())),
          child: const Text('Εντάξει'),
        ),
      ],
    ),
  );
  if (result == null || result < 21 || result > 5000) return null;
  return result;
}
