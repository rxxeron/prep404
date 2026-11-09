# Prep404 Mobile & Web Application

The official cross-platform learner application for **Prep404 • Failure Not Found** (Bangladeshi University Admission Preparation).

## Features
- **Software OMR Sheet & Timed Exams**: Exact real-world physical exam simulation with authentic 4-bubble OMR sheets, negative marking (-0.25), and live timer pills.
- **Dynamic Question Banking & Explanations**: Rich mathematical expressions rendered with KaTeX, categorized by university tracks (BRACU, NSU, IBA, BUP, etc.).
- **1v1 Real-Time Duel Arena**: Live head-to-head multiplayer battles powered by WebSocket and Redis Pub/Sub.
- **Syllabus Roadmap & Hiking Trails**: Step-by-step topic mastery with progress tracking and summit gates.
- **Athena Analytics & Mistake Vault**: Individual deficit impact calculation and automated weak topic re-tests.
- **Bilingual Experience**: Instant switching between Bengali and English.

## Tech Stack
- **Framework**: Flutter 3 (Dart 3)
- **Platforms**: Android, Web, iOS
- **State Management**: Riverpod (StateNotifier / AsyncNotifier)
- **Networking**: Dio / HTTP, WebSocket (`web_socket_channel`)
- **Backend/Auth**: Supabase Auth, Firebase Cloud Messaging (FCM)

## Getting Started

### 1. Prerequisites
- Flutter SDK 3.24+
- Dart SDK 3.5+
- Android Studio / VS Code with Flutter extension

### 2. Setup
```bash
flutter pub get
```

### 3. Environment
Ensure `.env` exists in this folder (copy from `.env.example`).

### 4. Run Application
```bash
# Run on connected Android device/emulator
flutter run

# Run on Web (Chrome)
flutter run -d chrome
```
