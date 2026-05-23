package com.zbooma.moharek

import android.media.MediaRecorder
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zbooma.app/voice_recorder"
    private var recorder: MediaRecorder? = null
    private var lastFilePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        startRecording(path, result)
                    } else {
                        result.error("INVALID_PATH", "Path was null", null)
                    }
                }
                "stopRecording" -> {
                    stopRecording(result)
                }
                "cancelRecording" -> {
                    cancelRecording(result)
                }
                "getAmplitude" -> {
                    result.success(getAmplitude())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startRecording(path: String, result: MethodChannel.Result) {
        try {
            lastFilePath = path
            recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                MediaRecorder()
            }
            recorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setOutputFile(path)
                prepare()
                start()
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("START_ERROR", e.message, null)
        }
    }

    private fun stopRecording(result: MethodChannel.Result) {
        try {
            recorder?.apply {
                stop()
                release()
            }
            recorder = null
            result.success(lastFilePath)
        } catch (e: Exception) {
            result.error("STOP_ERROR", e.message, null)
        }
    }

    private fun cancelRecording(result: MethodChannel.Result) {
        try {
            recorder?.apply {
                stop()
                release()
            }
            recorder = null
            lastFilePath?.let {
                val file = File(it)
                if (file.exists()) file.delete()
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("CANCEL_ERROR", e.message, null)
        }
    }

    private fun getAmplitude(): Double {
        return try {
            val maxAmp = recorder?.maxAmplitude ?: 0
            // Normalize to 0..1
            (maxAmp.toDouble() / 32767.0).coerceIn(0.0, 1.0)
        } catch (e: Exception) {
            0.0
        }
    }
}
