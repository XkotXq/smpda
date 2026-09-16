import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

const _kApiBaseUrlKey = 'smpda.apiBaseUrl';
const _kApiTokenKey = 'smpda.apiToken';
const _kOperatorNameKey = 'smpda.operatorName';

/// Loads [AppSettings] from SharedPreferences on startup and persists every
/// change back to it - the PDA stays configured/logged in across restarts
/// for a whole shift, same "just keep whoever's holding it" session model
/// wps itself uses for its own `operator` field.
class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      apiBaseUrl: prefs.getString(_kApiBaseUrlKey) ?? '',
      apiToken: prefs.getString(_kApiTokenKey) ?? '',
      operatorName: prefs.getString(_kOperatorNameKey) ?? '',
    );
  }

  Future<void> update({
    String? apiBaseUrl,
    String? apiToken,
    String? operatorName,
  }) async {
    final current = state.valueOrNull ?? const AppSettings();
    final next = current.copyWith(
      apiBaseUrl: apiBaseUrl,
      apiToken: apiToken,
      operatorName: operatorName,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiBaseUrlKey, next.apiBaseUrl);
    await prefs.setString(_kApiTokenKey, next.apiToken);
    await prefs.setString(_kOperatorNameKey, next.operatorName);
    state = AsyncData(next);
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
