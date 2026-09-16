/// Everything the PDA needs to talk to wpsApi and log operations under a
/// name - same three pieces of config wps itself needs (API_TOKEN,
/// API_BASE_URL) plus the operator field wps's own ReceiveUnitPanel/
/// BulkIssuePanel already attach to every sm_operations entry. Kept
/// together (not three separate providers) since they're always read/
/// edited as a unit (one "ustawienia" screen).
class AppSettings {
  const AppSettings({
    this.apiBaseUrl = '',
    this.apiToken = '',
    this.operatorName = '',
  });

  /// e.g. http://192.168.1.50:4000 - the PDA is on the same warehouse
  /// Wi-Fi as the machine running wpsApi, not localhost (see the Android
  /// emulator vs real-device note in AppSettingsNotifier).
  final String apiBaseUrl;

  /// Shared bearer token - must match wpsApi's own API_TOKEN, same as
  /// wps's/stock's own NEXT_PUBLIC_API_TOKEN (see wpsApi's AGENTS.md).
  final String apiToken;

  final String operatorName;

  bool get isConfigured => apiBaseUrl.isNotEmpty && apiToken.isNotEmpty;

  AppSettings copyWith({
    String? apiBaseUrl,
    String? apiToken,
    String? operatorName,
  }) {
    return AppSettings(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiToken: apiToken ?? this.apiToken,
      operatorName: operatorName ?? this.operatorName,
    );
  }
}
