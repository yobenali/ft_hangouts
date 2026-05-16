package com.example.ft_hangouts

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ft_hangouts/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        FlutterEngineCache.getInstance().put("main_engine", flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Send SMS ──────────────────────────────────
                    "sendSms" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        val message = call.argument<String>("message") ?: ""

                        if (ContextCompat.checkSelfPermission(
                                this, Manifest.permission.SEND_SMS
                            ) == PackageManager.PERMISSION_GRANTED
                        ) {
                            val success = SmsHelper.sendSms(this, phone, message)
                            if (success) result.success("sent")
                            else result.error("SEND_FAILED", "Failed to send SMS", null)
                        } else {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(
                                    Manifest.permission.SEND_SMS,
                                    Manifest.permission.READ_SMS,
                                    Manifest.permission.RECEIVE_SMS
                                ),
                                101
                            )
                            result.error("NO_PERMISSION", "Grant SMS permission and try again", null)
                        }
                    }

                    // ── Read SMS from inbox for a contact ─────────
                    "readSms" -> {
                        val phone = call.argument<String>("phone") ?: ""

                        if (ContextCompat.checkSelfPermission(
                                this, Manifest.permission.READ_SMS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.READ_SMS),
                                102
                            )
                            result.error("NO_PERMISSION", "Read SMS permission not granted", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val messages = mutableListOf<Map<String, Any>>()
                            // ── Read RECEIVED messages (inbox) ────
                            val inboxUri = Uri.parse("content://sms/inbox")

                            // Clean phone number — remove spaces, dashes
                            val cleanPhone = phone.replace(" ", "").replace("-", "")

                            // Try both formats: with and without country code
                            val localPhone = if (cleanPhone.startsWith("+212")) 
                                "0" + cleanPhone.substring(4) 
                                else cleanPhone
                            val intlPhone = if (cleanPhone.startsWith("0")) 
                                "+212" + cleanPhone.substring(1) 
                                else cleanPhone

                            val inboxCursor: Cursor? = contentResolver.query(
                                inboxUri,
                                arrayOf("address", "body", "date"),
                                "address = ? OR address = ? OR address = ?",
                                arrayOf(cleanPhone, localPhone, intlPhone),
                                "date ASC"
                            )
                            // // ── Read RECEIVED messages (inbox) ────
                            // val inboxUri = Uri.parse("content://sms/inbox")
                            // val inboxCursor: Cursor? = contentResolver.query(
                            //     inboxUri,
                            //     arrayOf("address", "body", "date"),
                            //     "address = ?",
                            //     arrayOf(phone),
                            //     "date ASC"
                            // )
                            // inboxCursor?.use { cursor ->
                            //     while (cursor.moveToNext()) {
                            //         val address = cursor.getString(0) ?: ""
                            //         val body = cursor.getString(1) ?: ""
                            //         val date = cursor.getLong(2)
                            //         messages.add(mapOf(
                            //             "address" to address,
                            //             "body" to body,
                            //             "date" to date,
                            //             "isSent" to 0
                            //         ))
                            //     }
                            // }

                            // ── Read SENT messages ─────────────────
                            val sentUri = Uri.parse("content://sms/sent")
                            val sentCursor: Cursor? = contentResolver.query(
                                sentUri,
                                arrayOf("address", "body", "date"),
                                "address = ?",
                                arrayOf(phone),
                                "date ASC"
                            )
                            sentCursor?.use { cursor ->
                                while (cursor.moveToNext()) {
                                    val address = cursor.getString(0) ?: ""
                                    val body = cursor.getString(1) ?: ""
                                    val date = cursor.getLong(2)
                                    messages.add(mapOf(
                                        "address" to address,
                                        "body" to body,
                                        "date" to date,
                                        "isSent" to 1
                                    ))
                                }
                            }

                            // Sort all messages by date
                            val sorted = messages.sortedBy { it["date"] as Long }
                            result.success(sorted)

                        } catch (e: Exception) {
                            result.error("READ_FAILED", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}