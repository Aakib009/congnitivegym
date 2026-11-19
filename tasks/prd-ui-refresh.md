# PRD: Cognitive Gym UI Refresh (All Screens)

## Introduction

Cognitive Gym's interface shows AI-generated design habits: seven competing accent colors on one screen, uppercase shouting labels, weight-800 text everywhere, emoji as icons, pill-shaped controls with mismatched radii, and ad-hoc color/opacity values instead of design tokens. This refresh applies the "unslop" design direction across the entire app so every screen is consistent, quiet, and deliberate: graphite surfaces, one lime accent, discipline colors only where they identify a discipline, and a strict type scale (Barlow Condensed for figures and titles, Plus Jakarta Sans for body).

The theme foundation, card widget, and home screen anchor are already done; this PRD covers rolling the same direction through every remaining screen, web-first.

## Goals

- One tinted neutral ramp, three text roles, one lime accent used rarely per screen
- Discipline colors (yellow/blue/orange/green) appear only where they identify a discipline
- All text sentence case; weights 400–600 only; no wide tracking on small text
- All spacing on the 4px grid; consistent radii (chips 6, controls 8, cards 12, dialogs 16)
- No emoji in interface chrome; one icon set (Material outlined) at consistent sizes
- Every screen reads as part of one product, verified in Flutter web

## User Stories

### US-001: Extend the cleaned theme tokens
**Description:** As a developer, I need the theme layer finished so all screens inherit correct defaults without per-screen overrides.

**Acceptance Criteria:**
- [ ] `app_theme.dart` text theme uses only weights 400/500/600, no letter spacing above 0.2
- [ ] ElevatedButton/OutlinedButton/TextButton/FilledButton themes all share radius 8 and no stadium shapes by default
- [ ] Dialog/Sheet themes defined: radius 16, hairline border, correct surface colors for dark and light
- [ ] `flutter analyze lib/utils/app_theme.dart` passes

### US-002: Auth screens (login, sign up)
**Description:** As a new user, I want a clean login and sign-up flow so the first impression is trustworthy.

**Acceptance Criteria:**
- [ ] Headline sentence case, states what the app is, no exclamation marks
- [ ] Inputs use theme input decoration; buttons use theme button style (radius 8)
- [ ] No gradient text, glows, or decorative blobs behind forms
- [ ] Keyboard focus states visible on all fields and buttons
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill (dark and light theme)

### US-003: Journal screen
**Description:** As a user, I want a readable journal list so I can review my past entries.

**Acceptance Criteria:**
- [ ] Entry rows share one height and gap; dates in one tabular column
- [ ] Sentence case headings; no emoji in toolbar or empty states
- [ ] Empty state uses a plain line icon and one short sentence
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-004: Analytics screen
**Description:** As a user, I want charts that follow one visual hierarchy so I can read my progress at a glance.

**Acceptance Criteria:**
- [ ] One main chart clearly the largest; secondary data smaller and different in kind
- [ ] One accent color per chart highlighting the current period; rest neutral
- [ ] Muted grid lines and sentence-case axis labels; no rainbow series
- [ ] Stat blocks are label + figure + change with comparison, no sparkline decoration
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-005: Mind tree screen and widget
**Description:** As a user, I want the mind tree visual to keep its nature identity while its controls match the app.

**Acceptance Criteria:**
- [ ] Tree painter (pine/moss/sage palette) kept as the screen's one rich moment
- [ ] Surrounding chrome uses graphite surfaces and lime accent only
- [ ] Legend and progress rows aligned; sentence case labels
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-006: Debate screens (arena, loading, chat)
**Description:** As a user, I want debate topic selection and chat to be calm and readable so I can focus on argument.

**Acceptance Criteria:**
- [ ] Arena topic cards: quiet surfaces, category color only on tag text
- [ ] Chat: user/AI bubbles differ by surface step, not by colored glow
- [ ] Loading screen has no looping decorative animation
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-007: Story builder screen
**Description:** As a user, I want the word constraints and editor to be clear so I can write without distraction.

**Acceptance Criteria:**
- [ ] Keyword chips quiet (mono figures, muted text, radius 6)
- [ ] Editor text at body size, sentence case prompts, no italic emphasis
- [ ] Timer/countdown as quiet tabular text, not a glowing pill
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-008: Observation challenge screen
**Description:** As a user, I want the challenge focus on the imagery, with quiet chrome around it.

**Acceptance Criteria:**
- [ ] Image area is the visual moment; controls and scores quiet
- [ ] Answer feedback uses semantic colors toned to palette
- [ ] Progress and timer aligned on the 4px grid
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-009: Scenario lab screen
**Description:** As a user, I want branching dilemmas presented as clear choice cards.

**Acceptance Criteria:**
- [ ] Choice cards equal height, equal padding, hairline borders
- [ ] Selected state is a surface step plus hairline highlight, no glow
- [ ] Outcome text sentence case, no trailing periods on short strings
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-010: Adaptive training, account, about screens
**Description:** As a user, I want settings and secondary screens to feel like the same product.

**Acceptance Criteria:**
- [ ] List rows one height, icons in one column, labels sentence case
- [ ] Achievement cards: no emoji icons; status via quiet text or dot
- [ ] About screen content reflowed with correct text roles
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-011: App drawer and navigation shell
**Description:** As a user, I want navigation that is the quietest part of the app.

**Acceptance Criteria:**
- [ ] Drawer rows 36–40 tall, 4px gaps, icons one column, sentence case
- [ ] Bottom nav uses theme NavigationBar with sentence case labels
- [ ] No badge pills except a small count dot where meaningful
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

### US-012: Level-up dialog, rank arena card, celebration widgets
**Description:** As a user, I want reward moments to feel earned and crafted, not loud.

**Acceptance Criteria:**
- [ ] Rank colors retained for tiers (they mean something) but used flat, no gradients
- [ ] Confetti colors limited to palette tokens
- [ ] Dialog radius 16, hairline border, sentence case copy
- [ ] `flutter analyze` passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: All screens import colors only from `AppColors` tokens; no inline `Color(0x...)` literals in screen/widget files
- FR-2: All text uses the theme text roles or the two families (Barlow Condensed, Plus Jakarta Sans) with weights 400–600
- FR-3: All interactive controls use the shared button/input themes; per-screen style overrides limited to size, not shape or color
- FR-4: Dark and light themes both render correctly on every touched screen
- FR-5: Each screen pass ends with `flutter analyze` clean and a web render check at 1280px and 390px widths

## Non-Goals

- No redesign of features, navigation structure, or information architecture
- No generated marketing imagery or new illustrations
- No new fonts beyond the existing two families
- No backend or data changes
- No dark/light theme behavior changes beyond color corrections

## Design Considerations

- Direction: "the gym at night" — matte graphite, chalk text, lime as the single signal
- The mind tree painter and rank emblem are the app's rich moments; chrome stays quiet around them
- Reuse existing `GymCard`, `SectionHeader`, and rank widgets rather than new components

## Technical Considerations

- Flutter web is the verification target; check rendering at 1280×800 and 390×844
- `home_screen.dart`, `app_theme.dart`, `app_colors.dart`, `gym_card.dart` are already converted; keep them as reference patterns
- Dead tokens (violet/gradients) already removed; any new need for them must be refused

## Success Metrics

- Zero emoji, zero weight-700+ text, zero letter-spacing >0.2 on small text across all screens
- `flutter analyze` reports no issues after every pass
- Side-by-side dark/light screenshots of all screens show consistent surfaces and radii

## Open Questions

- Should the web app get responsive breakpoints beyond the current 960px two-column switch?
- Do any screens need text scaling tests (accessibility 1.3x) as part of acceptance?
