import 'package:flutter/material.dart';

/// Wraps [child] with a tactile scale-down while a pointer is down on it.
/// Purely visual — implemented with a raw [Listener] rather than another
/// tap recognizer, so it never competes with the child's own
/// InkWell/GestureDetector for the tap gesture itself; the child keeps
/// handling the actual tap exactly as it did without this wrapper.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.96,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // translucent rather than the default deferToChild: this should
      // register presses regardless of whether the wrapped child itself
      // paints something hit-testable (e.g. a plain, colorless SizedBox
      // never would), while still letting the event reach the child too.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
