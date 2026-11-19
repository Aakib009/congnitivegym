# Project Requirements & Traceability Matrix

**Project:** Cognitive Gym  
**Status:** 100% Implemented & Verified (Release Ready)  
**Last Updated:** 2026-10-24  

---

## 1. Traceability Summary

| Category | Total Requirements | Implemented & Verified | In Progress / Hardening | Future Enhancements |
| :--- | :---: | :---: | :---: | :---: |
| **Architecture & Navigation** | 4 | 4 | 0 | 0 |
| **Authentication & Security** | 5 | 5 | 0 | 0 |
| **Debate Arena** | 5 | 5 | 0 | 0 |
| **Story Builder** | 5 | 5 | 0 | 0 |
| **Observation Challenge** | 5 | 5 | 0 | 0 |
| **Scenario Lab** | 5 | 5 | 0 | 0 |
| **Mind Tree Retirement & Mastery** | 4 | 4 | 0 | 0 |
| **Gamification & Rank Engine** | 9 | 9 | 0 | 0 |
| **Theme System & Tokens** | 3 | 3 | 0 | 0 |
| **Dashboard Experience** | 4 | 4 | 0 | 0 |
| **Design Specification & Responsive Layout** | 3 | 3 | 0 | 0 |
| **Analytics & Adaptive Training** | 5 | 5 | 0 | 0 |
| **Multi-Platform & Reliability** | 4 | 4 | 0 | 0 |
| **Total** | **61** | **61** | **0** | **0** |

---

## 2. Requirement Details & Implementation Mapping

### 2.1 Architecture & Navigation
- **`REQ-ARCH-01`**: Modern Material 3 UI theme with dynamic Dark Mode & Light Mode support.
  - *Status*: Implemented & Verified
  - *Source*: `lib/utils/app_theme.dart`, `lib/utils/app_colors.dart`, `lib/services/theme_service.dart`
- **`REQ-ARCH-02`**: Declarative routing with tab state preservation across primary destinations.
  - *Status*: Implemented & Verified
  - *Source*: `lib/routes/app_router.dart`, `lib/widgets/scaffold_with_nav_bar.dart` (`StatefulShellRoute.indexedStack`)
- **`REQ-ARCH-03`**: Reactive service architecture using Flutter `ChangeNotifier` and `ListenableBuilder`.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/progress_service.dart`, `lib/services/auth_service.dart`, `lib/main.dart`
- **`REQ-ARCH-04`**: Graceful startup error handling with dedicated fallback screen.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/startup_error_screen.dart`, `lib/main.dart`

---

### 2.2 Authentication & Security
- **`REQ-AUTH-01`**: Local user registration with validation (username, email, password strength).
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/sign_up_screen.dart`, `lib/services/auth_service.dart`
  - *Tests*: `test/auth_service_test.dart`
- **`REQ-AUTH-02`**: Cryptographic salted PBKDF2-HMAC-SHA256 password hashing.
  - *Status*: Implemented & Verified
  - *Source*: `lib/utils/password_security.dart`, `lib/services/auth_service.dart`
- **`REQ-AUTH-03`**: Persistent user login state via local SQLite and shared preferences.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/auth_service.dart`, `lib/services/database_service.dart`
- **`REQ-AUTH-04`**: Route guards redirecting unauthenticated users to `/login`.
  - *Status*: Implemented & Verified
  - *Source*: `lib/routes/app_router.dart` (`getRedirectForLocation`)
- **`REQ-AUTH-05`**: Secure logout routine resetting session state and in-memory caches.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/auth_service.dart`, `lib/services/adaptive_training_service.dart`

---

### 2.3 Debate Arena
- **`REQ-DEBATE-01`**: Curated list of philosophical, ethical, and societal debate topics with difficulty tiers.
  - *Status*: Implemented & Verified
  - *Source*: `lib/models/debate_topic.dart`, `lib/screens/debate_arena_screen.dart`
- **`REQ-DEBATE-02`**: User side selection (Support vs Oppose) with AI dynamically adopting the opposing stance.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/debate_chat_screen.dart`, `lib/services/open_router_service.dart`
- **`REQ-DEBATE-03`**: Real-time conversational AI integration via OpenRouter REST API with structured debate persona.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/open_router_service.dart`
- **`REQ-DEBATE-04`**: Turn tracking (5-turn limit) with end-of-round automated debate scoring.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/debate_chat_screen.dart`, `lib/services/exercise_scoring_service.dart`
  - *Tests*: `test/debate_arena_test.dart`
- **`REQ-DEBATE-05`**: Post-debate reflection dialog showing argument analysis and XP rewards.
  - *Status*: Implemented & Verified
  - *Source*: `lib/widgets/debate_reflection_dialog.dart`

---

### 2.4 Story Builder
- **`REQ-STORY-01`**: Dynamic word prompt generator supplying required keywords to incorporate.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/word_generator_service.dart`, `lib/screens/story_builder_screen.dart`
- **`REQ-STORY-02`**: Real-time validation of required keyword inclusion in user draft.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/story_builder_screen.dart`, `lib/services/exercise_scoring_service.dart`
  - *Tests*: `test/story_builder_test.dart`
- **`REQ-STORY-03`**: Deterministic scoring based on target word count, vocabulary diversity, and keyword integration.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/exercise_scoring_service.dart`
  - *Tests*: `test/exercise_scoring_service_test.dart`
- **`REQ-STORY-04`**: Text-to-Speech (TTS) audio playback of drafted stories.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/tts_service.dart`
- **`REQ-STORY-05`**: Local SQLite persistence of completed stories with timestamps and scores.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/story_storage_service.dart`, `lib/models/story_model.dart`

---

### 2.5 Observation Challenge
- **`REQ-OBS-01`**: Interactive visual scene rendered via custom canvas painter (`ObservationScenePainter`).
  - *Status*: Implemented & Verified
  - *Source*: `lib/widgets/observation_scene_painter.dart`, `lib/screens/observation_challenge_screen.dart`
- **`REQ-OBS-02`**: Timed observation phase with difficulty-graded countdown clocks (Easy, Medium, Hard).
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/observation_challenge_screen.dart`, `lib/services/observation_challenge_service.dart`
- **`REQ-OBS-03`**: Multiple-choice recall assessment evaluating specific scene details.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/observation_challenge_screen.dart`, `lib/models/observation_challenge.dart`
  - *Tests*: `test/observation_challenge_test.dart`
- **`REQ-OBS-04`**: Objective scoring factoring difficulty bonus, correct answer ratios, and zero speed penalty.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/exercise_scoring_service.dart`
  - *Tests*: `test/exercise_scoring_service_test.dart`
- **`REQ-OBS-05`**: Challenge completion summary displaying XP gains and cognitive skill impact.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/observation_challenge_screen.dart`, `lib/services/reward_manager.dart`

---

### 2.6 Scenario Lab
- **`REQ-SCENARIO-01`**: Rich repository of branching decision dilemmas covering ethics, crisis management, and resource allocation.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/scenario_lab_service.dart`, `lib/models/scenario_model.dart`
- **`REQ-SCENARIO-02`**: Deliberation time tracking calibrated against estimated reading duration (200 wpm).
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/scenario_lab_screen.dart`, `lib/services/exercise_scoring_service.dart`
- **`REQ-SCENARIO-03`**: Penalty for rushed snap decisions while protecting slow readers from penalties.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/exercise_scoring_service.dart`
  - *Tests*: `test/exercise_scoring_service_test.dart`
- **`REQ-SCENARIO-04`**: Consequence and reflection modal after choice confirmation.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/scenario_lab_screen.dart`
- **`REQ-SCENARIO-05`**: Decision-making skill XP distribution and journal event logging.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/reward_manager.dart`, `lib/services/analytics_service.dart`

---

### 2.7 Mind Tree Retirement & Domain Mastery
- **`REQ-MINDTREE-01`**: Retirement of user-facing tree growth screens, tree stages, and botanical dashboard cards.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/home_screen.dart`, `lib/widgets/app_drawer.dart`, `lib/routes/app_router.dart`
- **`REQ-MINDTREE-02`**: 5 discrete cognitive domain mastery trackers preserved internally:
  - Logic (Debate Arena)
  - Creativity (Story Builder)
  - Observation (Observation Challenge)
  - Decision Making (Scenario Lab)
  - Knowledge / General XP
  - *Status*: Implemented & Verified
  - *Source*: `lib/models/user_profile.dart`, `lib/models/mind_tree_level_config.dart`, `lib/services/mind_tree_service.dart`
  - *Tests*: `test/mind_tree_service_test.dart`
- **`REQ-MINDTREE-03`**: Replacement of botanical avatar titles (e.g. "Forest Sage") with competitive rank designations.
  - *Status*: Implemented & Verified
  - *Source*: `lib/models/user_profile.dart`, `lib/widgets/level_up_dialog.dart`
- **`REQ-MINDTREE-04`**: Clean route redirection of `/mind-tree-exercise` to Home Screen without crashes or dead ends.
  - *Status*: Implemented & Verified
  - *Source*: `lib/routes/app_router.dart`

---

### 2.8 Gamification & Rank Engine
- **`REQ-GAME-01`**: Global XP accounting and tiered level promotion mechanism.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/point_service.dart`, `lib/services/reward_manager.dart`
  - *Tests*: `test/reward_manager_test.dart`, `test/progress_service_test.dart`
- **`REQ-GAME-02`**: Daily active streak tracking with calendar day delta calculations.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/streak_service.dart`
- **`REQ-GAME-03`**: Achievement badge registry unlocking on specific milestones.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/achievement_service.dart`
- **`REQ-GAME-04`**: Audio-visual celebrations on rank promotion and milestone achievements.
  - *Status*: Implemented & Verified
  - *Source*: `lib/widgets/level_up_dialog.dart`, `lib/services/sound_service.dart`
- **`REQ-GAME-05`**: Customizable Raccoon mascot avatar with unlocking accessory gear.
  - *Status*: Implemented & Verified
  - *Source*: `lib/widgets/raccoon_avatar.dart`, `lib/screens/account_screen.dart`
- **`REQ-GAME-06`**: Comprehensive user profile displaying statistics, rank badge, and streak flames.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/account_screen.dart`
  - *Tests*: `test/account_screen_test.dart`
- **`REQ-GAME-07`**: Service-level idempotency and concurrency guards for activity completion and XP awards.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/progress_service.dart`, `lib/screens/*`
  - *Tests*: `test/progress_service_test.dart`
- **`REQ-GAME-08`**: 8-Tier Competitive Cognitive Rank Ladder (Bronze to Grandmaster) with vector geometric rank emblems (`RankEmblem`) and hero showcase card (`RankArenaCard`).
  - *Status*: Implemented & Verified
  - *Source*: `lib/models/rank_model.dart`, `lib/widgets/rank_emblem.dart`, `lib/widgets/rank_arena_card.dart`
- **`REQ-GAME-09`**: Strict AND rank promotion eligibility requiring XP, Account Level, AND Cognitive Mastery simultaneously.
  - *Status*: Implemented & Verified
  - *Source*: `lib/models/rank_model.dart`, `lib/widgets/rank_arena_card.dart`
  - *Tests*: `test/rank_progression_test.dart` (6 boundary tests proving failure if only 2 of 3 criteria met)

---

### 2.9 Theme System & Tokens
- **`REQ-THEME-01`**: Strict two-theme restriction to Dark and Light modes only.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/theme_service.dart`, `lib/utils/app_theme.dart`, `lib/widgets/app_drawer.dart`
  - *Tests*: `test/theme_migration_test.dart`
- **`REQ-THEME-02`**: Safe migration of legacy preferences ('forest' and 'violet') to 'dark' without modifying unrelated user data.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/theme_service.dart`
  - *Tests*: `test/theme_migration_test.dart`
- **`REQ-THEME-03`**: `design.md` color tokens with restrained page canvas (`#171717`), sidebar (`#151515`), surface cards (`#252525`), raised tracks (`#303030`), inset play regions (`#101010`), subtle borders (`#3A3A3A`), brand lime (`#A7FF4F`), math/creativity yellow (`#FFE000`), memory blue (`#4DB4F5`), puzzle green (`#00C878`), and event orange (`#FF7043`).
  - *Status*: Implemented & Verified
  - *Source*: `lib/utils/app_colors.dart`, `lib/utils/app_theme.dart`
  - *Tests*: `test/design_visual_verification_test.dart`

---

### 2.10 Dashboard Experience
- **`REQ-DASH-01`**: Top player status bar displaying avatar, display name, account level, rank title, and real telemetry stat pills (`${streak}d`, `${focus}%`, `${xp} XP`).
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/home_screen.dart`
- **`REQ-DASH-02`**: Daily challenges progress bar tracking actual user exercise completions across the 4 domains (`completedInCycle / 4`).
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/home_screen.dart`
- **`REQ-DASH-03`**: Horizontal domain category filter tabs (`ALL`, `CREATIVITY`, `OBSERVATION`, `LOGIC`, `DECISION`) filtering challenge cards in real time.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/home_screen.dart`
- **`REQ-DASH-04`**: Compact functional challenge cards for all 4 cognitive modules with direct launch navigation.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/home_screen.dart`

---

### 2.11 Design Specification & Responsive Layout (`design.md`)
- **`REQ-DESIGN-01`**: Responsive navigation shell with persistent desktop sidebar at viewports `width >= 900` and mobile bottom navigation bar at `width < 900`.
  - *Status*: Implemented & Verified
  - *Source*: `lib/widgets/scaffold_with_nav_bar.dart`
  - *Tests*: `test/design_visual_verification_test.dart`
- **`REQ-DESIGN-02`**: Inset dark play regions (`surfaceDeep` `#101010`) in active challenge screens (Story Builder text editor and Scenario Lab narrative panel) for enhanced immersion and visual hierarchy.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/story_builder_screen.dart`, `lib/screens/scenario_lab_screen.dart`
  - *Tests*: `test/design_visual_verification_test.dart`
- **`REQ-DESIGN-03`**: Narrow mobile viewport layout resilience (375x812) with flexible text rows, ellipsis constraints, and zero RenderFlex overflow across all screens.
  - *Status*: Implemented & Verified
  - *Source*: `lib/screens/home_screen.dart`, `lib/widgets/rank_arena_card.dart`, `lib/widgets/scaffold_with_nav_bar.dart`
  - *Tests*: `test/design_visual_verification_test.dart`

---

### 2.12 Analytics & Adaptive Training
- **`REQ-ANALYTICS-01`**: Event-driven analytics pipeline logging all exercise outcomes into SQLite.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/analytics_service.dart`, `lib/services/analytics_repository.dart`
  - *Tests*: `test/analytics_service_test.dart`
- **`REQ-ANALYTICS-02`**: Historical XP trend line chart using `fl_chart`.
  - *Status*: Implemented & Verified
  - *Source*: `lib/widgets/analytics/xp_trend_line_chart.dart`, `lib/screens/analytics_screen.dart`
- **`REQ-ANALYTICS-03`**: 5-axis cognitive skill radar chart visualizing strengths and growth areas.
  - *Status*: Implemented & Verified
  - *Source*: `lib/widgets/analytics/skill_radar_chart.dart`
- **`REQ-ANALYTICS-04`**: Exercise volume distribution bar chart with time-range filtering (7 Days, 30 Days, All Time).
  - *Status*: Implemented & Verified
  - *Source*: `lib/widgets/analytics/exercise_breakdown_bar_chart.dart`, `lib/screens/analytics_screen.dart`
- **`REQ-ANALYTICS-05`**: Adaptive training engine generating rolling-window recommendations to balance weaker cognitive domains.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/adaptive_training_service.dart`, `lib/screens/adaptive_training_screen.dart`
  - *Tests*: `test/adaptive_training_service_test.dart`

---

### 2.13 Multi-Platform & Reliability
- **`REQ-PLAT-01`**: SQLite cross-platform desktop & test compatibility using `sqflite_common_ffi`.
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/database_service.dart`
- **`REQ-PLAT-02`**: Web build support with WASM SQLite bindings (`sqflite_common_ffi_web`).
  - *Status*: Implemented & Verified
  - *Source*: `lib/services/database_service.dart`, `web/index.html`
- **`REQ-PLAT-03`**: Unit, Widget, and Visual verification test suite covering services, scoring, and UI flows.
  - *Status*: Implemented & Verified (18 test suites, 172 tests passing in 16.3s)
  - *Source*: `test/`
- **`REQ-PLAT-04`**: Isolated test database teardown preventing SQLite file concurrency locks during batch testing.
  - *Status*: Implemented & Verified
  - *Source*: `test/auth_service_test.dart`, `lib/services/database_service.dart` (`DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath)`)
