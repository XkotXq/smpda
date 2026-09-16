import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/scanner/barcode_scanner_service.dart';

/// First cut of the scan screen: claims the hardware scanner, lists every
/// code read this session (newest first). Real screens (przyjęcie/wydanie
/// against wpsApi) build on top of this same onScan stream - this is here
/// so the Honeywell wiring can be smoke-tested on a real device before any
/// of that exists.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _codes = <String>[];
  StreamSubscription<String>? _scanSub;
  StreamSubscription<Object>? _errorSub;
  bool _supported = true;

  @override
  void initState() {
    super.initState();
    _wire();
  }

  Future<void> _wire() async {
    final scanner = ref.read(barcodeScannerServiceProvider);
    final ok = await scanner.init();
    if (!mounted) return;
    setState(() => _supported = ok);
    _scanSub = scanner.onScan.listen((code) {
      if (!mounted) return;
      setState(() => _codes.insert(0, code));
    });
    _errorSub = scanner.onError.listen((error) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text('$error')),
      );
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Ten skaner nie jest wspierany na tym urządzeniu - honeywell_scanner '
            'zwrócił isSupported() = false (np. zwykły telefon/emulator zamiast PDA).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_codes.isEmpty) {
      return const Center(child: Text('Naciśnij spust skanera, aby zeskanować kod.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _codes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return ShadCard(
          padding: const EdgeInsets.all(12),
          child: Text(_codes[index], style: ShadTheme.of(context).textTheme.p),
        );
      },
    );
  }
}
