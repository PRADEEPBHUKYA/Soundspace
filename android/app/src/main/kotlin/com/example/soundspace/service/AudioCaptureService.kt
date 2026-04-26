package com.example.soundspace.service

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.*
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.IBinder
import androidx.core.app.NotificationCompat

class AudioCaptureService : Service() {
    private var projection: MediaProjection? = null
    private var recorder: AudioRecord? = null
    private var running = false

    companion object {
        init { System.loadLibrary("soundspace") }

        @JvmStatic external fun nativeInit()
        @JvmStatic external fun nativeFeed(data: ShortArray, size: Int)
        @JvmStatic external fun nativeUpdateParams(id: String, x: Float, y: Float, gain: Float, muted: Boolean)
        @JvmStatic external fun nativeSetRoomSize(s: Float)
        @JvmStatic external fun nativeSetStereoWidth(w: Float)
        @JvmStatic external fun nativeSetEq(b: FloatArray)
        @JvmStatic external fun nativeStop()

        fun updateParams(id: String, x: Float, y: Float, gain: Float, muted: Boolean) = nativeUpdateParams(id,x,y,gain,muted)
        fun setRoomSize(s: Float) = nativeSetRoomSize(s)
        fun setStereoWidth(w: Float) = nativeSetStereoWidth(w)
        fun setEq(b: FloatArray) = nativeSetEq(b)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, id: Int): Int {
        createChannel(); startForeground(1, notif())
        val priv = intent?.getBooleanExtra("PRIVILEGED_MODE", false) ?: false
        if (priv) startPrivileged()
        else {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra<Intent>("RESULT_DATA")?.let { startProjection(it) } ?: stopSelf()
        }
        return START_STICKY
    }

    private fun startPrivileged() {
        try {
            recorder = AudioRecord.Builder()
                .setAudioSource(8) // REMOTE_SUBMIX
                .setAudioFormat(AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(48000).setChannelMask(AudioFormat.CHANNEL_IN_STEREO).build())
                .build()
            loop()
        } catch (e: SecurityException) { stopSelf() }
    }

    private fun startProjection(data: Intent) {
        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        projection = mgr.getMediaProjection(Activity.RESULT_OK, data)
        val cfg = AudioPlaybackCaptureConfiguration.Builder(projection!!)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME).build()
        recorder = AudioRecord.Builder()
            .setAudioPlaybackCaptureConfig(cfg)
            .setAudioFormat(AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(48000).setChannelMask(AudioFormat.CHANNEL_IN_STEREO).build())
            .build()
        loop()
    }

    private fun loop() {
        nativeInit(); running = true
        Thread {
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_AUDIO)
            recorder?.startRecording()
            val buf = ShortArray(2048)
            while (running) { val n = recorder?.read(buf, 0, buf.size) ?: break; if (n > 0) nativeFeed(buf, n) }
            recorder?.stop(); recorder?.release(); nativeStop()
        }.start()
    }

    override fun onDestroy() { running = false; projection?.stop(); super.onDestroy() }
    override fun onBind(i: Intent?) = null as IBinder?

    private fun createChannel() = getSystemService(NotificationManager::class.java)
        .createNotificationChannel(NotificationChannel("ss","SoundSpace Engine",NotificationManager.IMPORTANCE_LOW))

    private fun notif() = NotificationCompat.Builder(this,"ss")
        .setContentTitle("SoundSpace Active").setContentText("Spatializing audio…")
        .setSmallIcon(android.R.drawable.ic_media_play).setOngoing(true).build()
}
