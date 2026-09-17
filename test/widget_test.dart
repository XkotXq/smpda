// Smoke test: the app boots without throwing. Replace/expand this once
// there's real screen logic worth testing (e.g. SettingsScreen's save
// flow, BarcodeScannerService against a fake channel).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smpda/app.dart';
import 'package:smpda/i18n/gen/strings.g.dart';

void main() {
  testWidgets('SmPdaApp builds', (WidgetTester tester) async {
    // Mirrors main.dart's real widget tree - TranslationProvider has to
    // wrap ProviderScope here too, not just at the real entry point, or
    // any screen's `context.t` (LoginScreen included, GoRouter's initial
    // route) throws "Please wrap your app with TranslationProvider".
    await tester.pumpWidget(
      TranslationProvider(child: const ProviderScope(child: SmPdaApp())),
    );
    // A single zero-duration pump() doesn't wait out shadcn_ui's own
    // locale-loading timer (ShadLocale, triggered by ShadApp's locale/
    // supportedLocales params), which then trips flutter_test's "timer
    // still pending after dispose" check - but pumpAndSettle() never
    // returns either, since a loading state can render a continuously-
    // animating ShadProgress spinner that never lets the frame scheduler
    // go idle. A single pump with a fixed duration splits the difference:
    // long enough to flush that one timer, not an open-ended wait on an
    // animation that never stops.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
