# Project Specification: Cognitive Gym

**Document Version:** 1.0.0  
**Status:** Active  
**Repository:** `Cognitive-Gym-main`  
**Framework:** Flutter 3.x / Dart 3.12+  
**Platform Targets:** Web, Windows Desktop, macOS, Linux, Android, iOS  

---

## 1. Executive Summary & Vision

**Cognitive Gym** is a cross-platform, gamified cognitive enhancement application engineered to stimulate critical thinking, observational acuity, narrative creativity, ethical/tactical decision-making, and argumentative debate skills.

By merging structured cognitive workouts with playful gamification mechanics—including experience progression (XP), daily streaks, customizable raccoon avatar mascots, celebratory feedback, and an evolving "Mind Tree"—Cognitive Gym turns mental exercises into a rewarding daily habit.

---

## 2. Core Pillars & Principles

1. **Objective, In-App Performance Metrics**  
   All scoring is strictly deterministic and based on actual user interactions (e.g., word integration, observational accuracy, deliberation time, debate engagement). Cognitive Gym does **not** make clinical or medical diagnostic claims.

2. **Engaging Gamification Feedback Loop**  
   Every workout yields measurable progress: XP, skill tier enhancements, daily streak continuity, level-up celebrations (audio cues + confetti), and visual growth of the user's personal Mind Tree.

3. **Privacy-Preserving & Local-First Architecture**  
   User profiles, exercise logs, analytics, and credentials are encrypted and stored locally via SQLite (`sqflite_common_ffi` on desktop/mobile and web-ffi). No personally identifiable information is transmitted externally except LLM prompt context sent to OpenRouter.

4. **Multi-Platform Fluidity & Material 3 Design**  
   Adaptive layouts optimized for both desktop/tablet wide viewports and mobile phone aspect ratios, supporting custom dark/light palettes (`AppColors` & `AppTheme`) and seamless state-preserving navigation via `GoRouter`.

5. **AI-Assisted Interactive Training**  
   Debate Arena leverages LLM completion APIs (via `OpenRouterService`) with robust error handling, offline test mocks, and fallback heuristics to provide an adaptive intellectual sparring partner.

---

## 3. Technology Stack & Key Dependencies

| Layer | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter | 3.x | Cross-platform UI toolkit & engine |
| **Language** | Dart | ^3.12.0 | Core type-safe programming language |
| **Navigation** | `go_router` | ^17.3.0 | Declarative routing with state preservation (`StatefulShellRoute`) |
| **Database** | `sqflite_common_ffi` | ^2.3.2 | Cross-platform SQLite engine for desktop, tests & mobile |
| **Web DB** | `sqflite_common_ffi_web` | ^1.1.2 | SQLite WebAssembly bindings for Web platform |
| **Key-Value Store** | `shared_preferences` | ^2.5.2 | Settings, theme preferences, and streaks |
| **AI Integration** | `http` | ^1.2.0 | REST client for OpenRouter Chat Completions |
| **Visual Charts** | `fl_chart` | ^0.70.2 | Radar charts, XP trend lines, and exercise distribution bar charts |
| **Audio** | `audioplayers` | ^6.0.0 | Sound effects for level-ups and milestone achievements |
| **Speech** | `flutter_tts` | ^4.2.0 | Text-to-Speech narration for Story Builder |
| **Typography** | `google_fonts` | ^8.2.0 | Modern font families (Inter, Roboto) |
| **Security** | `crypto` | ^3.0.7 | Salted SHA-256 password hashing & secure verification |

---

## 4. Architectural Overview

The application follows a clean, decoupled layered architecture:

```
c:\Cognitive-Gym-main\
├── assets/                     # Scenarios, icons, and mascot graphics
├── lib/
│   ├── main.dart               # App entrypoint & async singleton initialization
│   ├── constants/              # Reward tiers, XP thresholds, milestone constants
│   ├── models/                 # Data entities (Debate, Story, Scenario, User, Analytics)
│   ├── routes/                 # AppRouter configuration and authentication guards
│   ├── screens/                # UI screen components (17 dedicated feature screens)
│   ├── services/               # Singleton business logic & reactive ChangeNotifier services
│   ├── utils/                  # Color schemes, themes, password security helpers
│   └── widgets/                # Reusable UI widgets, custom canvas painters, dialogs
└── test/                       # Comprehensive unit and widget test suite (14 test files)
```

### Key Service Singletons (`lib/services/`):
- **`AuthService`**: Manages user registration, login, PBKDF2/SHA-256 salted credentials, session persistence, and reactive auth state.
- **`DatabaseService`**: Manages SQLite connection factory, schema migrations, and table lifecycles.
- **`ProgressService` & `RewardManager`**: Centralized XP accounting, level promotions, achievement verification, and streak increments.
- **`AnalyticsService` & `AnalyticsRepository`**: Collects exercise completion events and produces aggregated metrics.
- **`AdaptiveTrainingService`**: Evaluates rolling performance windows to generate personalized, difficulty-scaled training recommendations.
- **`ExerciseScoringService`**: Deterministic scoring algorithms for all four cognitive activities.
- **`OpenRouterService`**: Communicates with external LLMs for dynamic debate exchanges.
- **`ThemeService`**: Coordinates dark/light Material 3 theme switching.
- **`SoundService` & `TtsService`**: Audio cues and voice synthesis across platforms.

---

## 5. Scope Boundaries

### In Scope (Current & Planned v1.x):
- Four core interactive cognitive modules (Debate Arena, Story Builder, Observation Challenge, Scenario Lab).
- Visual Mind Tree growth engine reflecting user XP across 5 cognitive branches.
- Gamification mechanics: streak counters, level badges, achievement unlocks, sound/confetti celebrations.
- Analytics dashboard: skill radar charts, XP progression graphs, activity breakdowns, and cognitive journal history.
- Adaptive training plan generator delivering daily recommendations.
- Local SQLite database persistence and secure authentication.

### Out of Scope (Explicit Non-Goals):
- Clinical diagnosis or medical cognitive rehabilitation claims.
- Cloud-hosted multi-tenant backend (application is architected as local-first).
- Real-time multiplayer debate matchmaking (AI debate partner is utilized).
