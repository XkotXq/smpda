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
  });

  final String token;
  final String refreshToken;

  /// Display name (wpsApi's `name` - CIP's own `user_info.employee`,
  /// falling back to whatever username was typed) - this is what gets
  /// attached to every sm_operations entry as the operator.
  final String name;
}

/// POST /api/auth/login - proxies the company's legacy CIP system's
/// OAuth2 password grant (see wpsApi's src/routes/auth.js). Unlike every
/// other wpsApi route, this one does *not* need the shared bearer
/// apiToken - only apiBaseUrl has to be configured for this call to reach
/// the server at all.
class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  /// Throws a [String] error message (already the server's own Polish
  /// wording, e.g. "Nieprawidłowy login lub hasło") on a 401 - LoginScreen
  /// shows it as-is rather than wrapping it in something generic.
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
      );
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw serverMessage ?? 'Nie udało się połączyć z serwerem.';
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
