import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/contact.dart';
import '../models/message.dart';

class SmsService {
  static const _channel = MethodChannel('com.example.ft_hangouts/sms');

  // Send SMS
  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    try {
      final result = await _channel.invokeMethod('sendSms', {
        'phone': phone,
        'message': message,
      });
      return result == 'sent';
    } on PlatformException catch (e) {
      debugPrint('SMS Send Error: ${e.message}');
      return false;
    }
  }

  // Read SMS from inbox for a specific phone number
  static Future<List<Map<String, dynamic>>> readSms({
    required String phone,
  }) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('readSms', {
        'phone': phone,
      });
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      debugPrint('SMS Read Error: ${e.message}');
      return [];
    }
  }

  // Read ALL inbox messages — used for auto-contact creation
  static Future<List<Map<String, dynamic>>> readAllInbox() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('readAllInbox');
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      debugPrint('SMS ReadAll Error: ${e.message}');
      return [];
    }
  }

  // Check inbox for unknown senders and auto-create contacts
  static Future<void> autoCreateContactsFromInbox() async {
    final allMessages = await readAllInbox();

    for (final sms in allMessages) {
      final sender = sms['address'] as String? ?? '';
      if (sender.isEmpty) continue;

      // Check if contact exists
      Contact? contact =
          await DatabaseHelper.instance.findContactByPhone(sender);

      // Not found — create a new contact with number as name
      if (contact == null) {
        final newId = await DatabaseHelper.instance.insertContact(
          Contact(
            name: sender,   // use phone number as name
            phone: sender,
          ),
        );
        contact = Contact(id: newId, name: sender, phone: sender);
        debugPrint('Auto-created contact for: $sender');
      }

      // Save the message if not already saved
      final body = sms['body'] as String? ?? '';
      final date = sms['date'] as int? ?? 0;
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(date).toIso8601String();

      final exists = await DatabaseHelper.instance.messageExists(
        contactId: contact.id!,
        body: body,
        isSent: 0,
        timestamp: timestamp,
      );

      if (!exists) {
        await DatabaseHelper.instance.insertMessage(
          Message(
            contactId: contact.id!,
            body: body,
            isSent: 0,
            timestamp: timestamp,
          ),
        );
      }
    }
  }
}