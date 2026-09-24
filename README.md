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
  hardware at all - wired into a manual-entry field on the operations
  screen, always visible (not just a no-hardware fallback).
- **Auth**: CIP login (username/password) via wpsApi's existing
  `POST /api/auth/login` proxy (`lib/core/api/auth_api.dart`) - the same
  OAuth2 CIP session wps/stock use, not a separate scheme.
- **Routing**: [go_router](https://pub.dev/packages/go_router)
  (`lib/router.dart`) - named routes (`loginPath`/`dashboardPath`/
  `materialsSmPath`/`frpPath`/`settingsPath` constants) instead of ad-hoc
  `Navigator.push(MaterialPageRoute(...))`. A single `redirect` rule
  gates every route but `/login` on `AppSettings.isLoggedIn` (replaces
  the old widget-level `AuthGate`) - `refreshListenable` is a small
  `ChangeNotifier` that listens to `appSettingsProvider` via `ref.listen`
  so login/logout re-runs the redirect immediately.
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
  app.dart                  root ShadApp.router (theme/darkTheme/themeMode/locale)
  router.dart                GoRouter - routes + the login/dashboard redirect rule
  theme/                    colors + ShadThemeData matching WPS
  i18n/                     *.i18n.json (source) + gen/ (generated, committed)
  widgets/                  SectionHeader/SectionScaffold - shared back-button header for pushed sections
  core/
    api/                    Dio client + auth/sm-items/sm-operations/sm-catalog calls
    scanner/                Honeywell scanner wrapper (+ simulateScan for dev/testing)
    session/                persisted API URL/token, CIP session, theme, locale
    utils/                  quantity.dart - sanitize/parse/format, mirrors wps's lib/quantityInput.js
  features/
    auth/                   LoginScreen (login/password only)
    dashboard/              DashboardScreen - tile picker (Materiały SM, FRP) shown after login
    frp/                    FrpScreen - placeholder, not built yet
    home/                   HomeShell - Materiały SM's title bar + Przyjęcie/Wydanie switch
    materials/              scan -> fill in quantity -> confirm przyjęcie/wydanie flow (see below)
    settings/               API URL/token, language, theme, logout
```

### `features/materials/` - przyjęcie/wydanie

One operation at a time, not a batch: scan (or type) a code, its own full
screen (`OperationScreen`, pushed via go_router - see
`materialsSmOperationPath` in `router.dart`) shows which mode this is
under, then the item's number/name/[available quantity for an issue] and
a quantity field, confirm, and you're back on the scan screen ready for
the next one. No queue/review step - an operator's hands are on the
scanner trigger and the PDA's own keypad, not building up a list to
review later.

- `receive_issue_models.dart` - `FlowMode` (receive/issue), `IssueKind`
  (unit/aggregate/pending, mirroring wpsApi's own row-kind split), the
  `CurrentOperation` sealed type (`ReceiveOperation`/`IssueOperation` -
  the one operation in progress, or none), `ScanOutcome` (what a scan
  resolved to: started, needs a picker, unknown code, or nothing
  available to issue).
- `receive_issue_controller.dart` - `ReceiveIssueController` (Riverpod
  `Notifier`). `scan(code)` does two-tier resolution: first checks every
  cached item's units for a matching *unit tag* (issue mode only - a
  spool's own label identifies an exact unit to issue in full), then
  falls back to an *item-number* match against current stock, then
  `sm_catalog`. An item-number match starts the operation when
  unambiguous (one leaf to issue, or any receipt) and returns
  `ScanNeedsPick` when an issue could mean more than one unit/pending
  remainder - the screen opens a picker sheet for that case. `submit()`
  saves the one current operation as one `SmItemsApi.upsert()` + one
  `SmOperationsApi.create()` call (clamp-not-delete for aggregate/
  pending issues, drop-from-units-array for a full unit issue, append-
  new-unit or increment pending/total for a receipt - never delete an
  item at zero, since `sm_items` is shared with WPS's own UI), then
  clears the operation and patches `smItemsListProvider`'s cache with the
  server's own response (`SmItemsListNotifier.upsertLocal` in
  `materials_providers.dart`) instead of invalidating + refetching - a
  refetch's request/response round trip left a real window where
  scanning the very next item (right after confirming the previous one)
  came back "unknown" because the cache had gone back to `null` while
  loading.
- `materials_providers.dart` - `smItemsListProvider` (`AsyncNotifierProvider`,
  patched locally after every submit, see above) and `smCatalogListProvider`
  (`FutureProvider`, read once - it only feeds the manual-entry suggestions;
  the catalog changes once a year or two). A receipt asks the server about
  the one item instead: `startReceive` opens the screen at once, then
  `resolveReceive` reads the stock row and `GET /sm-catalog/{itemNo}`
  together. The catalog names the material and its `individualUnits` flag
  decides whether the spool-number field appears; wpsApi also fills the name
  from the catalog on save. An aggregate item that already has stock is
  upgraded to per-spool on submit when the catalog says so (its total becomes
  the pending "Brak" quantity) - never downgraded.
- `lib/widgets/require_online.dart` - every scan (Przyjęcie/Wydanie and the
  FRP module) first makes a fresh `GET /health` (`isServerReachable` in
  `core/api/server_status.dart`); with no answer the scan is refused with a
  toast instead of failing halfway. There is no offline mode by decision.
- `receive_issue_screen.dart` - just the scan/manual-entry field (reuses
  `BarcodeScannerService`) and an idle message; pushes
  `materialsSmOperationPath` once a scan resolves. Picker `showShadSheet`
  for the ambiguous-issue case also pushes it once something's picked.
- `operation_screen.dart` - the pushed screen itself: mode title, item
  card, auto-focused quantity field (system/physical keyboard handles
  input - no custom on-screen keypad: a `virtual_keypad` package
  integration was tried and dropped after its keys didn't actually
  insert characters into `ShadInput` on a real device test; turned out
  unnecessary too, since a focused field already accepts a PDA's
  physical keys with zero extra code), Anuluj/Zatwierdź buttons.
  **Pushed via `context.push`/popped via `context.pop` (go_router), never
  a raw `Navigator.push`/`pop`** - an earlier version pushed it as a bare
  `PageRouteBuilder` on the ambient `Navigator`, which go_router doesn't
  track as one of its own pages; popping it back out then desynced
  go_router's own idea of the current location, and confirming/
  cancelling an operation would land back on the dashboard instead of
  the scan screen it was pushed from.

## Status - what's done

- pubspec, theme, API client + models, scanner service wrapper, CIP
  login, language/theme switching, settings screen, przyjęcie/wydanie
  flow (`features/materials/`), app shell
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

Przyjęcie/wydanie has been click-tested end to end on the EDA51K
emulator against a real local wpsApi (`SKIP_CIP_AUTH`/`SKIP_API_AUTH`
enabled, see below): scan -> item details -> type quantity -> confirm ->
verified the row in Postgres actually changed, for both modes. Not yet
tried against real Honeywell hardware/a real network.

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
On the Android emulator specifically, `localhost`/the host's real LAN IP
are usually *not* reachable from inside the emulator's own network -
use `http://10.0.2.2:<port>` (the emulator's alias for the host) instead.

Working from a network that can't reach the real CIP system (e.g. home,
off VPN)? wpsApi's own `SKIP_CIP_AUTH=true` (`.env`, dev-only, see its
`src/routes/auth.js`) accepts any non-empty login/password instead of
proxying to CIP - paired with the existing `SKIP_API_AUTH=true` this
gets the whole app working end to end against a local Postgres with no
company-network dependency at all.

## Android target

Flutter's own minimum is API 21; Honeywell's Data Collection SDK targets
their own device line directly, which historically includes Android
8/8.1 devices - no known compatibility issue there, but verify against
your specific PDA model.
