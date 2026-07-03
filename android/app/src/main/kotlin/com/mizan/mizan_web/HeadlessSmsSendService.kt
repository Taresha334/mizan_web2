package com.mizan.mizan_web

import android.app.Service
import android.content.Intent
import android.os.IBinder

/**
 * MIZAN GATEWAY - HEADLESS SMS SERVICE
 * Required by Android 16 to handle 'Quick Reply' intents from the system UI
 */
class HeadlessSmsSendService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_NOT_STICKY
    }
}