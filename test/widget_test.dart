// Smoke test: the app boots without throwing. Replace/expand this once
// there's real screen logic worth testing (e.g. SettingsScreen's save
// flow, BarcodeScannerService against a fake channel).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smpda/app.dart';

void main() {
  testWidgets('SmPdaApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmPdaApp()));
    await tester.pump();
  });
}
