// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ft_hangouts';

  @override
  String get contacts => 'Contacts';

  @override
  String get newContact => 'New Contact';

  @override
  String get editContact => 'Edit Contact';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get address => 'Address';

  @override
  String get note => 'Note';

  @override
  String get noContacts => 'No contacts yet';

  @override
  String get addFirst => 'Tap + to add your first contact';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get sendFirst => 'Send the first message!';

  @override
  String lastSeen(String time) {
    return 'Last seen: $time';
  }

  @override
  String deleteConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get failedSend => 'Failed to send — check SMS permissions';
}
