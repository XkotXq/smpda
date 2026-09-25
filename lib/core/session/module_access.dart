import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_providers.dart';

/// The dashboard's modules and who may use them. A module whose
/// `requiredAuthority` is null is open to everyone; otherwise the logged-in
/// person's CIP authorities (AppSettings.authorities, from login) must contain
/// it - and a module the person may not use is left out of the dashboard
/// altogether, so the remaining ones are numbered 1, 2, ... without a gap
/// (the numbers are also the PDA's number keys).
///
/// Nothing requires an authority yet: which CIP permission opens which module
/// is still to be decided (e.g. FRP labeling not for forklift drivers). Set
/// the name here when it is - it is the only place to change.
enum AppModule {
  materialsSm(requiredAuthority: null),
  frp(requiredAuthority: null),
  orders(requiredAuthority: null);

  const AppModule({required this.requiredAuthority});
  final String? requiredAuthority;
}

/// The modules the logged-in person may open, in dashboard order.
final availableModulesProvider = Provider<List<AppModule>>((ref) {
  final authorities = ref.watch(appSettingsProvider.select((s) => s.value?.authorities ?? const <String>[]));
  return [
    for (final module in AppModule.values)
      if (module.requiredAuthority == null || authorities.contains(module.requiredAuthority)) module,
  ];
});
