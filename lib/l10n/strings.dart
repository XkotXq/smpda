import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/session_providers.dart';

/// Locale codes SettingsScreen's language selector offers - keep in sync
/// with the keys of the map below.
const supportedLocales = ['pl', 'en'];

const Map<String, Map<String, String>> _strings = {
  'pl': {
    'login.username': 'Login',
    'login.password': 'Hasło',
    'login.submit': 'Zaloguj',
    'login.submitting': 'Logowanie...',
    'settings.loggedInAs': 'Zalogowano jako',
    'settings.logout': 'Wyloguj',
    'settings.apiUrl': 'Adres wpsApi',
    'settings.apiToken': 'Token API',
    'settings.save': 'Zapisz',
    'settings.language': 'Język',
    'settings.theme': 'Motyw',
    'settings.theme.system': 'Systemowy',
    'settings.theme.light': 'Jasny',
    'settings.theme.dark': 'Ciemny',
    'scan.noHardware':
        'Brak fizycznego skanera na tym urządzeniu - wpisz kod ręcznie, żeby zasymulować skan.',
    'scan.manualPlaceholder': 'Wpisz kod i zatwierdź',
    'scan.simulate': 'Symuluj skan',
    'scan.waitingHardware': 'Naciśnij spust skanera, aby zeskanować kod.',
    'scan.waitingManual': 'Brak zeskanowanych kodów - wpisz jeden powyżej.',
    'nav.scan': 'Skanuj',
    'nav.settings': 'Ustawienia',
  },
  'en': {
    'login.username': 'Username',
    'login.password': 'Password',
    'login.submit': 'Sign in',
    'login.submitting': 'Signing in...',
    'settings.loggedInAs': 'Signed in as',
    'settings.logout': 'Sign out',
    'settings.apiUrl': 'wpsApi address',
    'settings.apiToken': 'API token',
    'settings.save': 'Save',
    'settings.language': 'Language',
    'settings.theme': 'Theme',
    'settings.theme.system': 'System',
    'settings.theme.light': 'Light',
    'settings.theme.dark': 'Dark',
    'scan.noHardware': 'No physical scanner on this device - type a code manually to simulate a scan.',
    'scan.manualPlaceholder': 'Type a code and submit',
    'scan.simulate': 'Simulate scan',
    'scan.waitingHardware': 'Pull the scanner trigger to scan a code.',
    'scan.waitingManual': 'No scanned codes yet - type one above.',
    'nav.scan': 'Scan',
    'nav.settings': 'Settings',
  },
};

/// Current locale's string table, keyed by AppSettings.localeCode - screens
/// call `ref.watch(appStringsProvider)('some.key')`. A small hand-rolled
/// map instead of Flutter's gen-l10n/ARB tooling (no codegen/build step to
/// keep in sync) - fine at this app's current size; worth switching to
/// proper ARB files if the string count grows much further, same tradeoff
/// wps itself would face choosing next-intl over a flatter approach.
final appStringsProvider = Provider<String Function(String key)>((ref) {
  final locale = ref.watch(appSettingsProvider).value?.localeCode ?? 'pl';
  final table = _strings[locale] ?? _strings['pl']!;
  return (key) => table[key] ?? key;
});
