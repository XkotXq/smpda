import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/session/session_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'theme/app_theme.dart';

/// Root widget - theme/darkTheme mirror WPS's own light/dark tokens (see
/// theme/app_theme.dart); themeMode follows the system setting, same
/// default WPS's own ThemeProvider uses.
class SmPdaApp extends StatelessWidget {
  const SmPdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'SmPda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
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
