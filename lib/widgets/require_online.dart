import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/api/api_client.dart';
import '../core/api/server_status.dart';
import '../i18n/gen/strings.g.dart';

/// Asks the server right now and, when it doesn't answer, shows the "no
/// connection" toast and returns false - the caller stops there. Called at the
/// start of a scan: with no connection nothing can be read (name, stock) or
/// saved, so the scan is refused up front instead of failing halfway through.
Future<bool> requireOnline(BuildContext context, WidgetRef ref) async {
  final online = await isServerReachable(ref.read(dioProvider));
  if (online || !context.mounted) return online;
  ShadToaster.of(context).show(ShadToast.destructive(description: Text(context.t.operations.toastOffline)));
  return false;
}
