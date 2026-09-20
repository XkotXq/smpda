import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Whether wpsApi answers `GET /api/health` right now - re-checked every 15s
/// while something watches it (the dashboard's status bar), and immediately
/// on first listen. Any error or non-2xx counts as offline.
final serverOnlineProvider = StreamProvider<bool>((ref) async* {
  final dio = ref.watch(dioProvider);
  while (true) {
    try {
      final res = await dio.get<dynamic>(
        '/health',
        options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)),
      );
      yield (res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300;
    } catch (_) {
      yield false;
    }
    await Future<void>.delayed(const Duration(seconds: 15));
  }
});
