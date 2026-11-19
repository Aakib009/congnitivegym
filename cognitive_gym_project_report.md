# Comprehensive Project Report: Cognitive Gym

## Executive Summary

**Cognitive Gym** (`cognitive_gym`) is a cross-platform, gamified cognitive enhancement application built with **Flutter 3.x** and **Dart 3.12+**. The platform provides interactive exercises designed to improve critical thinking, observational acuity, narrative creativity, decision-making, and argumentative debate skills.

---

## 1. Project Overview & Architecture

- **Project Name**: `cognitive_gym`
- **Platform Compatibility**: Web, Windows (Desktop), macOS, Linux, Android, iOS.
- **UI Architecture**: Material 3 Design System with dark/light mode toggle support and custom color palettes (`AppColors`).
- **Routing Engine**: `go_router` (v17.3.0) featuring `StatefulShellRoute.indexedStack` for seamless bottom-navigation bar state preservation across main tabs.

---

## 2. Core Interactive Modules

### 2.1 Debate Arena (`/debate-arena`, `/debate-chat`)
- **Purpose**: AI-assisted critical thinking and formal argument simulator.
- **AI Integration**: Powered by `OpenRouterService` connecting to LLM models via REST API.
- **Features**:
  - Selection of debate topics (`DebateTopic`) with custom difficulty levels.
  - Interactive multi-turn chat interface (`DebateChatScreen`).
  - Post-debate AI feedback and reflection modal (`DebateReflectionDialog`).

### 2.2 Story Builder (`/story-builder`)
- **Purpose**: Enhances creative writing, vocabulary expansion, and structural logic.
- **Features**:
  - Random word prompt generation (`WordGeneratorService`).
  - Text-to-Speech (TTS) narration (`TtsService`).
  - Story saving and progression tracking (`StoryStorageService`).

### 2.3 Observation Challenge (`/observation-challenge`)
- **Purpose**: Trains visual memory, spatial perception, and detail recognition.
- **Features**:
  - Interactive visual scenes with custom canvas painting (`ObservationScenePainter`).
  - Timed observation rounds and detail-recall questions.

### 2.4 Scenario Lab (`/scenario-lab`)
- **Purpose**: Simulates complex ethical, tactical, and logical decision scenarios.
- **Features**:
  - Multi-choice branching story scenarios with score evaluations (`ScenarioLabService`).

### 2.5 Mind Tree Exercise (`/mind-tree-exercise`)
- **Purpose**: Visual representation of mental skill trees and cognitive growth.
- **Features**:
  - Custom canvas rendering (`MindTreeWidget`) showing branching skill nodes unlocking as XP is gained.

### 2.6 Cognitive Journal (`/journal`)
- **Purpose**: Personal logging space for reflections, past performance metrics, and exercise history.

---

## 3. Gamification & User Progression Engine

- **XP & Level System (`PointService`, `RewardManager`)**: Earn experience points for completing exercises.
- **Streaks (`StreakService`)**: Daily active usage tracking to build consistent cognitive training habits.
- **Achievements (`AchievementService`)**: Unlock badges for milestones (e.g., first debate won, 5-day streak, 10 stories written).
- **Celebration Effects (`ConfettiCelebration`, `SoundService`)**: Audio cues and visual confetti celebrations on level ups and milestone completions.
- **User Profiles (`UserProfile`, `UserAccount`, `AuthService`)**: Local authentication, profile management, and mascot avatar customization (`RaccoonAvatar`).

---

## 4. Technical Stack & Key Dependencies

| Component | Library / Package | Description |
| :--- | :--- | :--- |
| **Framework** | `flutter` | Core UI and cross-platform runtime |
| **Language** | `dart` (^3.12.0) | Application programming language |
| **Navigation** | `go_router` (^17.3.0) | Declarative routing system |
| **Database** | `sqflite_common_ffi` (^2.3.2) | SQLite local database engine |
| **Key-Value Store** | `shared_preferences` (^2.5.2) | Persists user settings, theme preferences, and streaks |
| **AI API** | `http` (^1.2.0) | HTTP client for OpenRouter API requests |
| **Audio** | `audioplayers` (^6.0.0) | Sound effect playback for gamification |
| **Text-To-Speech** | `flutter_tts` (^4.2.0) | Text-to-Speech audio output |
| **Typography** | `google_fonts` (^8.2.0) | Modern typography styling |

---

## 5. File Structure Summary

```
c:\Cognitive-Gym-main\
├── android/            # Android platform files
├── ios/                # iOS platform files
├── web/                # Web platform files
├── windows/            # Windows desktop platform files
├── assets/             # Images, icons, scenario assets
│   ├── icons/
│   └── images/
├── lib/
│   ├── main.dart       # Application entrypoint & service initialization
│   ├── constants/      # Reward & game constants
│   ├── models/         # Data models (Debate, Story, Scenario, User, etc.)
│   ├── routes/         # AppRouter and route definitions
│   ├── screens/        # 14 UI screens for features and auth
│   ├── services/       # 18 singleton services (AI, DB, Auth, Gamification, Sound)
│   ├── utils/          # Colors, themes, constants
│   └── widgets/        # Reusable UI widgets, dialogs, custom painters
└── pubspec.yaml        # Flutter project configuration & dependencies
```

---

## 6. Execution & Runtime Options

1. **Web Mode**: Run `flutter run -d web-server --web-port 8080` (accessible at `http://127.0.0.1:8080`).
2. **Desktop Mode**: Run `flutter run -d windows` for native desktop performance.
3. **Mobile Mode**: Run `flutter run -d chrome` or target Android/iOS devices/emulators.
