import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/session/session_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'theme/app_theme.dart';

/// Root widget - theme/darkTheme mirror WPS's own light/dark tokens (see
/// theme/app_theme.dart); themeMode and locale both come from
/// AppSettings (SettingsScreen's own selectors), watched here so a change
/// takes effect immediately app-wide.
class SmPdaApp extends ConsumerWidget {
  const SmPdaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    return ShadApp(
      title: 'SM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings?.themeMode ?? ThemeMode.system,
      locale: Locale(settings?.localeCode ?? 'pl'),
      supportedLocales: const [Locale('pl'), Locale('en')],
      home: const AuthGate(),
    );
  }
}

/// Shows LoginScreen until appSettingsProvider reports a CIP session
/// (AppSettings.isLoggedIn), then HomeShell - the switch is reactive, so
/// LoginScreen's own setLoggedIn call is enough to move past this without
/// any explicit navigation.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    return settingsAsync.when(
      loading: () => const Center(child: ShadProgress()),
      error: (error, _) => Center(child: Text('$error')),
      data: (settings) => settings.isLoggedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}
