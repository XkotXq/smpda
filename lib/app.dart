import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
      home: const HomeShell(),
    );
  }
}
