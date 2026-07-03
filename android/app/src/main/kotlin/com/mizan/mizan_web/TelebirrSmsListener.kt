// filepath: android/app/src/main/kotlin/com/mizan/mizan_web/TelebirrSmsListener.kt
package com.mizan.mizan_web

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import kotlin.concurrent.thread

class TelebirrSmsListener : BroadcastReceiver() {
    private val client = OkHttpClient()
    private val SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6dGlkeHZkaWt5aW50d2lhdGhzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDEyNjI4NSwiZXhwIjoyMDg1NzAyMjg1fQ.7x-_4Arp_bsbcnZHPO2RqgXpWxB0UPcOWYIIKRiojS4"
    private val URL = "https://xztidxvdikyintwiaths.supabase.co/rest/v1/telebirr_sentinel"

    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        thread {
            try {
                val msgs = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return@thread
                val body = msgs.joinToString("") { it.displayMessageBody ?: "" }
                
                val json = JSONObject().apply {
                    put("raw_message", body)
                    put("sender_phone", msgs[0].displayOriginatingAddress ?: "Unknown")
                }

                val request = Request.Builder()
                    .url(URL)
                    .post(json.toString().toRequestBody("application/json".toMediaType()))
                    .header("apikey", SERVICE_KEY)
                    .header("Authorization", "Bearer $SERVICE_KEY")
                    .build()
                
                client.newCall(request).execute().close()
            } finally {
                pendingResult.finish()
            }
        }
    }
}