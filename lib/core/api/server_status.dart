import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// One immediate `GET /api/health`: is wpsApi reachable right now? Any error
/// or non-2xx counts as no. Unlike [serverOnlineProvider] (polled every 15s,
/// and only while something watches it) this is for the moment an answer is
/// needed - e.g. a scan that is about to read from the server.
Future<bool> isServerReachable(Dio dio) async {
  try {
    final res = await dio.get<dynamic>(
      '/health',
      options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)),
    );
    return (res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300;
  } catch (_) {
    return false;
  }
}

/// Whether wpsApi answers `GET /api/health` right now - re-checked every 15s
/// while something watches it (the dashboard's status bar), and immediately
/// on first listen. Any error or non-2xx counts as offline.
final serverOnlineProvider = StreamProvider<bool>((ref) async* {
  final dio = ref.watch(dioProvider);
  while (true) {
    yield await isServerReachable(dio);
    await Future<void>.delayed(const Duration(seconds: 15));
  }
});
