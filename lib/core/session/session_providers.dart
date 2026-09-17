import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

const _kApiBaseUrlKey = 'smpda.apiBaseUrl';
const _kApiTokenKey = 'smpda.apiToken';
const _kOperatorNameKey = 'smpda.operatorName';
const _kAuthTokenKey = 'smpda.authToken';
const _kAuthRefreshTokenKey = 'smpda.authRefreshToken';
const _kThemeModeKey = 'smpda.themeMode';
const _kLocaleCodeKey = 'smpda.localeCode';

ThemeMode _themeModeFromString(String? value) {
  return ThemeMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => ThemeMode.system,
  );
}

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
      authToken: prefs.getString(_kAuthTokenKey) ?? '',
      authRefreshToken: prefs.getString(_kAuthRefreshTokenKey) ?? '',
      themeMode: _themeModeFromString(prefs.getString(_kThemeModeKey)),
      localeCode: prefs.getString(_kLocaleCodeKey) ?? 'pl',
    );
  }

  Future<void> _persist(AppSettings next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiBaseUrlKey, next.apiBaseUrl);
    await prefs.setString(_kApiTokenKey, next.apiToken);
    await prefs.setString(_kOperatorNameKey, next.operatorName);
    await prefs.setString(_kAuthTokenKey, next.authToken);
    await prefs.setString(_kAuthRefreshTokenKey, next.authRefreshToken);
    await prefs.setString(_kThemeModeKey, next.themeMode.name);
    await prefs.setString(_kLocaleCodeKey, next.localeCode);
    state = AsyncData(next);
  }

  // Named `save`, not `update` - AsyncNotifier already declares its own
  // `update(cb)` (recompute state from a callback over the current value),
  // so reusing that name here would clash with the inherited signature.
  Future<void> save({
    String? apiBaseUrl,
    String? apiToken,
    String? operatorName,
  }) async {
    final current = state.value ?? const AppSettings();
    await _persist(current.copyWith(
      apiBaseUrl: apiBaseUrl,
      apiToken: apiToken,
      operatorName: operatorName,
    ));
  }

  /// Called after AuthApi.login succeeds - see LoginScreen.
  Future<void> setLoggedIn({
    required String authToken,
    required String authRefreshToken,
    required String operatorName,
  }) async {
    final current = state.value ?? const AppSettings();
    await _persist(current.copyWith(
      authToken: authToken,
      authRefreshToken: authRefreshToken,
      operatorName: operatorName,
    ));
  }

  Future<void> logout() async {
    final current = state.value ?? const AppSettings();
    await _persist(current.loggedOut());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.value ?? const AppSettings();
    await _persist(current.copyWith(themeMode: mode));
  }

  Future<void> setLocale(String localeCode) async {
    final current = state.value ?? const AppSettings();
    await _persist(current.copyWith(localeCode: localeCode));
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
