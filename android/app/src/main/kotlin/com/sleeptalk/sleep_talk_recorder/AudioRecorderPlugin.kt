package com.sleeptalk.sleep_talk_recorder

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.os.Process
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class AudioRecorderPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null
    private val isRecording = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "com.sleeptalk/audio_recorder")
        methodChannel?.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "com.sleeptalk/audio_recorder/stream")
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopRecording()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val sampleRate = call.argument<Int>("sampleRate") ?: 16000
                startRecording(sampleRate, result)
            }
            "stop" -> {
                stopRecording()
                result.success(true)
            }
            "isRecording" -> {
                result.success(isRecording.get())
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startRecording(sampleRate: Int, result: MethodChannel.Result) {
        if (isRecording.get()) {
            result.success(true)
            return
        }

        try {
            val minBufSize = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            if (minBufSize == AudioRecord.ERROR || minBufSize == AudioRecord.ERROR_BAD_VALUE) {
                result.error("AUDIO_RECORD_ERROR", "Invalid audio parameters: sampleRate=$sampleRate", null)
                return
            }

            val bufferSize = maxOf(minBufSize * 2, 4096)

            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                audioRecord?.release()
                audioRecord = null
                result.error("AUDIO_RECORD_ERROR", "AudioRecord initialization failed", null)
                return
            }

            audioRecord?.startRecording()
            if (audioRecord?.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                audioRecord?.release()
                audioRecord = null
                result.error("AUDIO_RECORD_ERROR", "AudioRecord failed to start", null)
                return
            }

            isRecording.set(true)

            recordingThread = Thread {
                // 在录音线程内设置优先级，不影响主线程
                Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
                val buffer = ByteArray(bufferSize)
                while (isRecording.get()) {
                    val bytesRead = audioRecord?.read(buffer, 0, buffer.size) ?: -1
                    if (bytesRead > 0) {
                        val data = buffer.copyOf(bytesRead)
                        // 通过主线程发送事件，避免线程安全问题
                        mainHandler.post {
                            eventSink?.success(data)
                        }
                    } else if (bytesRead < 0) {
                        // Read error, stop
                        break
                    }
                }
            }
            recordingThread?.start()

            result.success(true)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "Microphone permission not granted", e.message)
        } catch (e: IllegalArgumentException) {
            result.error("AUDIO_RECORD_ERROR", "Invalid audio configuration: ${e.message}", null)
        } catch (e: Exception) {
            result.error("AUDIO_RECORD_ERROR", e.message, null)
        }
    }

    private fun stopRecording() {
        isRecording.set(false)
        recordingThread?.join(500)
        recordingThread = null
        try {
            audioRecord?.apply {
                if (recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    stop()
                }
                release()
            }
        } catch (_: Exception) {}
        audioRecord = null
    }
}