package com.example.ft_hangouts

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (sms in messages) {
                val sender = sms.originatingAddress ?: ""
                val body = sms.messageBody ?: ""

                // Send to Flutter via method channel
                val engine = FlutterEngineCache.getInstance().get("main_engine")
                engine?.let {
                    val channel = MethodChannel(
                        it.dartExecutor.binaryMessenger,
                        "com.example.ft_hangouts/sms"
                    )
                    channel.invokeMethod("onSmsReceived", mapOf(
                        "sender" to sender,
                        "body" to body,
                    ))
                }
            }
        }
    }
}