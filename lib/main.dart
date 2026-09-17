import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'i18n/gen/strings.g.dart';

void main() {
  // TranslationProvider wraps everything so `context.t.someKey` works
  // anywhere and rebuilds on locale change (see app.dart, which bridges
  // AppSettings.localeCode - the persisted setting SettingsScreen edits -
  // into LocaleSettings.setLocale).
  runApp(TranslationProvider(child: const ProviderScope(child: SmPdaApp())));
}
