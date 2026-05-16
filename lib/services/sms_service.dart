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
      print('SMS Send Error: ${e.message}');
      return false;
    }
  }

  // Read all SMS from inbox + sent for a specific phone number
  static Future<List<Map<String, dynamic>>> readSms({
    required String phone,
  }) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('readSms', {
        'phone': phone,
      });
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      print('SMS Read Error: ${e.message}');
      return [];
    }
  }
}