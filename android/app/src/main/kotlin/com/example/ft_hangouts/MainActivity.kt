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
                                this, arrayOf(Manifest.permission.READ_SMS), 102
                            )
                            result.error("NO_PERMISSION", "Read SMS permission not granted", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val messages = mutableListOf<Map<String, Any>>()

                            // Build all possible formats of this number
                            val clean = phone.trim().replace(" ", "").replace("-", "")
                            val variants = mutableSetOf<String>()
                            variants.add(clean)

                            // +212XXXXXXXXX → 0XXXXXXXXX
                            if (clean.startsWith("+212")) {
                                variants.add("0" + clean.substring(4))
                            }
                            // 06XXXXXXXX or 07XXXXXXXX → +212 6XXXXXXXX or +212 7XXXXXXXX
                            if (clean.startsWith("0") && clean.length >= 9) {
                                variants.add("+212" + clean.substring(1))
                                variants.add("+212 " + clean.substring(1))
                            }
                            // Also try without leading zero: 6XXXXXXXX
                            if (clean.startsWith("0")) {
                                variants.add(clean.substring(1))
                            }

                            val placeholders = variants.joinToString(" OR ") { "address = ?" }
                            val args = variants.toTypedArray()

                            val inboxCursor: Cursor? = contentResolver.query(
                                Uri.parse("content://sms/inbox"),
                                arrayOf("address", "body", "date"),
                                placeholders,
                                args,
                                "date ASC"
                            )
                            inboxCursor?.use { cursor ->
                                while (cursor.moveToNext()) {
                                    messages.add(mapOf(
                                        "address" to (cursor.getString(0) ?: ""),
                                        "body" to (cursor.getString(1) ?: ""),
                                        "date" to cursor.getLong(2),
                                        "isSent" to 0
                                    ))
                                }
                            }

                            val sentCursor: Cursor? = contentResolver.query(
                                Uri.parse("content://sms/sent"),
                                arrayOf("address", "body", "date"),
                                placeholders,
                                args,
                                "date ASC"
                            )
                            sentCursor?.use { cursor ->
                                while (cursor.moveToNext()) {
                                    messages.add(mapOf(
                                        "address" to (cursor.getString(0) ?: ""),
                                        "body" to (cursor.getString(1) ?: ""),
                                        "date" to cursor.getLong(2),
                                        "isSent" to 1
                                    ))
                                }
                            }

                            result.success(messages.sortedBy { it["date"] as Long })
                        } catch (e: Exception) {
                            result.error("READ_FAILED", e.message, null)
                        }
                    }
                    "readAllInbox" -> {
                        if (ContextCompat.checkSelfPermission(
                                this, Manifest.permission.READ_SMS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error("NO_PERMISSION", "Read SMS permission not granted", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val messages = mutableListOf<Map<String, Any>>()
                            val inboxCursor: Cursor? = contentResolver.query(
                                Uri.parse("content://sms/inbox"),
                                arrayOf("address", "body", "date"),
                                null, null,
                                "date DESC"
                            )
                            inboxCursor?.use { cursor ->
                                // Only read last 100 messages to avoid performance issues
                                var count = 0
                                while (cursor.moveToNext() && count < 100) {
                                    messages.add(mapOf(
                                        "address" to (cursor.getString(0) ?: ""),
                                        "body" to (cursor.getString(1) ?: ""),
                                        "date" to cursor.getLong(2),
                                        "isSent" to 0
                                    ))
                                    count++
                                }
                            }
                            result.success(messages)
                        } catch (e: Exception) {
                            result.error("READ_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}