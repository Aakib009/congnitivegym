# Project State & Session Memory

**Project:** Cognitive Gym (`cognitive_gym`)  
**Project:** Cognitive Gym (`cognitive_gym`)  
**Active Phase:** Phase 13: Stabilization & UI Refinement  
**Current Status:** Release-Ready / 100% Offline-Capable Deterministic Debate Arena & Refined Competitive Dashboard  
**Timestamp:** 2026-10-24T10:35:00+05:30  

---

## 1. Project Health & Summary

| Dimension | Status | Notes |
| :--- | :---: | :--- |
| **Static Analysis** | Passed (0 issues) | Clean Dart analysis; zero errors, zero warnings, zero hints (`flutter analyze` clean in 4.5s). |
| **Core Functionality** | 100% Verified | All 4 cognitive exercises, SQLite journal, gamification, and analytics fully functional with offline deterministic debate sparring, transparent rubric feedback, and service-level idempotency. |
| **Test Suite** | 100% Passing (180/180) | 18 test suites; 100% passing across all widget, unit, scoring boundary, duplicate XP, and visual verification tests. |
| **Platform Target** | Multi-Platform | Web, Windows Desktop, Android, iOS, macOS, Linux supported. |
| **Design System** | `design.md` Specification | Exact tokens (`#171717` canvas, `#151515` sidebar, `#252525` surfaces, `#303030` raised, `#101010` inset play regions, `#3A3A3A` subtle borders, `#A7FF4F` brand lime, `#FFE000` math/creativity yellow, `#4DB4F5` memory blue, `#00C878` puzzle green, `#FF7043` event orange), responsive desktop sidebar (width >= 900), and mobile bottom navigation (width < 900). |
| **Security & Auth** | Robust (PBKDF2) | PBKDF2-HMAC-SHA256 (10,000 iterations); constant-time comparison; zero hardcoded secrets. |

---

## 2. Key Architecture Decisions (ADR Log)

- **`DEC-001` (Navigation)**: Adopted `go_router` with `StatefulShellRoute.indexedStack`.  
  *Rationale*: Retains full widget and scroll state across the 4 primary tabs (Home, Account, Journal, About) without rebuilding screens on tab switches.
- **`DEC-002` (State Management)**: Used singleton services extending `ChangeNotifier` and combined with `ListenableBuilder`.  
  *Rationale*: Avoids heavy external state management boilerplate while maintaining reactive, testable, and lightweight updates across the application.
- **`DEC-003` (Persistence Engine)**: Implemented `sqflite_common_ffi` paired with `sqflite_common_ffi_web`.  
  *Rationale*: Enables uniform SQLite API across mobile, native desktop (Windows/macOS/Linux), unit test isolates, and web browsers via WASM.
- **`DEC-004` (Cognitive Scoring & Analytics Normalization)**: Established deterministic, strictly objective in-app scoring in `ExerciseScoringService` and rolling aggregate normalization in `AnalyticsService`.  
  *Rationale*: Strictly avoids pseudoscientific medical claims while providing meaningful, reproducible feedback based on concrete interaction metrics bounded strictly to 0-100% without score overflow.
- **`DEC-005` (Deterministic Offline Debate Sparring Engine)**: Replaced external runtime OpenRouter dependency with `OfflineDebateService`.  
  *Rationale*: Completely removes network dependency, runtime API keys, and fake loading/AI claims. Evaluates user counterarguments deterministically across 4 transparent rhetorical criteria (Relevance 0-25, Reasoning 0-30, Counterargument Structure 0-25, Clarity 0-20, clamped 0-100) with tailored feedback notes.
- **`DEC-006` (Cryptographic Password Hashing)**: Upgraded password hashing from single-pass SHA-256 to PBKDF2-HMAC-SHA256 (10,000 iterations) with cryptographic random salt and constant-time string comparison (`_constantTimeEquals`).  
  *Rationale*: Protects against rainbow tables and timing side-channel attacks while supporting transparent legacy hash upgrades upon login.
- **`DEC-007` (Duplicate XP Prevention Guard)**: Implemented dual-guard submission architecture (`_isSubmitting` in-flight lock and `_hasCompletedCurrentChallenge` / `_hasRecordedCompletion` session locks).  
  *Rationale*: Prevents rapid multi-tap race conditions from awarding duplicate XP or double-logging exercises.
- **`DEC-008` (SQLite Journal Persistence)**: Added v4 database schema migration with `journal_entries` table, supporting full CRUD, category tagging, mood indexing, and mindfulness exercise rewards.  
  *Rationale*: Gives users persistent, private reflection storage backed by local SQLite with instant reactive UI updates.
- **`DEC-009` (Service-Level Activity Completion Idempotency)**: Implemented multi-layered service-level idempotency in `ProgressService` for all exercise completion methods (`recordStoryBuilderCompletion`, `recordObservationChallengeCompletion`, `recordScenarioLabCompletion`, `recordDebateArenaCompletion`, and `recordCustomExerciseReward`).  
  *Rationale*: Closes the verified duplicate-XP risk by combining synchronous in-flight claim locking (`Set<String> _inFlightCompletions`), persistent user-scoped storage in `SharedPreferences`, and SQLite primary key replacement deduplication (`ConflictAlgorithm.replace`) in `analytics_events`.
- **`DEC-010` (Tactical Anti-Vibe-Coding Design System & 8-Tier Competitive Rank System)**: Overhauled the application's visual system from botanical/pastel clichés to an art-directed, gaming-inspired cognitive console with `Rajdhani` and `Plus Jakarta Sans` typography, `GymCard` containers, and vector emblems.
- **`DEC-011` (Strict AND Rank Promotion Logic)**: Enforced strict conjunction (`totalXp >= minXp && level >= minLevel && totalMastery >= minMastery`) for rank eligibility. Added `RankRequirementStatus` and detailed breakdown pills in `RankArenaCard`. Verified via boundary tests (`test/rank_progression_test.dart`) proving that satisfying only 2 of the 3 criteria cannot unlock the next rank.
- **`DEC-012` (Theme Consolidation & Safe Migration)**: Restricted global themes strictly to Dark and Light modes. Added automated migration in `ThemeService.init()` converting legacy `'forest'` and `'violet'` user preferences cleanly to `'dark'` without altering any other user settings or data. Verified via unit tests (`test/theme_migration_test.dart`).
- **`DEC-013` (Mind Tree Retirement & Matiks Dashboard)**: Fully retired the user-facing Mind Tree screen, dashboard tree panel, and botanical labels while preserving underlying scoring, levels, XP, and analytics calculations. Redesigned dashboard following the Matiks reference with player bar, real telemetry status pills (`streak`, `focus`, `xp`), daily challenges progress bar, horizontal domain filter tabs, and 4 compact functional challenge cards.
- **`DEC-014` (`design.md` Complete Token Alignment & Responsive Layout)**: Aligned all color, typography, spacing, radius, and layout parameters strictly with `design.md`:
  - Main background `#171717`, desktop sidebar `#151515`, surface `#252525`, surface raised `#303030`, inset dark regions `#101010`, border subtle `#3A3A3A`, brand lime `#A7FF4F`.
  - Module identity accents: Story Builder `#FFE000`, Observation Challenge `#4DB4F5`, Scenario Lab `#FF7043`, Debate Arena `#00C878`.
  - Inset play areas: Story Builder editor and Scenario Lab narrative use `surfaceDeep` (`#101010`) for contrast and focus.
  - Zero overflow on narrow viewports: Made all headers, telemetry tags, and requirement pips flexible with ellipsis constraints.
- **`DEC-015` (Interactive Stance Selection & Offline Dialectical Sparring)**: Implemented pre-debate stance selection modal in `DebateArenaScreen` allowing users to explicitly choose `SUPPORT (In Favor)` or `OPPOSE (Against)`. Opponent dynamically adopts the opposite stance and responds instantly with structured rebuttals without fake delays or external network calls.
- **`DEC-016` (Daily Challenges 4-Domain Tracker & Modulo Bug Fix)**: Upgraded `_buildDailyChallengesBanner` to include discrete 4-domain tracker chips (Creativity, Observation, Decision, Logic) indicating whether each domain has been completed today. Fixed the modulo calculation so completed cycles correctly display `4/4 TARGET ACHIEVED` rather than rolling over to `0/4`.

---

## 3. Verification & Test Metrics

- **Static Analysis**: `flutter analyze` passed with **0 issues found** across all source and test files (ran in 4.5s).
- **Automated Tests**: **180/180 tests passed** (18 test suites in ~16.8s).
- **Design Specification Verification Suite**: `test/design_visual_verification_test.dart` passes all 9 verification items.
- **Debate Arena Test Suite**: `test/debate_arena_test.dart` passes all 16 unit and widget tests covering:
  1. Predefined 9 topics and prompts.
  2. Offline opening argument coverage across both stances.
  3. Rebuttal progression across turns.
  4. Closing syntheses.
  5. Transparent 4-criteria rubric boundary evaluations (0-100 clamping, empty/short/structured arguments).
  6. Strict determinism of evaluation engine.
  7. Duplicate XP prevention via idempotency keys.
  8. Stance selection modal interaction.
  9. Dual theme consistency (Dark & Light).
