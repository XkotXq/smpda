import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session/session_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/frp/frp_screen.dart';
import 'features/home/home_shell.dart';
import 'features/settings/settings_screen.dart';
import 'i18n/gen/strings.g.dart';
import 'widgets/section_scaffold.dart';

/// Top-level destinations - each section (Materiały SM, FRP) gets its own
/// route rather than being reached only through DashboardScreen's tiles,
/// so a deep link / back stack / (eventually) nested routes under each
/// section all have somewhere real to point at. Screens that switch
/// between a few tabs internally (HomeShell's own Scan/Settings bottom
/// bar) stay plain widget state for now - not every internal tab needs to
/// be its own route yet, see the module doc on GoRouter below for where
/// this is expected to grow.
const loginPath = '/login';
const dashboardPath = '/dashboard';
const materialsSmPath = '/materials-sm';
const frpPath = '/frp';
const settingsPath = '/settings';

/// Notifies GoRouter's `redirect` to re-run whenever AppSettings changes -
/// specifically login/logout, which is the only thing `redirect` itself
/// checks. GoRouter needs a Listenable, not a raw riverpod provider.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(appSettingsProvider, (_, _) => notifyListeners());
  }
}

/// One long-lived GoRouter instance for the app's lifetime (recreating it
/// on every settings change would drop the navigation stack) - `redirect`
/// reads the *current* auth state via `ref.read` at redirect-time instead
/// of closing over a stale value from when this provider first ran.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  return GoRouter(
    initialLocation: loginPath,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(appSettingsProvider).value?.isLoggedIn ?? false;
      final onLogin = state.matchedLocation == loginPath;
      // Settings has to be reachable while logged out too - it's where the
      // API URL/token get configured in the first place, and both
      // LoginScreen and DashboardScreen push to it via the same gear icon.
      final onSettings = state.matchedLocation == settingsPath;
      if (!loggedIn) return (onLogin || onSettings) ? null : loginPath;
      if (onLogin) return dashboardPath;
      return null;
    },
    routes: [
      GoRoute(path: loginPath, builder: (context, state) => const LoginScreen()),
      GoRoute(path: dashboardPath, builder: (context, state) => const DashboardScreen()),
      GoRoute(path: materialsSmPath, builder: (context, state) => const HomeShell()),
      GoRoute(
        path: frpPath,
        builder: (context, state) => SectionScaffold(
          title: context.t.dashboard.frp.title,
          body: const FrpScreen(),
        ),
      ),
      GoRoute(path: settingsPath, builder: (context, state) => const SettingsScreen()),
    ],
  );
});
