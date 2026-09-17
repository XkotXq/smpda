import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/session_providers.dart';

/// Where the PDA points at wpsApi and who's holding it - see AppSettings.
/// Nothing here is a secret worth locking behind auth of its own; it's the
/// same shared bearer token every other client (wps, stock) already uses,
/// just typed in once per device instead of baked into a build.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _operatorController = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    _operatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: ShadProgress()),
      error: (error, _) => Center(child: Text('$error')),
      data: (settings) {
        if (!_hydrated) {
          _baseUrlController.text = settings.apiBaseUrl;
          _tokenController.text = settings.apiToken;
          _operatorController.text = settings.operatorName;
          _hydrated = true;
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Adres wpsApi', style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 6),
              ShadInput(
                controller: _baseUrlController,
                placeholder: const Text('http://192.168.1.50:4000'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Text('Token API', style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 6),
              ShadInput(controller: _tokenController, obscureText: true),
              const SizedBox(height: 16),
              Text('Operator', style: ShadTheme.of(context).textTheme.small),
              const SizedBox(height: 6),
              ShadInput(controller: _operatorController),
              const SizedBox(height: 24),
              ShadButton(
                child: const Text('Zapisz'),
                onPressed: () {
                  ref.read(appSettingsProvider.notifier).save(
                        apiBaseUrl: _baseUrlController.text.trim(),
                        apiToken: _tokenController.text.trim(),
                        operatorName: _operatorController.text.trim(),
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
