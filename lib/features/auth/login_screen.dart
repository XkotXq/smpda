import 'package:flutter/material.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/auth_api.dart';
import '../../core/session/session_providers.dart';
import '../../i18n/gen/strings.g.dart';
import '../../router.dart';
import '../../widgets/enter_to_next.dart';
import '../../widgets/field_scroll_padding.dart';

/// First screen the app shows - GoRouter's own `redirect` (router.dart)
/// sends here whenever AppSettings.isLoggedIn is false, and away from
/// here once it's true, so nothing on this screen needs to navigate on
/// login success itself. Just the CIP login/password wps and stock
/// already use, proxied through wpsApi's POST /api/auth/login (see
/// AuthApi) - nothing else on this screen by design; the gear icon in the
/// corner is the only way to reach the apiBaseUrl/apiToken settings a
/// fresh install needs before this call can even reach a server.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  /// The eye at the end of the password field - shows the typed password
  /// instead of dots, for checking a typo on the small PDA keypad.
  bool _showPassword = false;
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
      await ref
          .read(appSettingsProvider.notifier)
          .setLoggedIn(
            authToken: session.token,
            authRefreshToken: session.refreshToken,
            operatorName: session.userId,
            authorities: session.authorities,
            authExpiresAt: session.expiresIn == null
                ? 0
                : DateTime.now().millisecondsSinceEpoch + session.expiresIn! * 1000,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// The error in the selected language: wpsApi sends a code, CIP's own text
  /// is Chinese and never shown. No code (server unreachable) or one this app
  /// doesn't know -> the generic "can't reach the server" / the server's text.
  String _messageFor(Object error) {
    final t = context.t.login.errors;
    if (error is AuthFailure) {
      return switch (error.code) {
        'invalid_credentials' => t.invalidCredentials,
        'cip_unreachable' => t.cipUnreachable,
        'too_many_attempts' => t.tooManyAttempts,
        null => t.serverUnreachable,
        _ => error.message,
      };
    }
    return t.serverUnreachable;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    return Stack(
      children: [
        // Scrollable (centered while it fits): with the on-screen keyboard up
        // the fields and the button no longer fit, so they scroll instead of
        // being cut off.
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
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
                        EnterToNext(
                          child: ShadInput(
                            scrollPadding: kFieldScrollPadding,
                            controller: _usernameController,
                            placeholder: Text(t.login.username),
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(height: 12),
                        EnterToNext(
                          isLast: true,
                          onLast: _submit,
                          child: ShadInput(
                            scrollPadding: kFieldScrollPadding,
                            controller: _passwordController,
                            placeholder: Text(t.login.password),
                            obscureText: !_showPassword,
                            // Tap only (ExcludeFocus): the eye must not take keyboard
                            // focus away from the field or draw a focus ring on the PDA.
                            trailing: ExcludeFocus(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() => _showPassword = !_showPassword),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  child: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
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
                          child: Text(_submitting ? t.login.submitting : t.login.submit),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: ShadButton.ghost(onPressed: () => context.push(settingsPath), child: const Icon(LucideIcons.settings)),
        ),
      ],
    );
  }
}
