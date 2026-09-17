import 'package:flutter/material.dart' show MaterialPageRoute, TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/auth_api.dart';
import '../../core/session/session_providers.dart';
import '../../l10n/strings.dart';
import '../settings/settings_screen.dart';

/// First screen the app shows (see AuthGate in app.dart) - just the CIP
/// login/password wps and stock already use, proxied through wpsApi's
/// POST /api/auth/login (see AuthApi). Nothing else on this screen by
/// design; the gear icon in the corner is the only way to reach the
/// apiBaseUrl/apiToken settings a fresh install needs before this call
/// can even reach a server.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = await ref.read(authApiProvider).login(username, password);
      await ref.read(appSettingsProvider.notifier).setLoggedIn(
            authToken: session.token,
            authRefreshToken: session.refreshToken,
            operatorName: session.name,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = ref.watch(appStringsProvider);
    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SM', style: theme.textTheme.h3, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ShadInput(
                    controller: _usernameController,
                    placeholder: Text(t('login.username')),
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  ShadInput(
                    controller: _passwordController,
                    placeholder: Text(t('login.password')),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.small.copyWith(color: theme.colorScheme.destructive),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ShadButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? t('login.submitting') : t('login.submit')),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: ShadButton.ghost(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: const Icon(LucideIcons.settings),
          ),
        ),
      ],
    );
  }
}
