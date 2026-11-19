# PRD: Word Recall Training Module

## Introduction

Cognitive Gym trains four disciplines today (Story builder, Observation challenge, Scenario lab, Debate arena) but has no dedicated short-session memory drill. `WordGeneratorService` already maintains a curated 75-word pool but is only used for Story Builder constraints. This feature adds a fifth training module — **Word Recall** — a fast, timed memory exercise: the app shows a set of words briefly, then asks the user to recall them, optionally with a distractor task in between. It targets the Memory domain, integrates with XP/streak/rank systems, and gives the adaptive engine a new exercise type to recommend.

Primary target: all users, web-first (Flutter web), then mobile/desktop.

## Goals

- Add a playable word-recall drill completable in 2–4 minutes per session
- Reuse the existing word pool and scoring/XP infrastructure, no new backend
- Increase daily session variety and give the adaptive engine one more signal
- Support 3 difficulty tiers mapped to word count, display time, and distractor presence

## User Stories

### US-001: Word recall session model and service
**Description:** As a developer, I need a session engine that generates rounds, tracks recall answers, and computes a score.

**Acceptance Criteria:**
- [ ] `WordRecallService` generates a round: N words sampled via `WordGeneratorService.getRandomWords`, display duration, and distractor task type
- [ ] Difficulty tiers: Easy (5 words, 5s, no distractor), Standard (7 words, 4s, 10s distractor), Hard (10 words, 3s, math distractor)
- [ ] Score computed from exact matches, with partial credit for wrong order
- [ ] Score persists through existing `ExerciseScoringService`/`ProgressService` XP flow
- [ ] Unit test: round generation never repeats a word within a round; score math verified
- [ ] `flutter analyze` and `flutter test` pass

### US-002: Word recall screen
**Description:** As a user, I want a distraction-free screen that shows words, hides them, then collects my recall so the drill feels focused.

**Acceptance Criteria:**
- [ ] Screen states: briefing → memorize (words shown in a quiet grid, tabular layout) → distractor (Standard/Hard only) → recall input → result
- [ ] Memorize phase shows a visible countdown; words hide automatically at zero
- [ ] Recall phase uses a text field accepting comma-separated words; submit validates
- [ ] Result view lists correct (check), missed (dash), and wrong (cross) words with counts and XP earned
- [ ] Follows app design system: graphite surfaces, one lime accent, sentence case, radius 8/12
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill (all three difficulties)

### US-003: Home screen integration
**Description:** As a user, I want Word Recall discoverable from home like the other modules.

**Acceptance Criteria:**
- [ ] Fifth module card added to the workout grid: title "Word recall", subtitle describing the drill, tag "Memory", route `/word-recall`
- [ ] Memory domain identity color used only on the tag dot and tag text
- [ ] Daily quest panel optionally includes one Word Recall quest when adaptive engine picks it
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-004: Router and navigation wiring
**Description:** As a developer, I need the route registered so deep links and the back stack work.

**Acceptance Criteria:**
- [ ] `AppRouter.wordRecallRoute = '/word-recall'` registered with auth guard like other module routes
- [ ] Direct navigation to `/word-recall` while logged in opens the screen; logged out redirects to login and back after sign-in
- [ ] `flutter analyze` passes

### US-005: Adaptive training integration
**Description:** As a user, I want the adaptive engine to recommend Word Recall when memory practice is my weakest area.

**Acceptance Criteria:**
- [ ] `TrainingRecommendation` supports `word_recall` exercise type with icon, name, route, and estimated minutes
- [ ] Recommendation weight uses memory-domain performance (recall accuracy from recent sessions)
- [ ] Top-pick banner on home opens the screen with chosen difficulty when applicable
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-006: Analytics and streak integration
**Description:** As a user, I want Word Recall sessions to count toward XP, streaks, and analytics.

**Acceptance Criteria:**
- [ ] Completing a session records XP, domain points, and an analytics event via existing services
- [ ] Streak increments when a session completes (same rules as other modules)
- [ ] Analytics screen includes word-recall accuracy in skill/metric views where memory data appears
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: The system must sample N unique words per round from `WordGeneratorService.wordPool` without repeats
- FR-2: The system must display words for the tier's duration, then automatically advance to distractor or recall
- FR-3: The system must accept recall input as comma- or space-separated entries, case-insensitive, trimmed
- FR-4: The system must score: exact word match = 1 point; order bonus on Hard only
- FR-5: The system must award XP via the existing point flow and show the earned amount on the result view
- FR-6: The system must persist session results (round size, accuracy, XP) through the existing database service
- FR-7: The system must allow exiting mid-session with a confirmation dialog without awarding XP

## Non-Goals

- No new word pool content, word categories, or user-defined word lists
- No spaced-repetition scheduling or long-term review reminders
- No multiplayer or leaderboard mode for this module
- No TTS read-aloud mode in v1 (service exists; defer)
- No changes to existing modules' scoring or XP rates

## Design Considerations

- Memorize grid is the screen's visual moment: large tabular figures on a quiet surface; everything else stays chrome-quiet
- Distractor task uses the app's existing math/decision styling, plain card, no glow
- Follow the unslop direction established in `tasks/prd-ui-refresh.md` (same tokens, radii, type scale)

## Technical Considerations

- Flutter web first; keyboard input and paste must work in the recall field
- Session state is ephemeral (in-memory); only results persist
- Reuse `SoundService` tap/success cues already used by other modules
- Estimated effort small: one service, one screen, wiring in router/home/adaptive

## Success Metrics

- A complete Standard round takes under 3 minutes including result review
- Word Recall appears in at least one adaptive recommendation when memory domain is weakest
- No regression in home screen render performance with the fifth module card

## Open Questions

- Should wrong-order answers on Hard get 0.5 credit or 0?
- Does Memory domain map to an existing point type (observationPoints/knowledgePoints) or need its own counter?
- Should the recall input offer per-word fields instead of free text on web?
