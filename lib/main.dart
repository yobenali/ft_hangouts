import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/sms_service.dart';
import 'database/db_helper.dart';
import 'models/message.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Listen for incoming SMS globally
  SmsService.listenForIncomingSms(
    onMessage: (sender, body) async {
      // Find contact by phone number
      final contacts = await DatabaseHelper.instance.getContacts();
      final match = contacts.where((c) => c.phone == sender).toList();

      if (match.isNotEmpty) {
        // Save received message to DB
        await DatabaseHelper.instance.insertMessage(
          Message(
            contactId: match.first.id!,
            body: body,
            isSent: 0,
            timestamp: DateTime.now().toIso8601String(),
          ),
        );
      }
    },
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ft_hangouts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}