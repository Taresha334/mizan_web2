package com.mizan.mizan_web

import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import androidx.work.*
import java.util.concurrent.TimeUnit

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Check for both standard and HTC/Samsung fastboot actions
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            // Schedule the 15-minute polling
            val workRequest = PeriodicWorkRequestBuilder<SmsOutboxWorker>(15, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .build()
            
            // Re-register the unique work with the KEEP policy
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                "MizanSmsOutbox",
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest
            )
        }
    }
}