package com.example.soundspace

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.soundspace.service.AudioCaptureService

class MainActivity : FlutterActivity() {
    private val CH = "com.example.soundspace/audio_engine"
    private val REQ = 1001
    private var pending: MethodChannel.Result? = null

    override fun configureFlutterEngine(fe: FlutterEngine) {
        super.configureFlutterEngine(fe)
        MethodChannel(fe.dartExecutor.binaryMessenger, CH).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCapture" -> {
                    val priv = call.argument<Boolean>("privileged") ?: false
                    if (priv) {
                        startForegroundService(Intent(this, AudioCaptureService::class.java).apply { putExtra("PRIVILEGED_MODE", true) })
                        result.success(true)
                    } else {
                        pending = result
                        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        startActivityForResult(mgr.createScreenCaptureIntent(), REQ)
                    }
                }
                "stopCapture" -> { stopService(Intent(this, AudioCaptureService::class.java)); result.success(true) }
                "checkShizuku" -> result.success(mapOf(
                    "installed" to ShizukuHelper.isInstalled(this),
                    "running" to ShizukuHelper.isRunning(),
                    "authorized" to (ShizukuHelper.isRunning() && ShizukuHelper.checkPermission(0))
                ))
                "updateParams" -> {
                    AudioCaptureService.updateParams(
                        call.argument<String>("id") ?: "",
                        (call.argument<Double>("x") ?: .5).toFloat(),
                        (call.argument<Double>("y") ?: .5).toFloat(),
                        (call.argument<Double>("gain") ?: 1.0).toFloat(),
                        call.argument<Boolean>("muted") ?: false
                    ); result.success(null)
                }
                "setRoomSize"    -> { AudioCaptureService.setRoomSize((call.argument<Double>("size") ?: .5).toFloat()); result.success(null) }
                "setStereoWidth" -> { AudioCaptureService.setStereoWidth((call.argument<Double>("width") ?: 1.0).toFloat()); result.success(null) }
                "setEq"          -> { AudioCaptureService.setEq((call.argument<List<Double>>("bands") ?: List(5){0.0}).map{it.toFloat()}.toFloatArray()); result.success(null) }
                "setReverb"      -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(req: Int, res: Int, data: Intent?) {
        super.onActivityResult(req, res, data)
        if (req == REQ) {
            if (res == Activity.RESULT_OK && data != null) {
                startForegroundService(Intent(this, AudioCaptureService::class.java).apply { putExtra("RESULT_DATA", data) })
                pending?.success(true)
            } else { pending?.success(false) }
            pending = null
        }
    }
}
