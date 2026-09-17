import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'section_header.dart';

/// SectionHeader + a plain body - for a pushed section with no bottom nav
/// of its own (e.g. FrpScreen). HomeShell builds its own header+body+bottom-
/// bar layout directly instead of using this, since it needs the extra row.
class SectionScaffold extends StatelessWidget {
  const SectionScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.background,
      child: Column(
        children: [
          SectionHeader(title: title),
          Expanded(child: body),
        ],
      ),
    );
  }
}
