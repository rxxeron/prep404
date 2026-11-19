# Prep404 • Failure Not Found

Bangladeshi private university admission preparation platform available in two native/cross-platform TypeScript & Dart stacks:
1. **Flutter (Dart)** at the repository root (`/lib`, `/android`, `/web`, `/test`, `/pubspec.yaml`)
2. **React Native + TypeScript** in `/react-native/` (`/react-native/App.tsx`, `/react-native/src/`, `/react-native/package.json`)

## Core Features

- **Authentication & Bilingual Onboarding (`EN` / `বাং`)**:
  - Phone + OTP verification, Guest Preview entry, and 3-step onboarding supporting **Bangla Medium (NCTB Bangla/English Version)** and **English Medium (Cambridge CAIE / Pearson Edexcel)**, cascading Division → District selectors, searchable SSC/HSC/O-Level/A-Level institutions, and multi-university/discipline selection.
- **8 Bangladeshi Private University Tracks & Blueprints**:
  - `NSU`, `BRACU`, `AUST`, `AIUB`, `EWU`, `IUB`, `UIU`, and `UAP` with program-specific section weightages, negative-marking policies, admission cycles, and countdown timers.
- **Hiking Admission Roadmap**:
  - S-curve milestone trail (`10 | 15 | 30 | 60` day horizons) across 4 pillars (`Topic-wise`, `Subject-wise`, `Section-wise`, `Overall`) with XP & completion tracking.
- **Question Bank & FSRS-4.5 Adaptive Practice**:
  - Math & science MCQs (`Higher Math`, `Quant Math`, `Physics`, `Chemistry`, `Biology`, `English`), reading comprehension passages, bookmarks, authored Socratic study hints, question reporting, and FSRS-4.5 spaced-repetition scheduling.
- **Live Model Tests & Software OMR Bubble Sheet Simulator**:
  - Choose **In-App Digital Exam** or **Software OMR Bubble Sheet** (+15m transfer buffer, interactive `(A)(B)(C)(D)` bubbles with question booklet inspector), live timer, navigator grid, negative-marking scorer, confetti Score Card, and reviewed solutions.
- **Daily Ranked Exam Arena & 1v1 Quiz Battle Arena**:
  - 10 AM – 10 PM daily slot countdown with national & university-track leaderboards, plus timed 15s/round 1v1 duels with room codes and zero-spoiler locking.
- **Analytics, Mistake Vault & Study Streaks**:
  - Analytical accuracy breakdown, reviewed exam scripts, deficit-ranked Mistake Vault with 1-click Adaptive Re-Tests, and Study Streak Milestone Ladder.

## Running & Verifying

### 1. Flutter App (Repository Root `/`)

Ensure `.env` exists (copy from `.env.example` and configure optional backend keys):

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d web-server --web-port 3000
```

### 2. React Native + TypeScript App (`/react-native/`)

```bash
cd react-native
npm install
npm run lint      # TypeScript check (tsc --noEmit)
npm run web       # Run React Native in browser preview on http://0.0.0.0:3000
npm start         # Start React Native Metro bundler for native builds
npm run android   # Run on Android
npm run ios       # Run on iOS
```
