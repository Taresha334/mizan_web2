package com.mizan.mizan_web

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * MIZAN GATEWAY - MMS COMPONENT
 * Mandatory for Default SMS App Role eligibility on SM A266M
 */
class MmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // MMS processing is currently suppressed by Mizan Gateway protocol
    }
}