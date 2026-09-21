package com.wps.smpda

import com.honeywell.aidc.AidcManager
import com.honeywell.aidc.BarcodeReader
import com.honeywell.aidc.TriggerStateChangeEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var manager: AidcManager? = null
    private var reader: BarcodeReader? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.wps.smpda/trigger")
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> startCapture(result)
                "stop" -> {
                    stopCapture()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // The scan button as a plain "button": the reader is claimed in
    // client-control mode, in which the trigger no longer fires the laser by
    // itself - it only reports its state here. Must not overlap with the
    // honeywell_scanner plugin's own claim (Dart pauses that one first).
    private fun startCapture(result: MethodChannel.Result) {
        stopCapture()
        try {
            AidcManager.create(this) { aidc ->
                try {
                    manager = aidc
                    val r = aidc.createBarcodeReader()
                    r.setProperty(
                        BarcodeReader.PROPERTY_TRIGGER_CONTROL_MODE,
                        BarcodeReader.TRIGGER_CONTROL_MODE_CLIENT_CONTROL,
                    )
                    r.addTriggerListener(object : BarcodeReader.TriggerListener {
                        override fun onTriggerEvent(event: TriggerStateChangeEvent) {
                            if (event.state) runOnUiThread { channel?.invokeMethod("pressed", null) }
                        }
                    })
                    r.claim()
                    reader = r
                    result.success(true)
                } catch (e: Exception) {
                    stopCapture()
                    result.success(false)
                }
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun stopCapture() {
        try {
            reader?.release()
            reader?.close()
        } catch (_: Exception) {
        }
        try {
            manager?.close()
        } catch (_: Exception) {
        }
        reader = null
        manager = null
    }

    override fun onDestroy() {
        stopCapture()
        super.onDestroy()
    }
}
