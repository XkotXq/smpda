import 'package:flutter/widgets.dart';

/// scrollPadding for every text field: when a field gets focus (and the
/// on-screen keyboard slides up) its scroll view keeps this much room around
/// the caret, so the field being typed in ends up clearly above the keyboard
/// instead of touching its edge - the bottom margin is the generous one.
const kFieldScrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 120);
