// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ft_hangouts';

  @override
  String get contacts => 'Contacts';

  @override
  String get newContact => 'Nouveau contact';

  @override
  String get editContact => 'Modifier le contact';

  @override
  String get save => 'Sauvegarder';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get name => 'Nom';

  @override
  String get phone => 'Téléphone';

  @override
  String get email => 'Email';

  @override
  String get address => 'Adresse';

  @override
  String get note => 'Note';

  @override
  String get noContacts => 'Aucun contact';

  @override
  String get addFirst => 'Appuyez sur + pour ajouter un contact';

  @override
  String get typeMessage => 'Écrire un message...';

  @override
  String get noMessages => 'Aucun message';

  @override
  String get sendFirst => 'Envoyez le premier message !';

  @override
  String lastSeen(String time) {
    return 'Dernière visite : $time';
  }

  @override
  String deleteConfirm(String name) {
    return 'Voulez-vous supprimer $name ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get failedSend => 'Échec d\'envoi — vérifiez les permissions SMS';
}
