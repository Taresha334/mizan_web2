// filepath: android/app/src/main/kotlin/com/mizan/mizan_web/SmsOutboxWorker.kt
package com.mizan.mizan_web

import android.content.Context
import android.telephony.SmsManager
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

class SmsOutboxWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    private val client = OkHttpClient()
    private val SUPABASE_URL = "https://xztidxvdikyintwiaths.supabase.co/rest/v1"
    private val SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6dGlkeHZkaWt5aW50d2lhdGhzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDEyNjI4NSwiZXhwIjoyMDg1NzAyMjg1fQ.7x-_4Arp_bsbcnZHPO2RqgXpWxB0UPcOWYIIKRiojS4"

    override suspend fun doWork(): Result {
        return try {
            syncUniversalOutbox()
            Result.success()
        } catch (e: Exception) {
            Log.e("MIZAN_GATEWAY", "Critical Worker Failure: ${e.message}")
            Result.retry()
        }
    }

    private fun syncUniversalOutbox() {
        val request = Request.Builder()
            .url("$SUPABASE_URL/sms_outbox?status=eq.pending&select=*")
            .header("apikey", SERVICE_KEY)
            .header("Authorization", "Bearer $SERVICE_KEY")
            .header("Accept", "application/json")
            .get()
            .build()

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: "[]"
            if (!response.isSuccessful) {
                Log.e("MIZAN_GATEWAY", "Outbox Sync Fetch Failed (${response.code}): $responseBody")
                return
            }
            val data = JSONArray(responseBody)
            for (i in 0 until data.length()) {
                processAndDispatch(data.getJSONObject(i))
            }
        }
    }

    private fun processAndDispatch(record: JSONObject) {
        val id = record.getString("id")
        val phone = record.getString("phone")
        val message = record.getString("message")
        
        try {
            val smsManager = applicationContext.getSystemService(SmsManager::class.java)
            smsManager.sendMultipartTextMessage(phone, null, smsManager.divideMessage(message), null, null)
            updateSmsStatus(id, "sent")
        } catch (e: Exception) {
            Log.e("MIZAN_GATEWAY", "Dispatch Error for ID $id: ${e.message}")
            updateSmsStatus(id, "failed")
        }
    }

    private fun updateSmsStatus(id: String, status: String) {
        // Construct clean JSON for status update
        val json = JSONObject()
            .put("status", status)
            .put("processed_at", Instant.now().toString())
            .toString()

        // Protocol Check: Ensure UUID is clean. PostgREST handles 'id=eq.uuid' natively.
        val patchUrl = "$SUPABASE_URL/sms_outbox?id=eq.$id"
        
        val request = Request.Builder()
            .url(patchUrl)
            .patch(json.toRequestBody("application/json".toMediaType()))
            .header("apikey", SERVICE_KEY)
            .header("Authorization", "Bearer $SERVICE_KEY")
            .header("Content-Type", "application/json")
            .header("Prefer", "return=representation")
            .build()
            
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                val errorBody = response.body?.string()
                Log.e("MIZAN_GATEWAY", "Sync Status Update Failed (${response.code}) for ID $id: $errorBody")
            } else {
                Log.i("MIZAN_GATEWAY", "Status updated successfully for ID $id to $status")
            }
        }
    }
}