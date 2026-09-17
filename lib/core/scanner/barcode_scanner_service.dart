import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeywell_scanner/honeywell_scanner.dart';

/// Wraps the honeywell_scanner plugin's callback API as a plain [Stream] of
/// scanned codes (and a separate error stream) - screens just listen,
/// nothing about them needs to know this is a hardware-trigger callback
/// under the hood.
///
/// `init()` must run once (e.g. from the widget that owns the scan screen's
/// lifecycle) before any scan can be received - it checks [isSupported] so
/// this app doesn't hard-crash when run on a plain (non-Honeywell) device/
/// emulator during development, it just never emits a scan.
class BarcodeScannerService {
  BarcodeScannerService()
      : _scanner = HoneywellScanner(),
        _codeController = StreamController<String>.broadcast(),
        _errorController = StreamController<Object>.broadcast();

  final HoneywellScanner _scanner;
  final StreamController<String> _codeController;
  final StreamController<Object> _errorController;

  Stream<String> get onScan => _codeController.stream;
  Stream<Object> get onError => _errorController.stream;

  bool _started = false;

  /// True once [init] has run - screens use this to decide whether to show
  /// the manual-entry fallback (see [simulateScan]) instead of/alongside
  /// the "point the PDA and pull the trigger" UI.
  bool get isHardwareScanner => _started;

  /// Feeds [onScan] exactly like a real decode would - lets every screen
  /// built on top of this service (receive/issue flows included) be
  /// developed and tested on a plain PC/emulator, with no Honeywell
  /// hardware involved at all. Always available, not gated on [init]
  /// having found real hardware.
  void simulateScan(String code) {
    if (code.isNotEmpty) _codeController.add(code);
  }

  Future<bool> init() async {
    final supported = await _scanner.isSupported();
    if (!supported) return false;

    _scanner
      ..setScannerDecodeCallback((scannedData) {
        final code = scannedData?.code;
        if (code != null && code.isNotEmpty) _codeController.add(code);
      })
      ..setScannerErrorCallback((error) => _errorController.add(error));

    _started = await _scanner.startScanner();
    return _started;
  }

  /// Only meaningful if [init] returned true - see [BarcodeScannerService]'s
  /// own doc comment about running on non-Honeywell devices.
  Future<void> pause() => _started ? _scanner.pauseScanner() : Future.value();
  Future<void> resume() =>
      _started ? _scanner.resumeScanner() : Future.value();

  Future<void> dispose() async {
    if (_started) await _scanner.stopScanner();
    await _codeController.close();
    await _errorController.close();
  }
}

/// Kept alive for the app's lifetime (not autoDispose) - claiming/releasing
/// the physical scanner repeatedly as screens come and go is both slow and
/// prone to leaving the trigger unclaimed; this app claims it once at
/// startup (see main.dart) and every screen just listens to [onScan].
final barcodeScannerServiceProvider = Provider<BarcodeScannerService>((ref) {
  final service = BarcodeScannerService();
  ref.onDispose(service.dispose);
  return service;
});
