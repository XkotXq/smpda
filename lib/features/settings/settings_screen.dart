import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/session_providers.dart';
import '../../i18n/gen/strings.g.dart';

/// Where the PDA points at wpsApi (apiBaseUrl/apiToken) plus this device's
/// own display prefs (language/theme) - see AppSettings. Nothing here is a
/// secret worth locking behind auth of its own; the bearer token is the
/// same one every other client (wps, stock) already uses, just typed in
/// once per device instead of baked into a build. Who's logged in
/// (operatorName) isn't editable here - that's set by LoginScreen from the
/// CIP session - this screen just shows it, with a way to log out.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: ShadProgress()),
      error: (error, _) => Center(child: Text('$error')),
      data: (settings) {
        if (!_hydrated) {
          _baseUrlController.text = settings.apiBaseUrl;
          _tokenController.text = settings.apiToken;
          _hydrated = true;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (settings.isLoggedIn) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${t.settings.loggedInAs}: ${settings.operatorName}',
                        style: theme.textTheme.small,
                      ),
                    ),
                    ShadButton.outline(
                      onPressed: () => ref.read(appSettingsProvider.notifier).logout(),
                      child: Text(t.settings.logout),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Text(t.settings.language, style: theme.textTheme.small),
              const SizedBox(height: 6),
              ShadSelect<String>(
                initialValue: settings.localeCode,
                placeholder: Text(t.settings.language),
                options: const [
                  ShadOption(value: 'pl', child: Text('Polski')),
                  ShadOption(value: 'en', child: Text('English')),
                ],
                selectedOptionBuilder: (context, value) =>
                    Text(value == 'pl' ? 'Polski' : 'English'),
                onChanged: (value) {
                  if (value != null) ref.read(appSettingsProvider.notifier).setLocale(value);
                },
              ),
              const SizedBox(height: 16),
              Text(t.settings.theme.label, style: theme.textTheme.small),
              const SizedBox(height: 6),
              ShadSelect<ThemeMode>(
                initialValue: settings.themeMode,
                placeholder: Text(t.settings.theme.label),
                options: [
                  ShadOption(value: ThemeMode.system, child: Text(t.settings.theme.system)),
                  ShadOption(value: ThemeMode.light, child: Text(t.settings.theme.light)),
                  ShadOption(value: ThemeMode.dark, child: Text(t.settings.theme.dark)),
                ],
                selectedOptionBuilder: (context, value) => Text(switch (value) {
                  ThemeMode.system => t.settings.theme.system,
                  ThemeMode.light => t.settings.theme.light,
                  ThemeMode.dark => t.settings.theme.dark,
                }),
                onChanged: (value) {
                  if (value != null) ref.read(appSettingsProvider.notifier).setThemeMode(value);
                },
              ),
              const SizedBox(height: 16),
              Text(t.settings.apiUrl, style: theme.textTheme.small),
              const SizedBox(height: 6),
              ShadInput(
                controller: _baseUrlController,
                placeholder: const Text('http://192.168.1.50:4000'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Text(t.settings.apiToken, style: theme.textTheme.small),
              const SizedBox(height: 6),
              ShadInput(controller: _tokenController, obscureText: true),
              const SizedBox(height: 24),
              ShadButton(
                onPressed: () {
                  ref.read(appSettingsProvider.notifier).save(
                        apiBaseUrl: _baseUrlController.text.trim(),
                        apiToken: _tokenController.text.trim(),
                      );
                },
                child: Text(t.settings.save),
              ),
            ],
          ),
        );
      },
    );
  }
}
