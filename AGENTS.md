# Project context

`smpda` is the **warehouse PDA app** in this 4-app + backend family: the one
that does the actual physical stock work. It runs on a **Honeywell handheld
scanner** (Android), and everything about it assumes that device: a small
screen, a physical keypad, and a hardware scan trigger.

The family, so this app's place in it is clear:

| app | who uses it | what it does |
|---|---|---|
| `../wpsapi` | - | Express + Postgres backend. Owns all data. Every write goes through it. |
| `../wps` | office / warehouse supervisor | Next.js dashboard: reports, balances, catalog, current lists, order lists. |
| **`.` (smpda)** | **warehouse operator** | **Scans labels, receives and issues stock, labels spools, fulfils material orders.** |
| `../smVendor` | forklift operator ("wózkowy") | Takes a transport order and marks it delivered. |
| `../smOrder` | line foreman ("brygadzista") | Places transport orders and watches them. |
| `../stock` | warehouse staff | Consumer-facing physical stock check/count. |

## What this app actually does

Three modules, listed on the dashboard (`features/dashboard/`,
`core/session/module_access.dart` - `AppModule`: `materialsSm`, `frp`,
`orders`). A module can be gated behind a CIP authority, but **nothing is
gated yet** (`requiredAuthority: null` everywhere) - which CIP permission
opens which module is an open question, not a decision already made.

1. **Materiały SM** (`features/materials/`, routes `/materials-sm`,
   `/materials-sm/operation`, `/materials-sm/spools`) - the core: scan a
   label, then receive or issue that material. Spool-tracked items
   (`trackedIndividually`) are picked per physical spool
   (`spool_picker_screen.dart`); aggregate items take a typed quantity.
   `receive_issue_controller.dart` is the state machine the screens drive,
   and `receive_issue_models.dart` holds the `ScanOutcome` sealed class every
   scan resolves to (`ScanStarted`, `ScanNeedsPick`, `ScanNotIssuable`,
   `ScanUnknown`, `ScanNotInOrder`) - **every `switch` over it is
   exhaustive, so adding a case means updating each one**.
2. **FRP** (`features/frp/`, `/frp`, `/frp/label`) - labelling spools:
   an arriving FRP drum gets a spool number from the series wpsApi hands out
   (`core/api/sm_spools_api.dart`).
3. **Obsługa zamówień** (`features/orders/`, `/orders`, `/orders/:id`) - a
   transport order's material list, scanned and issued straight from the
   order screen. See "Orders" below, the part most easily got wrong. The
   queue is `material_order` in status `inProgress` **or `problem`**: a
   problem the forklift operator reported blocks the delivery, not the
   issuing, and is often about the stock itself - dropping a half-issued
   order off this queue would be the wrong surprise.

## The scanner is the input device
`core/scanner/barcode_scanner_service.dart` wraps the `honeywell_scanner`
plugin's callback API as a plain `Stream` of codes plus a separate error
stream, so screens only listen. Two things to know:
- `init()` must run once before any scan arrives, and it checks
  `isSupported` - so the app **does not crash on a normal phone or
  emulator**, it simply never emits a scan. That is how this is developed
  without the hardware.
- A scanned label is parsed by `features/materials/scanned_code.dart`.
  Supplier labels are `#`-separated (item no # supplier ref # date # date #
  batch # quantity); a plain barcode has no `#` and yields only the item
  number. Materiały SM uses item number + batch (the operator types the
  quantity); FRP also reads the label's quantity as the spool's length.

The physical keypad also drives navigation: `widgets/enter_to_next.dart`
moves focus on Enter, and `core/session/numeric_keyboard.dart` keeps the
on-screen numeric keyboard **off by default** - the device has real keys, so
the touch keyboard would just cover half the screen.

## Orders: what must not be broken
- An ordinary Materiały SM issue (module 1) **must not count** toward a
  transport order's progress. Only an issue performed from inside an order
  carries `sm_operations.order_id`, and wpsApi's `order_items_progress` view
  sums exactly those. Keep that invariant on any change here.
- Inside an order, issuing an item **not on that order's list** is refused
  (`ScanNotInOrder`) - `ReceiveIssueState.orderId` +
  `orderItemQuantities` gate it; `setOrderContext()` on entering an order
  screen, `clearOrderContext()` on leaving.
- The "Wydano" line shows **the catalog's unit**, and for FRP the **summed
  length in km** (not the drum count wpsApi's `issuedUnit` reports as
  "szt."): `OrderItem.displayIssuedQuantity`/`displayIssuedUnit` in
  `features/orders/orders_api.dart`. `isFulfilled` keeps using the
  server's piece count, because that is what an FRP order is placed in -
  **do not "simplify" the two into one**.
- Both order screens poll (`Timer.periodic`, 3 s, with a `_polling` guard)
  so a status change shows up without pulling to refresh.

## Riverpod traps already hit here (both cost a live crash)
1. **Never call `ref.read(...)` from `dispose()`** - it throws
   `StateError: Using "ref" when a widget is about to or has been unmounted`.
   Capture the notifier **eagerly in `initState()`** as a plain assignment.
   `late final x = ref.read(...)` does **not** fix it: `late` initializes on
   first *read*, and if that read is in `dispose()` the crash is identical.
   See `order_detail_screen.dart`'s `_receiveIssueController`.
2. **Never mutate a provider synchronously from `initState()`/`build()`** -
   "Tried to modify a provider while the widget tree was building". Defer
   with `Future.microtask(...)` (earlier than `addPostFrameCallback`).

## Conventions
- **UI is `shadcn_ui`** (`ShadButton`, `ShadInput`, `ShadSelect`, ...) on
  `package:flutter/widgets.dart` - Material is imported only for single
  names like `ThemeMode`/`TextInputAction`. `theme/` mirrors wps's own
  Tailwind tokens as plain Dart hex (`app_colors.dart`), so the three
  Flutter apps and the web dashboard look like one product. Don't add a
  second UI package.
- **i18n is `slang`**: edit `lib/i18n/pl.i18n.json` / `en.i18n.json`, then
  run `dart run slang`. Polish is the base locale.
- **Routing is `go_router`** (`router.dart`) - unlike smVendor/smOrder,
  which have no router at all.
- **Settings live in one object**: `core/session/app_settings.dart`
  (`AppSettings`, SharedPreferences-backed) holds apiBaseUrl, apiToken, the
  CIP session, theme, locale and the numeric-keyboard flag together, since
  they are always read as a unit. `apiBaseUrl`/`apiToken` are typed in on
  the Settings screen - this app is configured per device, not at build time
  (unlike smVendor/smOrder's `--dart-define=API_TOKEN=...`).
- **The CIP token is used for real here**: an issue/receipt is pushed to CIP
  with the operator's own token, so `core/session/cip_session.dart`
  (`CipSessionService`) renews it before expiry and again if CIP refuses it,
  and logs out when even the refresh token is dead. Any new code that sends
  a token to CIP must go through it.
- **Offline is refused, by decision**: `widgets/require_online.dart` blocks
  scanning without a connection. If offline work is ever wanted, see
  wpsApi's AGENTS.md roadmap - it needs an idempotency-keyed "apply
  operation" endpoint, not `PUT /sm-items` (which overwrites whole rows and
  races between two PDAs).

## Running it
`flutter run -d <device>` on the scanner (`flutter devices` lists it by
serial). Analyzer must be clean: `flutter analyze`.
