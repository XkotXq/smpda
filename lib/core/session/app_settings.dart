/// Everything the PDA needs to talk to wpsApi and log operations under a
/// name - same pieces of config wps itself needs (API_TOKEN, API_BASE_URL)
/// plus the CIP session (see AuthApi) that identifies who's holding the
/// device right now. Kept together (not several separate providers) since
/// they're always read/edited as a unit.
class AppSettings {
  const AppSettings({
    this.apiBaseUrl = '',
    this.apiToken = '',
    this.operatorName = '',
    this.authToken = '',
    this.authRefreshToken = '',
  });

  /// e.g. http://192.168.1.50:4000 - the PDA is on the same warehouse
  /// Wi-Fi as the machine running wpsApi, not localhost (see the Android
  /// emulator vs real-device note in AppSettingsNotifier).
  final String apiBaseUrl;

  /// Shared bearer token - must match wpsApi's own API_TOKEN, same as
  /// wps's/stock's own NEXT_PUBLIC_API_TOKEN (see wpsApi's AGENTS.md).
  /// Authenticates every wpsApi route *except* /api/auth/* - unrelated to
  /// [authToken] below, which is that one operator's own CIP session.
  final String apiToken;

  /// The logged-in CIP user's display name (wpsApi's own `name` field,
  /// from the old app's `user_info.employee`) - attached to every
  /// sm_operations entry this device logs, same as wps's own `operator`.
  final String operatorName;

  /// CIP OAuth2 access/refresh token pair from POST /api/auth/login (see
  /// AuthApi) - presence of [authToken] is what LoginScreen/AuthGate use
  /// to decide whether to show the login screen or the app itself.
  final String authToken;
  final String authRefreshToken;

  bool get isConfigured => apiBaseUrl.isNotEmpty && apiToken.isNotEmpty;
  bool get isLoggedIn => authToken.isNotEmpty;

  AppSettings copyWith({
    String? apiBaseUrl,
    String? apiToken,
    String? operatorName,
    String? authToken,
    String? authRefreshToken,
  }) {
    return AppSettings(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiToken: apiToken ?? this.apiToken,
      operatorName: operatorName ?? this.operatorName,
      authToken: authToken ?? this.authToken,
      authRefreshToken: authRefreshToken ?? this.authRefreshToken,
    );
  }

  /// Drops the CIP session only - apiBaseUrl/apiToken (this device's own
  /// wpsApi config) stay put, since those aren't tied to who's logged in.
  AppSettings loggedOut() => copyWith(authToken: '', authRefreshToken: '', operatorName: '');
}
