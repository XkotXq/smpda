# SM

Flutter app for Honeywell Android PDAs (scan-and-receive/issue on the
warehouse floor), talking to the same `wpsApi` backend as the `WPS`
dashboard - specifically the Materiały SM endpoints (`sm-items`,
`sm-operations`, `sm-catalog`) plus the same CIP login (`/api/auth/login`)
wps/stock already use. See `../wpsApi/AGENTS.md` and `../WPS/AGENTS.md`'s
"Materiały SM" section for the data model this app builds on. Flutter
package/applicationId stay `smpda` (see "Brand the app as SM" commit) -
only the user-visible name changed.

## Stack

- **UI**: [shadcn_ui](https://pub.dev/packages/shadcn_ui) - theme in
  `lib/theme/` mirrors WPS's own `app/globals.css` tokens (same navy
  accent, same neutral surfaces, same base radius) so this app reads as
  the same product on a handheld. Icons are `shadcn_ui`'s bundled
  `LucideIcons` - same icon set WPS itself uses (lucide-react). Font is
  Satoshi (`assets/fonts/`) - the same family WPS loads via
  `next/font/local` in `app/layout.js`, re-exported here as `.ttf`
  (converted from WPS's own `.woff2` files - Flutter's font pipeline
  doesn't accept woff2).
- **Scanner**: [honeywell_scanner](https://pub.dev/packages/honeywell_scanner)
  - wraps the physical trigger + hardware decoder on Honeywell devices
  (`lib/core/scanner/barcode_scanner_service.dart`). Also exposes
  `simulateScan(code)` so scan-driven flows can be built/tested with no
  hardware at all - wired into a manual-entry field on the scan screen,
  always visible (not just a no-hardware fallback).
- **Auth**: CIP login (username/password) via wpsApi's existing
  `POST /api/auth/login` proxy (`lib/core/api/auth_api.dart`) - the same
  OAuth2 CIP session wps/stock use, not a separate scheme. `AuthGate` in
  `app.dart` shows `LoginScreen` until `AppSettings.isLoggedIn`.
- **i18n**: [slang](https://pub.dev/packages/slang) (+ `slang_flutter`) -
  translations live in `lib/i18n/*.i18n.json`, generated code in
  `lib/i18n/gen/` (committed, so a fresh clone doesn't need to run
  codegen before its first `flutter run`). Regenerate after editing a
  JSON file: `dart run slang`. Access via `context.t.someKey.nested` in
  any widget under `TranslationProvider` (wraps the whole app in
  `main.dart`). Current locale is `AppSettings.localeCode`
  (`'pl'`/`'en'`, set from SettingsScreen's language dropdown) - bridged
  into slang's own `LocaleSettings` in `app.dart`.
- **Theme**: light/dark/system, `AppSettings.themeMode` (SettingsScreen's
  theme dropdown), wired straight into `ShadApp`'s own `themeMode`.
- **State**: Riverpod (`flutter_riverpod`) - no code generation used yet,
  plain `Provider`/`NotifierProvider`/`AsyncNotifierProvider`.
- **HTTP**: Dio, one shared client (`lib/core/api/api_client.dart`) with an
  interceptor that attaches the bearer token from the in-app settings
  screen to every request - mirrors `wps/lib/smItemsApi.js`'s own
  `apiFetch`.

## Project layout

```
lib/
  main.dart                 entry point (TranslationProvider + ProviderScope + SmPdaApp)
  app.dart                  root ShadApp (theme/darkTheme/themeMode/locale) + AuthGate
  theme/                    colors + ShadThemeData matching WPS
  i18n/                     *.i18n.json (source) + gen/ (generated, committed)
  core/
    api/                    Dio client + auth/sm-items/sm-operations/sm-catalog calls
    scanner/                Honeywell scanner wrapper (+ simulateScan for dev/testing)
    session/                persisted API URL/token, CIP session, theme, locale
  features/
    auth/                   LoginScreen (login/password only)
    home/                   HomeShell (bottom-bar screen switcher - placeholder nav)
    scan/                   smoke-test screen: claims the scanner, lists scans
    settings/               API URL/token, language, theme, logout
```

## Status - what's done

- pubspec, theme, API client + models, scanner service wrapper, CIP
  login, language/theme switching, settings/scan screens, app shell
- Native `android/` scaffolding (`flutter create .`), with
  honeywell_scanner's own native setup already wired in:
  `android/honeywell/` (its `build.gradle` + `honeywell.aar`, copied
  verbatim from
  [the package's example project](https://github.com/luis901101/honeywell_scanner/tree/master/example/android/honeywell)
  since that AAR isn't published to Maven), `include(":honeywell")` in
  `android/settings.gradle.kts`, and `tools:replace="android:label"` on
  `<application>` in `AndroidManifest.xml` (avoids a manifest-merge
  conflict with the AAR's own manifest).
- `web/` and `windows/` platform folders too, for a fast local dev loop
  with no PDA/emulator needed (`flutter run -d chrome` /
  `-d windows` - the latter needs Visual Studio Build Tools' "Desktop
  development with C++" workload and Windows Developer Mode enabled).
- `flutter build apk --debug` succeeds end to end (verified locally -
  needs JDK 21, not 17: honeywell_scanner's own Gradle config targets
  Java 21 bytecode, and the SDK will pull whatever `platforms`/
  `build-tools`/cmake versions the Gradle plugins ask for on first
  build).

Not yet built: any real przyjęcie/wydanie screen against wpsApi - `scan`
is a smoke-test screen (lists whatever's been scanned/typed this
session), and `settings` only holds the API URL/token/language/theme.

## Local dev environment (this machine)

Flutter SDK, Android SDK (cmdline-tools, platform-tools, platforms,
build-tools, licenses), and JDK 21 are installed under
`%USERPROFILE%\dev\flutter` / `%USERPROFILE%\dev\android-sdk` /
`C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot`, with
`ANDROID_HOME`/`JAVA_HOME` and Flutter's own `bin` on the user `PATH` -
not part of this repo, just documented here so a fresh shell on this
machine knows where to look.

An "EDA51K" AVD (`android-29 google_apis x86_64`, LCD forced to
480x800@240dpi to match the real device's 4" panel) exists under
`%USERPROFILE%\.android\avd\` for closer-to-real screen-size testing -
also not part of this repo. `honeywell_scanner`'s `isSupported()` always
returns false on it (no real Honeywell hardware to detect), same as web/
Windows/any plain emulator - use the scan screen's manual-entry field
instead.

On first run, open the gear icon on the login screen (or the Settings
tab once logged in) and point it at your `wpsApi` instance's LAN address
(not `localhost` - the PDA is a separate device on the same Wi-Fi) and
the same `API_TOKEN` wpsApi's `.env` uses - login itself only needs the
address (it doesn't require the bearer token, see AuthApi's own comment).

## Android target

Flutter's own minimum is API 21; Honeywell's Data Collection SDK targets
their own device line directly, which historically includes Android
8/8.1 devices - no known compatibility issue there, but verify against
your specific PDA model.
