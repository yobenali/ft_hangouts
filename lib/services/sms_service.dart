import 'package:flutter/services.dart';

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
      print('SMS Error: ${e.message}');
      return false;
    }
  }

  // Listen for incoming SMS — callback gives sender + body
  static void listenForIncomingSms({
    required Function(String sender, String body) onMessage,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final sender = call.arguments['sender'] as String;
        final body = call.arguments['body'] as String;
        onMessage(sender, body);
      }
    });
  }
}