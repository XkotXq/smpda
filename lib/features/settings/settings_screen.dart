import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/session_providers.dart';

/// Where the PDA points at wpsApi (apiBaseUrl/apiToken) - see AppSettings.
/// Nothing here is a secret worth locking behind auth of its own; it's the
/// same shared bearer token every other client (wps, stock) already uses,
/// just typed in once per device instead of baked into a build. Who's
/// logged in (operatorName) isn't editable here anymore - that's set by
/// LoginScreen from the CIP session - this screen just shows it, with a
/// way to log out.
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (settings.isLoggedIn) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Zalogowano jako: ${settings.operatorName}',
                        style: theme.textTheme.small,
                      ),
                    ),
                    ShadButton.outline(
                      onPressed: () => ref.read(appSettingsProvider.notifier).logout(),
                      child: const Text('Wyloguj'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Text('Adres wpsApi', style: theme.textTheme.small),
              const SizedBox(height: 6),
              ShadInput(
                controller: _baseUrlController,
                placeholder: const Text('http://192.168.1.50:4000'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Text('Token API', style: theme.textTheme.small),
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
                child: const Text('Zapisz'),
              ),
            ],
          ),
        );
      },
    );
  }
}
