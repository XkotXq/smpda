import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Result of a successful CIP login - mirrors wpsApi's own
/// POST /api/auth/login response shape (src/routes/auth.js).
class AuthSession {
  const AuthSession({
    required this.token,
    required this.refreshToken,
    required this.name,
    required this.userId,
    this.expiresIn,
    this.authorities = const [],
  });

  /// What CIP allows this person (wpsApi's `authorities`) - see
  /// lib/core/session/module_access.dart.
  final List<String> authorities;

  /// Seconds until [token] expires, when the server said (wpsApi's `expiresIn`).
  final int? expiresIn;

  final String token;
  final String refreshToken;

  /// Display name (wpsApi's `name` - CIP's own `user_info.employee`,
  /// falling back to whatever username was typed).
  final String name;

  /// CIP username (wpsApi's `userId`) - the employee number. This, not
  /// [name], is what gets attached to every sm_operations entry as the operator.
  final String userId;
}

/// A failed login/refresh. [code] is wpsApi's stable error code
/// (invalid_credentials, cip_unreachable, too_many_attempts, ...) - the
/// screen turns it into a message in the language the user picked, because
/// CIP's own text is Chinese. Null when the server couldn't be reached at all.
class AuthFailure implements Exception {
  AuthFailure(this.code, this.message);
  final String? code;

  /// wpsApi's Polish fallback message, for a code this app doesn't know.
  final String message;

  @override
  String toString() => message;
}

/// POST /api/auth/login - proxies the company's legacy CIP system's
/// OAuth2 password grant (see wpsApi's src/routes/auth.js). Unlike every
/// other wpsApi route, this one does *not* need the shared bearer
/// apiToken - only apiBaseUrl has to be configured for this call to reach
/// the server at all.
class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  /// Throws an [AuthFailure] - LoginScreen shows its `code` in the user's
  /// language rather than the server's text.
  Future<AuthSession> login(String username, String password) async {
    return _session('/auth/login', {'username': username, 'password': password}, username);
  }

  /// Trades a refresh token for a new token pair (wpsApi's POST
  /// /api/auth/refresh) - the same person stays logged in. Throws an
  /// [AuthFailure]; code `session_expired` means CIP refused (the refresh
  /// token itself is dead: only a fresh login helps).
  Future<AuthSession> refresh(String refreshToken, {required String fallbackUserId}) async {
    final session = await _session('/auth/refresh', {'refreshToken': refreshToken}, fallbackUserId);
    // Some servers don't rotate the refresh token - keep the one we sent.
    return session.refreshToken.isEmpty
        ? AuthSession(
            token: session.token,
            refreshToken: refreshToken,
            name: session.name,
            userId: session.userId,
            expiresIn: session.expiresIn,
            authorities: session.authorities,
          )
        : session;
  }

  Future<AuthSession> _session(String path, Map<String, dynamic> body, String fallbackUser) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = res.data!;
      return AuthSession(
        token: data['token'] as String,
        refreshToken: data['refreshToken'] as String? ?? '',
        name: data['name'] as String? ?? fallbackUser,
        userId: data['userId'] as String? ?? fallbackUser,
        expiresIn: (data['expiresIn'] as num?)?.toInt(),
        authorities: [for (final a in (data['authorities'] as List<dynamic>? ?? const [])) a.toString()],
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final serverMessage = body is Map ? body['error'] as String? : null;
      final code = body is Map ? body['code'] as String? : null;
      throw AuthFailure(code, serverMessage ?? 'Nie udało się połączyć z serwerem.');
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
