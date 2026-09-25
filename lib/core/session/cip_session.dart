import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/auth_api.dart';
import 'app_settings.dart';
import 'session_providers.dart';

/// Keeps the operator's CIP session alive. CIP tokens expire, and every
/// receipt/issue is pushed to CIP with the operator's own token - so before
/// one is used it is renewed with the refresh token from login when it is
/// (nearly) expired, and again on demand when CIP turns out to have refused it
/// anyway. When even the refresh token is dead the operator is logged out
/// (the router then shows the login screen) - the only thing that helps then.
class CipSessionService {
  CipSessionService(this._ref);
  final Ref _ref;

  /// One renewal at a time: two screens asking together share the same call
  /// (a refresh token may be single-use).
  Future<String>? _inFlight;

  /// Renew this long before the expiry, so a token never dies mid-request.
  static const _skew = Duration(seconds: 60);

  /// The token to send to CIP now. [force]: renew regardless of the expiry
  /// (CIP just refused the current one). Throws [AuthFailure] with code
  /// `session_expired` once the session cannot be renewed.
  Future<String> freshToken({bool force = false}) {
    final settings = _ref.read(appSettingsProvider).value ?? const AppSettings();
    if (settings.authToken.isEmpty) {
      return Future.error(AuthFailure('session_expired', 'Sesja wygasła - zaloguj się ponownie.'));
    }
    final expiring =
        settings.authExpiresAt > 0 &&
        DateTime.now().millisecondsSinceEpoch > settings.authExpiresAt - _skew.inMilliseconds;
    if (!force && !expiring) return Future.value(settings.authToken);
    return _inFlight ??= _renew(settings).whenComplete(() => _inFlight = null);
  }

  Future<String> _renew(AppSettings settings) async {
    final notifier = _ref.read(appSettingsProvider.notifier);
    if (settings.authRefreshToken.isEmpty) {
      await notifier.logout();
      throw AuthFailure('session_expired', 'Sesja wygasła - zaloguj się ponownie.');
    }
    try {
      final session = await _ref
          .read(authApiProvider)
          .refresh(settings.authRefreshToken, fallbackUserId: settings.operatorName);
      final expiresAt = session.expiresIn == null
          ? 0
          : DateTime.now().millisecondsSinceEpoch + session.expiresIn! * 1000;
      await notifier.setSession(
        authToken: session.token,
        authRefreshToken: session.refreshToken,
        authExpiresAt: expiresAt,
        // Only when the refresh answer carried them - otherwise keep what we have.
        authorities: session.authorities.isEmpty ? null : session.authorities,
      );
      return session.token;
    } on AuthFailure catch (e) {
      // CIP refused the refresh token: this session is over. Anything else
      // (server unreachable, ...) leaves the session alone - retrying later
      // may well work.
      if (e.code == 'session_expired') await notifier.logout();
      rethrow;
    }
  }
}

final cipSessionProvider = Provider<CipSessionService>((ref) => CipSessionService(ref));
