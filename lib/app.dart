import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/session/session_providers.dart';
import 'i18n/gen/strings.g.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget - theme/darkTheme mirror WPS's own light/dark tokens (see
/// theme/app_theme.dart); themeMode and locale both come from
/// AppSettings (SettingsScreen's own selectors), watched here so a change
/// takes effect immediately app-wide. Navigation goes through GoRouter
/// (see router.dart) - its own `redirect` handles the login/dashboard
/// switch that used to live here as AuthGate.
class SmPdaApp extends ConsumerWidget {
  const SmPdaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    final locale = settings?.localeCode == 'en' ? AppLocale.en : AppLocale.pl;
    // Bridges AppSettings.localeCode (persisted, riverpod-managed) into
    // slang's own LocaleSettings singleton - a plain equality check keeps
    // this idempotent, since build() re-running on every unrelated
    // settings change would otherwise call setLocale needlessly.
    if (LocaleSettings.currentLocale != locale) {
      LocaleSettings.setLocale(locale);
    }
    return ShadApp.router(
      title: 'SM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings?.themeMode ?? ThemeMode.system,
      locale: locale.flutterLocale,
      supportedLocales: AppLocale.values.map((l) => l.flutterLocale),
      routerConfig: ref.watch(routerProvider),
      // The app has no Scaffold to make room for the on-screen keyboard, so do it
      // here for every screen: the content ends where the keyboard begins (the
      // field being typed in scrolls into that smaller area instead of sitting
      // behind the keyboard). The inset is then consumed so nothing pads twice.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.removeViewInsets(removeBottom: true),
          child: Padding(padding: EdgeInsets.only(bottom: media.viewInsets.bottom), child: child),
        );
      },
    );
  }
}
