package com.wjprogramer.flutter_sing_tools

import android.content.Context
import android.media.*
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "real_time_audio"

    private var audioTrack: AudioTrack? = null
    private var selectedOutputDeviceId: Int? = null
    private var selectedInputDeviceId: Int? = null
    private val sampleRate = 16000
    private val channelConfig = AudioFormat.CHANNEL_OUT_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "write" -> {
                    val byteArray = call.arguments as ByteArray
                    playAudio(byteArray)
                    result.success(null)
                }
                "setOutputDevice" -> {
                    selectedOutputDeviceId = (call.argument<Int>("id"))
                    recreateAudioTrack()
                    result.success(true)
                }
                "getOutputDevices" -> {
                    val devices = getAudioDevices(AudioManager.GET_DEVICES_OUTPUTS)
                    result.success(devices)
                }
                "setInputDevice" -> {
                    selectedInputDeviceId = (call.argument<Int>("id"))
                    // ⚠️ 此範例未啟用錄音邏輯，請根據 FlutterSound 或自定錄音程式整合 selectedInputDeviceId
                    result.success(true)
                }
                "getInputDevices" -> {
                    val devices = getAudioDevices(AudioManager.GET_DEVICES_INPUTS)
                    result.success(devices)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getAudioDevices(type: Int): List<Map<String, Any>> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val deviceList = mutableListOf<Map<String, Any>>()

        val devices = audioManager.getDevices(type)
        for (device in devices) {
            deviceList.add(
                mapOf(
                    "id" to device.id,
                    "type" to device.type,
                    "isSource" to device.isSource,
                    "isSink" to device.isSink,
                    "productName" to device.productName.toString()
                )
            )
        }
        return deviceList
    }

    private fun recreateAudioTrack() {
        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null

        var matched: AudioDeviceInfo? = null
        if (selectedOutputDeviceId != null) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val outputDevices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            matched = outputDevices.firstOrNull { it.id == selectedOutputDeviceId }
        }

        audioTrack = createAudioTrack()
        if (matched != null) {
            audioTrack?.setPreferredDevice(matched)
        }
        audioTrack?.play()
    }

    private fun playAudio(buffer: ByteArray?) {
        if (audioTrack == null) {
            audioTrack = createAudioTrack()
            audioTrack?.play()
        }
        if (buffer != null) {
            audioTrack?.write(buffer, 0, buffer.size)
        }
    }

    private fun createAudioTrack(): AudioTrack {
        // deprecated 的寫法，需要再確認新舊寫法是否等價
//        return AudioTrack(
//            AudioManager.STREAM_MUSIC,
//            sampleRate,
//            channelConfig,
//            audioFormat,
//            bufferSize,
//            AudioTrack.MODE_STREAM
//        )
        val attr = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()

        val format = AudioFormat.Builder()
            .setEncoding(audioFormat)
            .setSampleRate(sampleRate)
            .setChannelMask(channelConfig)
            .build()

        val builder = AudioTrack.Builder()
            .setAudioAttributes(attr)
            .setAudioFormat(format)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setBufferSizeInBytes(bufferSize)

        return builder.build()
    }

    override fun onDestroy() {
        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null
        super.onDestroy()
    }
}
