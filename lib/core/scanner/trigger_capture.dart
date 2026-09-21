import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'barcode_scanner_service.dart';

/// Turns the PDA's physical scan button into a plain "confirm" button on the
/// screens that hold it (see MainActivity.kt): while at least one screen has
/// [acquire]d it, a press only shows up on [onPressed] - the laser doesn't
/// fire and nothing gets scanned. The honeywell_scanner plugin's own claim
/// is parked meanwhile (only one reader can hold the scanner) and resumed
/// once the last screen [release]s it.
///
/// Counted rather than a simple on/off because go_router's pushReplacement
/// builds the next screen before disposing the old one - a plain stop() from
/// the old screen would kill the capture the new one just started.
class TriggerCapture {
  TriggerCapture(this._scanner) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pressed') _pressed.add(null);
    });
  }

  static const _channel = MethodChannel('com.wps.smpda/trigger');
  final BarcodeScannerService _scanner;
  final _pressed = StreamController<void>.broadcast();

  int _holders = 0;
  bool _active = false;
  Future<void> _queue = Future.value();

  Stream<void> get onPressed => _pressed.stream;

  void acquire() {
    _holders++;
    _queue = _queue.then((_) => _sync());
  }

  void release() {
    _holders--;
    _queue = _queue.then((_) => _sync());
  }

  Future<void> _sync() async {
    try {
      if (_holders > 0 && !_active) {
        await _scanner.pause();
        _active = await _invoke<bool>('start') ?? false;
        // Not a Honeywell device (or the claim failed): put the plugin's
        // own scanner back rather than leave both off.
        if (!_active) await _scanner.resume();
      } else if (_holders <= 0 && _active) {
        await _invoke<void>('stop');
        _active = false;
        await _scanner.resume();
      }
    } catch (_) {
      // Best effort - a failed hand-over must never break the screen.
    }
  }

  Future<T?> _invoke<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

final triggerCaptureProvider = Provider<TriggerCapture>((ref) {
  return TriggerCapture(ref.watch(barcodeScannerServiceProvider));
});
