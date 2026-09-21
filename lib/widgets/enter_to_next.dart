import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// Wraps a text field so the PDA keypad's Enter key moves on to the next
/// field (or, on the last one, runs [onLast] - by default just leaves the
/// field). Enter is handled here, before it can reach the keyboard/IME, so a
/// field without an on-screen keyboard (see numericKeyboardType) reacts to it
/// the same as one with, and it never advances twice.
class EnterToNext extends StatelessWidget {
  const EnterToNext({super.key, required this.child, this.isLast = false, this.onLast});

  final Widget child;

  /// The last field of the form: Enter does [onLast] (or just drops focus)
  /// instead of moving to whatever follows.
  final bool isLast;
  final VoidCallback? onLast;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey != LogicalKeyboardKey.enter && event.logicalKey != LogicalKeyboardKey.numpadEnter) {
          return KeyEventResult.ignored;
        }
        if (event is KeyDownEvent) {
          if (!isLast) {
            FocusScope.of(context).nextFocus();
          } else if (onLast != null) {
            onLast!();
          } else {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        }
        // Key-up / repeat are swallowed too, so nothing else reacts to Enter.
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}
