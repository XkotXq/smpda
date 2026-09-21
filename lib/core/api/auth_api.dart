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
  });

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
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = res.data!;
      return AuthSession(
        token: data['token'] as String,
        refreshToken: data['refreshToken'] as String? ?? '',
        name: data['name'] as String? ?? username,
        userId: data['userId'] as String? ?? username,
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
