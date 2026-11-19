# Development Roadmap: Cognitive Gym

**Project:** Cognitive Gym  
**Current Milestone:** v1.0 Stabilization & Release Polish  
**Last Updated:** 2026-10-23  

---

## 1. Milestone Overview

```mermaid
gantt
    title Cognitive Gym Roadmap Progression
    dateFormat  YYYY-MM-DD
    section Completed
    Phase 1: Foundation & Navigation         :done, p1, 2026-08-01, 2026-08-15
    Phase 2: Core Cognitive Modules         :done, p2, 2026-08-16, 2026-09-01
    Phase 3: Gamification & Mind Tree       :done, p3, 2026-09-02, 2026-09-18
    Phase 4: SQLite Persistence & Security  :done, p4, 2026-09-19, 2026-09-30
    Phase 5: User Profiles & Mascot         :done, p5, 2026-10-01, 2026-10-08
    Phase 6: Visual Analytics & Radar       :done, p6, 2026-10-09, 2026-10-15
    Phase 7: Adaptive Training Engine       :done, p7, 2026-10-16, 2026-10-22
    section Active
    Phase 8: Multi-Platform Hardening       :active, p8, 2026-10-23, 2026-11-05
    section Future
    Phase 9: Cloud Sync & Social Challenges :p9, 2026-11-06, 2026-12-31
```

---

## 2. Phase Breakdown & Status

### Phase 1: Foundation & Navigation
- **Status:** COMPLETED
- **Focus:** Flutter project structure, theme definitions (`AppTheme`, `AppColors`), declarative navigation with `GoRouter`, bottom navigation shell with state retention (`StatefulShellRoute`).
- **Deliverables:**
  - `lib/main.dart`, `lib/routes/app_router.dart`, `lib/utils/app_theme.dart`
  - Base scaffolds, fallback startup error screen.

### Phase 2: Core Cognitive Modules
- **Status:** COMPLETED
- **Focus:** 4 distinct interactive training modules.
- **Deliverables:**
  - **Debate Arena**: OpenRouter integration, multi-turn AI debate coach, topic selection, post-debate reflection.
  - **Story Builder**: Prompt generator, required word validation, TTS speech reading, story storage.
  - **Observation Challenge**: Custom canvas scene painter, difficulty countdown timer, multiple-choice recall.
  - **Scenario Lab**: Decision-making dilemmas, deliberation speed/engagement scoring, consequences view.
  - **Scoring Engine**: `ExerciseScoringService` with objective in-app scoring rules and test coverage.

### Phase 3: Gamification & Mind Tree Engine
- **Status:** COMPLETED
- **Focus:** Player motivation, habit building, visual growth metaphors.
- **Deliverables:**
  - `PointService`, `RewardManager`, `StreakService`, `AchievementService`.
  - Level promotions with `LevelUpDialog` and `ConfettiCelebration`.
  - Audio cues via `SoundService`.
  - `MindTreeWidget` custom canvas tree renderer with branching nodes for Logic, Creativity, Observation, Decision-Making, and Knowledge.

### Phase 4: SQLite Persistence & Security
- **Status:** COMPLETED
- **Focus:** Robust local-first database, cross-platform FFI, user credentials security.
- **Deliverables:**
  - `DatabaseService` using `sqflite_common_ffi` and `sqflite_common_ffi_web`.
  - Table schemas for users, stories, analytics events, exercise completions.
  - Password security: Salted SHA-256 password hashing and transparent legacy password upgrades.

### Phase 5: User Management & Mascots
- **Status:** COMPLETED
- **Focus:** Authentication flows, profile customization, and identity.
- **Deliverables:**
  - `LoginScreen`, `SignUpScreen`, `AccountScreen`.
  - Customizable Raccoon mascot avatar (`RaccoonAvatar`) with gear unlocking.
  - Account statistics overview, streak indicator, and account settings.

### Phase 6: Visual Analytics & Cognitive Journal
- **Status:** COMPLETED
- **Focus:** Visualizing brain training trends and self-reflection.
- **Deliverables:**
  - `fl_chart` integrations:
    - `XpTrendLineChart` (daily XP trajectories)
    - `SkillRadarChart` (5-axis cognitive balance)
    - `ExerciseBreakdownBarChart` (distribution of completed activities)
  - `JournalScreen` logging chronological workout entries and reflection notes.

### Phase 7: Adaptive Training Engine
- **Status:** COMPLETED
- **Focus:** Closing cognitive gaps through personalized recommendations.
- **Deliverables:**
  - `AdaptiveTrainingService` computing rolling performance windows.
  - Dynamic difficulty scaling and exercise prioritization.
  - `AdaptiveTrainingScreen` and home screen recommendation banner.

---

### Phase 8: Multi-Platform Hardening & Release Polish (CURRENT COMPLETED)
- **Status:** COMPLETED
- **Focus:** Production build readiness, cross-platform validation, test runner concurrency hardening, security audit.
- **Key Tasks:**
  1. [x] **Test Database Isolation**: Resolved SQLite database file locks during concurrent/batch test runs (`auth_service_test.dart` / `test/`) by using unique in-memory isolated temp database instances per test harness (`DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath)`).
  2. [x] **Cryptographic Password Hardening**: Upgraded to PBKDF2-HMAC-SHA256 (10,000 iterations) with constant-time equality check and legacy SHA-256 upgrade path.
  3. [x] **API Key Secret Isolation**: Removed hardcoded OpenRouter API keys; switched to `--dart-define=OPENROUTER_API_KEY` and runtime injection.
  4. [x] **Duplicate XP Remediation**: Eliminated race-condition double-submissions in Story Builder and Observation Challenge via dual-lock guard pattern.
  5. [x] **SQLite Journal Persistence**: Added schema v4 migration for `journal_entries` table, reactive `JournalService`, mood/category metadata, and interactive journal UI.
  6. [x] **Scoring & Analytics Normalization**: Guaranteed 0-100% strict bounds across all 4 cognitive modules, eliminated artificial 15% skill floor for unpracticed domains, and added sample-size confidence tracking to `CognitiveAnalyticsData`.
  7. [x] **Audio/TTS Platform Fallbacks**: Graceful no-op handlers for platforms or headless environments without speech synthesis engines.
  8. [x] **Test Suite & Linter Verification**: 100% passing test suite (143/143 tests in 17s) and 0 static analysis issues.

---

### Phase 9: Cloud Sync, Social Challenges & Community (PLANNED)
- **Status:** PLANNED
- **Focus:** Multi-device synchronization and peer engagement.
- **Planned Features:**
  - Optional cloud backup for user profiles and journals.
  - Daily Community Challenge with synchronized prompts.
  - Peer debate rating / asynchronous debate sparring.
  - Extended scenario and observation scene asset packs.
