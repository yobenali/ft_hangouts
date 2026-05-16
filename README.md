# ft_hangouts

An Android contact and SMS application built with Flutter for the 42 mobile curriculum.

`ft_hangouts` is a compact phonebook app with local contact storage, native Android SMS integration, bilingual UI, lifecycle awareness, and a custom launcher icon. The project focuses on building a real mobile workflow end to end: data modeling, persistence, native platform channels, permissions, localization, responsive layouts, and Android deployment.

## Highlights

- Contact management with create, edit, delete, and list views
- Local persistence with SQLite through `sqflite`
- One-to-one chat view for each contact
- Native SMS sending through a Flutter `MethodChannel`
- SMS history sync from Android inbox and sent messages
- English and French localization
- Background timestamp notification when returning to the app
- Portrait and landscape support with safe-area handling
- Custom Android launcher icon
- No external UI component library

## Why This Project Matters

The goal of the 42 `ft_hangouts` project is not only to make a Flutter screen. It is to connect a Flutter UI to real Android capabilities while keeping the app usable, persistent, and maintainable.

This implementation demonstrates:

- Flutter stateful UI and navigation
- SQLite database design for contacts and messages
- Dart model mapping between objects and database rows
- Native Kotlin integration for SMS features
- Runtime permission handling for Android SMS APIs
- Localized interface strings with generated Flutter l10n files
- App lifecycle handling with `WidgetsBindingObserver`
- Practical mobile debugging on a physical Android device

## Tech Stack

| Area | Technology |
| --- | --- |
| UI | Flutter / Dart |
| Native Android | Kotlin |
| Native bridge | Flutter `MethodChannel` |
| Storage | SQLite with `sqflite` |
| Localization | `flutter_localizations` and `intl` |
| Preferences | `shared_preferences` |
| Permissions | Android SMS permissions |
| Icon generation | `flutter_launcher_icons` |

## Features

### Contacts

Contacts are stored locally in SQLite and include:

- name
- phone number
- email
- address
- note

Users can add new contacts, edit existing contacts, delete contacts, and open a chat screen from the contact list.

### SMS Chat

Each contact has a conversation screen that combines:

- messages saved by the app
- SMS messages read from Android inbox
- SMS messages read from Android sent messages

Sending SMS is handled natively in Kotlin because direct SMS sending is platform-specific. Flutter calls the native layer through:

```dart
MethodChannel('com.example.ft_hangouts/sms')
```

The Kotlin side handles:

- `sendSms`
- `readSms`

### Phone Number Matching

The native SMS reader supports common Moroccan number formats by matching both local and international forms, such as:

```text
06XXXXXXXX
+2126XXXXXXXX
```

This makes SMS history sync more reliable when Android stores a number in a different format than the one saved in the contact.

### Localization

The app supports:

- English
- French

Localization files live in:

```text
lib/l10n/
```

Important import path:

```dart
import 'package:ft_hangouts/l10n/app_localizations.dart';
```

### Background Timestamp

The home screen observes app lifecycle changes.

When the app goes to the background, it saves the current timestamp with `shared_preferences`.

When the app resumes, it shows a styled floating SnackBar:

```text
Last seen: 14:32
```

or in French:

```text
Derniere visite : 14:32
```

### Responsive Layout

The main screens use `SafeArea` so content remains visible in portrait and landscape, including on Android devices with gesture navigation or immersive system bars.

Screens tested:

- Home screen
- Contact form
- Chat screen

## Project Structure

```text
ft_hangouts/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/com/example/ft_hangouts/
│           ├── MainActivity.kt
│           ├── SmsHelper.kt
│           └── SmsReceiver.kt
├── assets/
│   └── launcher_icon.png
├── lib/
│   ├── database/
│   │   └── db_helper.dart
│   ├── l10n/
│   │   ├── app_en.arb
│   │   ├── app_fr.arb
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   └── app_localizations_fr.dart
│   ├── models/
│   │   ├── contact.dart
│   │   └── message.dart
│   ├── screens/
│   │   ├── chat_screen.dart
│   │   ├── contact_form.dart
│   │   └── home_screen.dart
│   ├── services/
│   │   └── sms_service.dart
│   └── main.dart
├── l10n.yaml
├── pubspec.yaml
└── pubspec.lock
```

## Data Model

### Contact

```text
id      INTEGER PRIMARY KEY
name    TEXT NOT NULL
phone   TEXT NOT NULL
email   TEXT
address TEXT
note    TEXT
```

### Message

```text
id         INTEGER PRIMARY KEY
contact_id INTEGER NOT NULL
body       TEXT NOT NULL
is_sent    INTEGER NOT NULL
timestamp  TEXT NOT NULL
```

## Android Permissions

The app uses Android SMS permissions:

```xml
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_SMS"/>
```

On some Android distributions, especially MIUI, SMS broadcast receiving may be limited if the app is not the default SMS app. To make the project practical on a real Xiaomi device, the chat screen also reads messages directly from:

```text
content://sms/inbox
content://sms/sent
```

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Generate localization files if needed:

```bash
flutter gen-l10n
```

Regenerate Android launcher icons if `assets/launcher_icon.png` changes:

```bash
dart run flutter_launcher_icons
```

If Android keeps showing an old launcher icon:

```bash
adb uninstall com.example.ft_hangouts
flutter run
```

If `adb` does not find the phone, check the connected device first:

```bash
adb devices
```

## Testing Checklist

- Add a contact
- Edit a contact
- Delete a contact
- Open a contact chat
- Send an SMS
- Reopen chat and verify message history
- Rotate the phone on every screen
- Send the app to background, reopen it, and confirm the last-seen toast appears
- Switch device language between English and French
- Confirm Android launcher icon displays correctly

## Notes for Reviewers

This repository is intentionally focused on the Android target for the 42 subject. Generated Flutter folders and unused desktop/web platform folders are ignored to keep the submission small and relevant.

The app was developed and tested on a physical Xiaomi Android phone using WiFi ADB, because emulator support was not available in the development environment.

## Possible Improvements

- Add contact profile pictures
- Add a direct call action
- Improve validation messages with full localization
- Add automated tests around database mapping
- Add SMS import conflict handling for edge cases
- Add search and sorting for larger contact lists

## Context

Built as part of the 42 mobile module.
