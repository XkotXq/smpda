# SmPda

Flutter app for Honeywell Android PDAs (scan-and-receive/issue on the
warehouse floor), talking to the same `wpsApi` backend as the `WPS`
dashboard - specifically the Materiały SM endpoints (`sm-items`,
`sm-operations`, `sm-catalog`). See `../wpsApi/AGENTS.md` and
`../WPS/AGENTS.md`'s "Materiały SM" section for the data model this app
builds on.

## Stack

- **UI**: [shadcn_ui](https://pub.dev/packages/shadcn_ui) - theme in
  `lib/theme/` mirrors WPS's own `app/globals.css` tokens (same navy
  accent, same neutral surfaces, same base radius) so this app reads as
  the same product on a handheld.
- **Scanner**: [honeywell_scanner](https://pub.dev/packages/honeywell_scanner)
  - wraps the physical trigger + hardware decoder on Honeywell devices
  (`lib/core/scanner/barcode_scanner_service.dart`).
- **State**: Riverpod (`flutter_riverpod`) - no code generation used yet,
  plain `Provider`/`NotifierProvider`/`AsyncNotifierProvider`.
- **HTTP**: Dio, one shared client (`lib/core/api/api_client.dart`) with an
  interceptor that attaches the bearer token from the in-app settings
  screen to every request - mirrors `wps/lib/smItemsApi.js`'s own
  `apiFetch`.

## Project layout

```
lib/
  main.dart                 entry point (ProviderScope + SmPdaApp)
  app.dart                  root ShadApp (theme/darkTheme/themeMode)
  theme/                    colors + ShadThemeData matching WPS
  core/
    api/                    Dio client + typed sm-items/sm-operations/sm-catalog calls
    scanner/                Honeywell scanner wrapper
    session/                persisted API URL / token / operator name
  features/
    home/                   HomeShell (bottom-bar screen switcher - placeholder nav)
    scan/                   smoke-test screen: claims the scanner, lists scans
    settings/               API URL / token / operator form
```

## Status - what's done

- pubspec, theme, API client + models, scanner service wrapper,
  settings/scan screens, app shell
- Native `android/` scaffolding (`flutter create .`), with
  honeywell_scanner's own native setup already wired in:
  `android/honeywell/` (its `build.gradle` + `honeywell.aar`, copied
  verbatim from
  [the package's example project](https://github.com/luis901101/honeywell_scanner/tree/master/example/android/honeywell)
  since that AAR isn't published to Maven), `include(":honeywell")` in
  `android/settings.gradle.kts`, and `tools:replace="android:label"` on
  `<application>` in `AndroidManifest.xml` (avoids a manifest-merge
  conflict with the AAR's own manifest).
- `flutter build apk --debug` succeeds end to end (verified locally -
  needs JDK 21, not 17: honeywell_scanner's own Gradle config targets
  Java 21 bytecode, and the SDK will pull whatever `platforms`/
  `build-tools`/cmake versions the Gradle plugins ask for on first
  build).

Not yet built: any real przyjęcie/wydanie screen against wpsApi - `scan`
is a smoke-test screen (lists whatever's been scanned this session), and
`settings` only holds the API URL/token/operator.

## Local dev environment (this machine)

Flutter SDK, Android SDK (cmdline-tools, platform-tools, platforms,
build-tools, licenses), and JDK 21 are installed under
`%USERPROFILE%\dev\flutter` / `%USERPROFILE%\dev\android-sdk` /
`C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot`, with
`ANDROID_HOME`/`JAVA_HOME` and Flutter's own `bin` on the user `PATH` -
not part of this repo, just documented here so a fresh shell on this
machine knows where to look.

On first run, open the Settings tab and point it at your `wpsApi`
instance's LAN address (not `localhost` - the PDA is a separate device
on the same Wi-Fi) and the same `API_TOKEN` wpsApi's `.env` uses.

## Android target

Flutter's own minimum is API 21; Honeywell's Data Collection SDK targets
their own device line directly, which historically includes Android
8/8.1 devices - no known compatibility issue there, but verify against
your specific PDA model.
