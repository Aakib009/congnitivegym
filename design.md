# Cognitive Gym --- Visual Design System

## Matiks-Inspired Reference Specification

**Status:** Reference-based design specification\
**Source:** Ten user-provided Matiks screenshots captured on 24 October
2026\
**Target application:** Cognitive Gym (Flutter)\
**Scope:** Visual language, layout patterns, reusable components,
interaction states, and adaptation guidance

------------------------------------------------------------------------

## 1. Design Intent

Cognitive Gym should feel like a **competitive cognitive-training
arcade**, not a generic productivity dashboard. The interface should
emphasize activities, challenge selection, live performance, and
progression.

The Matiks references establish a visual language built from: -
Near-black page backgrounds and charcoal surfaces. - Bright lime
branding and restrained category-specific accent colors. - Condensed,
uppercase display typography. - Large, assertive game titles. - Compact
labels and telemetry. - Persistent navigation and clearly separated
content regions. - Gameplay screens that remove unnecessary interface
chrome. - Purpose-built matchmaking, gameplay, and result states.

Use these as design principles, not as a mandate to copy Matiks
branding, assets, names, or unsupported functionality.

### Product-specific adaptation

Cognitive Gym's existing modules are: - Story Builder - Observation
Challenge - Scenario Lab - Debate Arena

Give each module a distinct accent and icon treatment while retaining
one shared layout, typography system, spacing scale, and interaction
language. Do not add multiplayer queues, live opponents, social feeds,
or competitive features unless they genuinely exist in the application.

------------------------------------------------------------------------

## 2. Visual Foundations

### 2.1 Color palette

The screenshots show a dark-first interface. The following values are
**proposed implementation tokens inferred from the screenshots**, not
measured official Matiks brand values.

  -----------------------------------------------------------------------
  Token                   Proposed value          Usage
  ----------------------- ----------------------- -----------------------
  `pageBackground`        `#171717`               Main application
                                                  background

  `sidebarBackground`     `#151515`               Persistent desktop
                                                  navigation

  `surface`               `#252525`               Game cards, quest
                                                  cards, content panels

  `surfaceRaised`         `#303030`               Inputs, progress
                                                  tracks, secondary
                                                  surfaces

  `surfaceDeep`           `#101010`               In-game play areas and
                                                  inset regions

  `borderSubtle`          `#3A3A3A`               Separators and quiet
                                                  outlines

  `textPrimary`           `#F5F5F5`               Primary labels and
                                                  headings

  `textSecondary`         `#A3A3A3`               Descriptions and
                                                  supporting metadata

  `textMuted`             `#707070`               Low-priority labels and
                                                  inactive metadata

  `brandLime`             `#A7FF4F`               Brand emphasis, active
                                                  navigation, primary
                                                  progress

  `mathYellow`            `#FFE000`               Math category accent

  `memoryBlue`            `#4DB4F5`               Memory category accent

  `puzzleGreen`           `#00C878`               Puzzle/logic-style
                                                  accent

  `logicPink`             `#EA438B`               Logic category accent

  `eventOrange`           `#FF7043`               Event banners and
                                                  special challenge
                                                  emphasis

  `error`                 `#E34B4B`               Errors only; never
                                                  decorative emphasis
  -----------------------------------------------------------------------

#### Color rules

1.  Use charcoal surfaces against a near-black page; avoid making every
    container a separate shade.
2.  Reserve lime for the primary brand and selected states.
3.  Use category colors to communicate category identity, not as
    arbitrary decoration.
4.  Keep text contrast high. Do not use muted gray for essential
    instructions or scores.
5.  Avoid gradients, neon glows, and drop shadows as default styling.
6.  Provide a real light theme using semantic tokens. Do not simply
    invert every color mechanically.
7.  Never use a category color as the only way to convey status; pair it
    with text, an icon, or a shape change.

### 2.2 Typography

The references use a strong contrast between condensed display type and
compact UI text.

  -----------------------------------------------------------------------
  Role                    Style guidance          Typical use
  ----------------------- ----------------------- -----------------------
  Display / game title    Condensed, heavy,       Activity names, section
                          uppercase               headers, event titles

  Section heading         Bold, compact           "Daily Challenges",
                                                  "Today's Quest"
                                                  equivalents

  Body                    Neutral sans-serif,     Instructions,
                          medium weight           explanations, dialogue

  Metadata                Small sans-serif,       Category, rating,
                          medium weight           duration, status

  Telemetry               Tabular numerals where  Timer, score, XP,
                          possible                progress

  Button                  Bold, compact;          Primary action and game
                          uppercase only where    controls
                          suitable                
  -----------------------------------------------------------------------

Use a bundled or reliably available font pairing in Flutter. A condensed
display font such as **Rajdhani or Barlow Condensed** may suit headings;
pair it with a legible sans-serif such as **Inter or Plus Jakarta Sans**
for body text. Confirm font licensing and offline availability before
adopting assets.

Do not use the display font for long paragraphs, dialogue, or
accessibility-critical instructions.

### 2.3 Shape, borders, and depth

-   Use compact corner radii rather than applying one oversized radius
    everywhere.
-   Use thin borders for selected navigation and category states.
-   Prefer flat surfaces and clear contrast over elevation and shadow.
-   Use an inset dark region for focused gameplay where it improves
    concentration.
-   Use stronger outlines for selected/active items; inactive items
    should remain legible.
-   Reserve decorative illustrations for specific product moments, not
    every card.

Suggested radius tokens: - `radiusSmall`: 4--6 px - `radiusControl`:
8--10 px - `radiusPanel`: 10--14 px - `radiusPill`: fully rounded, only
for compact badges or status chips

These are implementation recommendations, not exact measurements
extracted from the screenshots.

------------------------------------------------------------------------

## 3. Layout System

### 3.1 Desktop shell

The Arena, Quests, and Compete references use a persistent left sidebar.
Content is organized in a central workspace, with a right rail on
selected screens.

Recommended desktop structure:

``` text
┌────────────────┬─────────────────────────────┬──────────────────┐
│ Brand           │ Main content                │ Optional right   │
│                 │                             │ rail             │
│ Arena           │ Page heading / activity     │ Daily tasks      │
│ Quests          │ Category selector           │ Progress         │
│ Compete         │ Main content                 │ Supporting info  │
│ Feed*           │                             │                  │
│ More*           │                             │                  │
└────────────────┴─────────────────────────────┴──────────────────┘
```

`*` Include only navigation destinations that actually exist in
Cognitive Gym.

Guidelines: - Keep the sidebar width stable on desktop and visually
separated by a subtle vertical border. - Make the active destination
unmistakable with a lime outline or filled active surface, icon, and
label. - Let the main content have the most horizontal space. - Use a
right rail only when it provides useful secondary information. Do not
force one onto focused gameplay screens. - Avoid excessive horizontal
stretching of text-heavy content. - Use a consistent content gutter and
align section headings to the same grid.

### 3.2 Responsive behavior

The supplied references are predominantly desktop layouts; they do not
establish exact mobile breakpoints.

Recommended behavior: - **Wide desktop:** sidebar + main workspace +
optional right rail. - **Tablet / narrow window:** sidebar may collapse
to icon navigation; right rail moves below the main content or is
omitted if secondary. - **Mobile:** use compact top navigation or bottom
navigation consistent with the existing app; stack content vertically;
prioritize the active task and current score. - **Gameplay:** keep the
play surface central, controls reachable, and timer/score visible
without forcing horizontal scrolling.

Choose breakpoints based on actual Flutter layout testing rather than
copying assumed web breakpoints.

### 3.3 Spacing scale

Use a small consistent spacing scale instead of arbitrary values:

  Token         Suggested value
  ----------- -----------------
  `space1`                 4 px
  `space2`                 8 px
  `space3`                12 px
  `space4`                16 px
  `space6`                24 px
  `space8`                32 px
  `space12`               48 px

Use tighter spacing for telemetry and labels, larger spacing between
distinct sections, and sufficient padding around gameplay controls.

------------------------------------------------------------------------

## 4. Navigation and Shared Components

### 4.1 Sidebar item

**Anatomy** - Icon - Short label - Active-state outline or surface -
Optional small status marker only when meaningful

**Behavior** - Selected item has strong contrast and a clear visual
boundary. - Inactive items remain readable. - Hover and keyboard-focus
states are visible on desktop. - Selection is not communicated by color
alone.

### 4.2 Category selector

The Matiks Arena shows categories as a row of compact, visually distinct
tiles.

For Cognitive Gym, adapt this to the four real modules or their existing
cognitive domains.

**Anatomy** - Distinct icon or geometric mark - Category label -
Optional rating or progress only if supported by real data - Selected
outline and stronger accent treatment

Do not display invented ratings, matchmaking status, or rank values. If
mastery data is unavailable, omit the value or display a truthful empty
state.

### 4.3 Activity / challenge tile

The references use large game titles and short descriptions rather than
dense metadata.

**Recommended anatomy** 1. Category label 2. Large, concise activity
title 3. One-line purpose or instruction 4. Optional real
progress/status 5. Directional indicator or primary action

Avoid placing the same number of badges, metadata rows, and buttons on
every tile. Use the simplest structure that serves the specific
activity.

### 4.4 Quest / daily task row

Use compact rows for discrete tasks: - Task description - Current
progress and target - A thin progress indicator - Action to continue,
when applicable

Progress must be derived from actual task-completion state. Do not use
modulo counters or placeholder progress to simulate a live system.

### 4.5 Buttons

-   Primary action: strong contrast and a clear label.
-   Secondary action: neutral outline or flat surface.
-   Destructive action: reserved error/destructive styling.
-   Disabled action: visibly disabled and non-interactive.
-   Keep labels action-oriented: "Start challenge", "Submit argument",
    "Review result".
-   Avoid vague labels such as "Go" when a more specific action is
    possible.

### 4.6 Status and rating chips

Use compact chips for category, difficulty, rating, or state. Keep each
chip to one semantic purpose. Do not display an ELO/rating system unless
Cognitive Gym actually implements and persists it.

------------------------------------------------------------------------

## 5. Game and Activity States

The references show that pre-game, active gameplay, and result
calculation are different visual states. Cognitive Gym should treat them
as distinct screens or clearly defined states.

### 5.1 Selection state

-   Explain what the activity trains.
-   Present available topics or challenge variants.
-   Show difficulty or estimated duration only when grounded in real
    configuration.
-   Keep the start action prominent.

### 5.2 Ready / start state

-   State the task and rules concisely.
-   Confirm any time limit before the activity begins.
-   Provide an obvious start action.
-   Avoid starting timers while the user is still reading instructions.

### 5.3 Active gameplay state

-   Remove unrelated dashboard sections and promotional content.
-   Keep the prompt/task, response area, score, and timer visible as
    relevant.
-   Use high-contrast controls and a clear focus order.
-   Prevent accidental duplicate submissions.
-   Make keyboard input and focus behavior reliable where applicable.

### 5.4 Evaluation / loading state

-   Use a task-specific progress message when work is genuinely
    occurring.
-   For deterministic local scoring, evaluation should usually be
    immediate; do not simulate long processing.
-   Do not use a fake countdown or spinner to conceal an error.
-   If an operation fails, provide a recovery action.

### 5.5 Result state

-   Show the actual result, score, and earned rewards.
-   Explain the scoring basis briefly.
-   Separate activity performance from cumulative XP, level, rank, and
    long-term mastery.
-   Offer sensible next actions: review, retry, or return.
-   Award XP once per completed activity; prevent repeat submissions
    from duplicating rewards.

------------------------------------------------------------------------

## 6. Cognitive Gym Module Mapping

These are product-specific recommendations derived from the reference
patterns and the known module list, not claims about Matiks features.

  -----------------------------------------------------------------------
  Cognitive Gym module    Suggested visual        Primary screen emphasis
                          identity                
  ----------------------- ----------------------- -----------------------
  Story Builder           Warm amber or           Prompt, constraints,
                          restrained violet       writing area,
                          accent                  completion

  Observation Challenge   Cool blue/cyan accent   Scene, observation
                                                  timer, recall response

  Scenario Lab            Amber/orange accent     Dilemma, branching
                                                  choices, trade-offs

  Debate Arena            Green or blue accent    Topic, stance, argument
                                                  entry, turn state
  -----------------------------------------------------------------------

Keep the overall interface dark-first with lime as the brand accent. Use
module accents as secondary identifiers, not as four competing brand
colors.

If the project already has an established accent mapping, inspect it
before changing it. Avoid introducing colors that conflict with the
user's requirement for only Dark and Light appearance themes.

------------------------------------------------------------------------

## 7. Progression and Gamification

Matiks makes ratings, XP, streaks, and task completion visible.
Cognitive Gym should use the same principle of visibility while
retaining its own progression model.

### Recommended information hierarchy

1.  Current rank and level
2.  Progress toward the next rank
3.  Current XP and relevant mastery indicators
4.  Daily challenge progress
5.  Recent activity results

Rules: - Use the existing authoritative services and models. - Rank
eligibility must use the implemented requirements; do not derive rank
separately in multiple widgets. - Display the exact requirements for the
next rank. - Make unmet requirements clear without overstating
progress. - Do not confuse an activity score with XP or long-term
mastery. - Use a rank badge as a flat geometric emblem rather than an
elaborate gradient/glass effect. - Keep progression meaningful even when
the user has zero recorded activity.

------------------------------------------------------------------------

## 8. Light and Dark Themes

The references primarily demonstrate a dark theme. They do not provide
enough evidence to specify an official Matiks light theme.

Cognitive Gym must support exactly two appearance themes: **Dark** and
**Light**.

Implement semantic color tokens so widgets do not hardcode
theme-specific colors: - Page background - Primary and secondary
surfaces - Primary, secondary, and muted text - Border and divider -
Brand accent - Module accents - Success, warning, and error - Focus,
selected, disabled, and hover states

The light theme should preserve the same hierarchy, typography, and
category mapping while using suitable light surfaces and dark text. Do
not create Forest, Violet, or other selectable appearance themes. Module
accent colors are not themes.

Test both themes for contrast, disabled states, dialogs, charts, and
gameplay surfaces.

------------------------------------------------------------------------

## 9. Motion and Feedback

Use motion only when it clarifies a state change or gives feedback.

Appropriate examples: - A short active-navigation transition. - A
progress bar updating after confirmed completion. - A brief
rank-promotion reveal. - A clear countdown transition when a timed
activity starts. - A result reveal after real evaluation completes.

Avoid: - Constant pulsing or decorative movement. - Long transitions
between ordinary screens. - Animations that delay user input. - Fake
matchmaking or loading states. - Motion as the only indicator of success
or failure.

Respect reduced-motion preferences where the platform and implementation
support them.

------------------------------------------------------------------------

## 10. Accessibility and Usability

-   Maintain readable contrast in both themes.
-   Do not rely on color alone for category, correctness, progress, or
    error.
-   Provide semantic labels for icon-only controls.
-   Support keyboard navigation and visible focus on desktop.
-   Keep tap targets sufficiently large on mobile.
-   Support larger text scaling without overflow.
-   Ensure timers do not obscure essential controls.
-   Make errors actionable and preserve user-entered content where
    possible.
-   Use clear empty states instead of invented telemetry.
-   Make screen readers announce meaningful state changes without
    excessive repetition.

------------------------------------------------------------------------

## 11. Flutter Implementation Guidance

Before implementing, inspect the existing theme, shared widgets,
routing, and module architecture. Prefer adapting existing code over
introducing a parallel design system.

Suggested conceptual tokens: - `AppColors` - `AppTypography` -
`AppSpacing` - `AppRadii` - `GymScaffold` - `GymNavigationItem` -
`GymCategoryTile` - `GymActivityTile` - `GymProgressIndicator` -
`GymStatusChip` - `GymPrimaryButton`

These are suggestions, not mandatory new classes. Reuse existing project
equivalents when available.

Implementation rules: 1. Keep business logic out of presentation
widgets. 2. Use existing services for XP, rank, mastery, persistence,
and completion. 3. Do not create mock production data to make the
interface appear populated. 4. Preserve routes, module functionality,
authentication, and persistence. 5. Avoid adding dependencies solely for
visual effects. 6. Verify desktop and mobile layouts at representative
sizes. 7. Run `flutter analyze`, focused tests, and `flutter test` after
implementation. 8. Inspect the actual rendered UI, not just the widget
source.

------------------------------------------------------------------------

## 12. Screenshot-Based Findings and Limits

The supplied screenshots support the following observations: - Dark,
charcoal-based UI is the dominant visual language. - Lime is used for
branding and active navigation. - Game categories have separate accent
colors. - Display headings are condensed, heavy, and often uppercase. -
Desktop navigation is persistent on several product screens. - Arena
content is organized into category selection, activity cards, daily
tasks, and secondary content. - Gameplay uses a sparse, centered task
area with prominent score/timer information. - Matchmaking and result
processing have their own full-screen states. - Quests and events can
use stronger, campaign-specific graphic treatments.

The screenshots do **not** establish: - Exact official color values,
font files, spacing tokens, or breakpoints. - How every hover, focus,
disabled, or error state behaves. - The full mobile layout system. -
Matiks' underlying component architecture. - Whether every displayed
social, matchmaking, or competition feature is available in Cognitive
Gym. - Any scientifically valid relationship between gameplay scores and
cognitive improvement.

Treat all proposed numeric tokens in this document as starting points to
validate in the rendered Flutter app.

------------------------------------------------------------------------

## 13. Design Review Checklist

Before approving a redesigned screen, check:

-   [ ] The screen has one clear primary purpose.
-   [ ] The visual hierarchy starts with the activity, not decorative
    containers.
-   [ ] Typography has a clear display/body distinction.
-   [ ] Colors communicate brand, category, or state intentionally.
-   [ ] Cards are used only where grouping improves comprehension.
-   [ ] The layout is not a repeated template without a product-specific
    reason.
-   [ ] No fake timers, rankings, users, progress, quests, or telemetry
    appear.
-   [ ] Active, loading, empty, error, and completion states are
    handled.
-   [ ] Dark and Light themes both work.
-   [ ] Desktop and mobile layouts have been inspected.
-   [ ] Accessibility and keyboard/touch interaction have been checked.
-   [ ] Existing functionality and tests remain intact.

------------------------------------------------------------------------

## 14. Recommended Design Direction

**Working concept: Cognitive Arena.**

The product should feel like a focused training arena where users enter
a cognitive challenge, perform under clear rules, receive understandable
feedback, and progress through ranks. The interface should be bold and
competitive without pretending that offline exercises are multiplayer
matches or that heuristic scores are clinical measures.

The differentiator should be the **transition from challenge selection
to focused activity to meaningful results**, not merely the use of dark
colors and bright accents.

Build and critique one representative flow first: 1. Dashboard / module
selection 2. One active cognitive challenge 3. Result and XP/rank update

Once that flow feels coherent and distinctive, extend the design system
to the other modules.
