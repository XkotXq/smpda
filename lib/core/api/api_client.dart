import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_providers.dart';

/// One shared Dio instance for every wpsApi call - an interceptor reads the
/// current base URL + bearer token from [appSettingsProvider] on every
/// request (rather than baking them into a fixed BaseOptions at provider-
/// creation time) so changing them in the settings screen takes effect
/// immediately, no app restart or provider rebuild needed. Mirrors wps's
/// own lib/smItemsApi.js `apiFetch`: `${apiBaseUrl}/api${path}` +
/// `Authorization: Bearer ${apiToken}`.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final settings = ref.read(appSettingsProvider).value;
        options.baseUrl = '${settings?.apiBaseUrl ?? ''}/api';
        final token = settings?.apiToken ?? '';
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});
