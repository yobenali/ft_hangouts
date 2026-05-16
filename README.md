# ft_hangouts

An Android contact and SMS application built with Flutter for the 42 mobile curriculum.

`ft_hangouts` is a mobile contact and messaging app focused on real Android features such as local persistence, SMS handling, localization, permissions, responsive layouts, and Flutter/native integration.

The project was developed and tested on a physical Android device using Flutter and Kotlin.

---

## Features

- Create, edit, delete, and list contacts
- Local SQLite persistence with `sqflite`
- One-to-one chat screen for each contact
- Native Android SMS sending through `MethodChannel`
- SMS history synchronization from Android inbox and sent messages
- English and French localization
- Background timestamp notification when returning to the app
- Portrait and landscape support
- Custom Android launcher icon
- No external UI component library

---

## What I Learned

This project was my first deeper experience with Flutter mobile development and Android native integration.

The most challenging parts were:

- handling Android SMS permissions correctly
- integrating Flutter with Kotlin using `MethodChannel`
- reading SMS history reliably on MIUI/Xiaomi devices
- managing app lifecycle events
- keeping the UI responsive in both portrait and landscape

The project also helped me better understand:

- SQLite persistence
- Flutter localization
- Android runtime permissions
- stateful widget lifecycle
- debugging on a physical Android device

---

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

---

## Features Overview

### Contacts

Contacts are stored locally in SQLite and include:

- name
- phone number
- email
- address
- note

Users can:

- add contacts
- edit contacts
- delete contacts
- open a dedicated chat screen

---

### SMS Chat

Each contact has a conversation screen that combines:

- messages saved by the app
- SMS messages read from Android inbox
- SMS messages read from Android sent messages

SMS sending is handled natively in Kotlin through a Flutter `MethodChannel`.

```dart
MethodChannel('com.example.ft_hangouts/sms')
```

The Kotlin layer handles:

- `sendSms`
- `readSms`

---

### Phone Number Matching

The native SMS reader supports common Moroccan number formats by matching both local and international forms:

```text
06XXXXXXXX
+2126XXXXXXXX
```

This helps Android SMS history synchronize correctly even when numbers are stored differently.

---

## Challenges

One challenge during development was SMS synchronization on Xiaomi/MIUI devices.

Some Android distributions restrict SMS broadcast behavior for non-default SMS applications.

To make message history more reliable, the app reads messages directly from:

```text
content://sms/inbox
content://sms/sent
```

and merges them inside the Flutter chat screen.

Another challenge was testing without a working Android emulator because KVM acceleration was unavailable on the development machine. The entire project was developed and debugged on a physical Xiaomi Android device through WiFi ADB.

---

## Localization

The app supports:

- English
- French

Localization files are located in:

```text
lib/l10n/
```

Important Flutter localization import:

```dart
import 'package:ft_hangouts/l10n/app_localizations.dart';
```

---

## Background Timestamp

The home screen observes app lifecycle changes using:

```dart
WidgetsBindingObserver
```

When the app goes to the background, the current timestamp is saved with `shared_preferences`.

When the app resumes, the user receives a floating SnackBar:

```text
Last seen: 14:32
```

or in French:

```text
Dernière visite : 14:32
```

---

## Responsive Layout

The application supports both portrait and landscape orientations.

Main screens use `SafeArea` to keep content visible on Android devices with gesture navigation and immersive system bars.

Tested screens:

- Home screen
- Contact form
- Chat screen

---

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

---

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

---

## Android Permissions

The app uses Android SMS permissions:

```xml
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_SMS"/>
```

Runtime permissions are requested directly inside the Android native layer before SMS operations are executed.

---

## Screenshots

Add screenshots here after finishing the UI:

```text
screenshots/home.png
screenshots/chat.png
screenshots/contact_form.png
```

Example section:

```md
| Home | Chat | Contact Form |
|---|---|---|
| ![](screenshots/home.png) | ![](screenshots/chat.png) | ![](screenshots/contact_form.png) |
```

---

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Generate localization files:

```bash
flutter gen-l10n
```

Regenerate launcher icons after changing the icon asset:

```bash
dart run flutter_launcher_icons
```

If Android still displays an old launcher icon:

```bash
adb uninstall com.example.ft_hangouts
flutter run
```

Verify connected Android devices:

```bash
adb devices
```

---

## Testing Checklist

- Add a contact
- Edit a contact
- Delete a contact
- Open a contact chat
- Send an SMS
- Verify SMS history synchronization
- Rotate the device on every screen
- Send the app to the background and reopen it
- Verify the last-seen SnackBar appears
- Switch between English and French
- Verify launcher icon generation

---

## Notes

This repository mainly targets Android because the original 42 subject focuses on Android mobile development.

Generated Flutter folders and unused desktop/web targets are intentionally excluded to keep the repository smaller and focused on the mobile implementation.

The project was developed and tested on a physical Xiaomi Android phone using WiFi ADB.

---

## Possible Improvements

- Contact profile pictures
- Direct call action
- Search and sorting
- Improved validation feedback
- Automated database tests
- Better SMS conflict handling
- UI animations and Material polish

---

## Context

Built as part of the 42 mobile module.