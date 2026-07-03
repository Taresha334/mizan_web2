// filepath: android/app/src/main/kotlin/com/mizan/mizan_web/MainActivity.kt

package com.mizan.mizan_web

import android.Manifest
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.work.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val ROLE_CHANNEL = "com.mizan.gateway/sms_role"
    private val mainHandler = Handler(Looper.getMainLooper())
    private var fastPollerRunnable: Runnable? = null
    private val SMS_PERMISSION_CODE = 200

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure physical hardware runtime permissions are granted immediately on launch
        checkAndRequestSmsPermissions()

        setupBackgroundSmsWorker()
        startHighFrequencyOutboxPoller()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ROLE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "requestDefaultSmsRole") {
                val status = requestSmsRole()
                if (status == "ALREADY_DEFAULT") {
                    triggerImmediateSmsSync()
                }
                result.success(status)
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Checks runtime conditions and prompts the user to grant hardware transmission access
     */
    private fun checkAndRequestSmsPermissions() {
        val sendSmsPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
        val receiveSmsPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS)
        
        val listPermissionsNeeded = ArrayList<String>()
        if (sendSmsPermission != PackageManager.PERMISSION_GRANTED) {
            listPermissionsNeeded.add(Manifest.permission.SEND_SMS)
        }
        if (receiveSmsPermission != PackageManager.PERMISSION_GRANTED) {
            listPermissionsNeeded.add(Manifest.permission.RECEIVE_SMS)
        }
        
        if (listPermissionsNeeded.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, listPermissionsNeeded.toTypedArray(), SMS_PERMISSION_CODE)
        }
    }

    private fun setupBackgroundSmsWorker() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<SmsOutboxWorker>(15, TimeUnit.MINUTES)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(applicationContext).enqueueUniquePeriodicWork(
            "MizanSmsOutbox",
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
    }

    private fun startHighFrequencyOutboxPoller() {
        fastPollerRunnable = object : Runnable {
            override fun run() {
                triggerImmediateSmsSync()
                mainHandler.postDelayed(this, 10000)
            }
        }
        mainHandler.post(fastPollerRunnable!!)
    }

    private fun triggerImmediateSmsSync() {
        val instantRequest = OneTimeWorkRequestBuilder<SmsOutboxWorker>()
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(applicationContext).enqueue(instantRequest)
    }

    private fun requestSmsRole(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            if (roleManager.isRoleHeld(RoleManager.ROLE_SMS)) "ALREADY_DEFAULT"
            else {
                startActivityForResult(roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS), 101)
                "REQUEST_SENT"
            }
        } else {
            val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
            intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
            startActivity(intent)
            "LEGACY_REQUEST_SENT"
        }
    }

    override fun onDestroy() {
        fastPollerRunnable?.let { mainHandler.removeCallbacks(it) }
        super.onDestroy()
    }
}