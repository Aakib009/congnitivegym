import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_router.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';

/// Represents a cognitive training activity or game in the game library.
class CognitiveGameItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String mode;
  final IconData icon;
  final Color accentColor;
  final String route;
  final String actionLabel;

  const CognitiveGameItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.mode,
    required this.icon,
    required this.accentColor,
    required this.route,
    this.actionLabel = 'Start Playing →',
  });
}

/// Centralized game library screen where users can explore and launch all
/// major cognitive-training games and activities.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Observation',
    'Decision',
    'Creativity',
    'Logic',
  ];

  static const List<CognitiveGameItem> _allGames = [
    CognitiveGameItem(
      id: 'OBSERVATION',
      title: 'Observation Challenge',
      subtitle:
          'Timed visual detail and memory recall under graded focus clocks.',
      category: 'Observation',
      mode: 'Adaptive Trial • Visual Memory',
      icon: Icons.visibility_rounded,
      accentColor: AppColors.memoryBlue,
      route: AppRouter.observationChallengeRoute,
      actionLabel: 'Start Challenge →',
    ),
    CognitiveGameItem(
      id: 'DECISION',
      title: 'Scenario Lab',
      subtitle:
          'Multi-branching dilemma analysis, tactical ethics, and strategic trade-offs.',
      category: 'Decision',
      mode: 'Decision Tree • Trade-Offs',
      icon: Icons.alt_route_rounded,
      accentColor: AppColors.eventOrange,
      route: AppRouter.scenarioLabRoute,
      actionLabel: 'Enter Lab →',
    ),
    CognitiveGameItem(
      id: 'CREATIVITY',
      title: 'Story Builder',
      subtitle:
          'Synthesize dynamic narratives with vocabulary constraints and ranked scoring.',
      category: 'Creativity',
      mode: '1v1 Ranked • Vocabulary Synthesis',
      icon: Icons.auto_stories_rounded,
      accentColor: AppColors.mathYellow,
      route: AppRouter.storyBuilderRoute,
      actionLabel: 'Build Story →',
    ),
    CognitiveGameItem(
      id: 'LOGIC',
      title: 'Debate Arena',
      subtitle:
          'Structured dialectical sparring across philosophy, ethics, and formal logic.',
      category: 'Logic',
      mode: 'Dialectical Sparring • Logic',
      icon: Icons.forum_rounded,
      accentColor: AppColors.puzzleGreen,
      route: AppRouter.debateArenaRoute,
      actionLabel: 'Enter Arena →',
    ),
    CognitiveGameItem(
      id: 'SEQUENCE',
      title: 'Sequence Master',
      subtitle:
          'Decode alphabet, number, mixed, and visual patterns against a graded clock.',
      category: 'Logic',
      mode: 'Pattern Logic • Sequence Reasoning',
      icon: Icons.timeline_rounded,
      accentColor: AppColors.logicPink,
      route: AppRouter.sequenceMasterRoute,
      actionLabel: 'Start Sequences →',
    ),
    CognitiveGameItem(
      id: 'SPOT_DIFFERENCE',
      title: 'Spot the Difference',
      subtitle:
          'Scan paired scenes side-by-side to detect subtle visual discrepancies.',
      category: 'Observation',
      mode: 'Visual Discrimination • Attention',
      icon: Icons.center_focus_strong_rounded,
      accentColor: AppColors.memoryBlue,
      route: AppRouter.spotTheDifferenceRoute,
      actionLabel: 'Spot Differences →',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredGames = _selectedCategory == 'All'
        ? _allGames
        : _allGames.where((g) => g.category == _selectedCategory).toList();

    final canvasColor = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFF1F4F8);

    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.surfaceLightClean,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
                onPressed: () {
                  SoundService.instance.playPop();
                  Navigator.of(context).pop();
                },
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    (isDark ? AppColors.brandLime : AppColors.primaryLimeLight)
                        .withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.sports_esports_rounded,
                size: 20,
                color: isDark
                    ? AppColors.brandLime
                    : AppColors.primaryLimeLight,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Games',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMultiColumn = constraints.maxWidth >= 720;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  children: [
                    // 1. Category Filter Row
                    _buildCategoryFilterRow(isDark),
                    const SizedBox(height: 20),

                    // 2. Responsive Games Library Grid / List
                    if (isMultiColumn)
                      _buildMultiColumnLayout(context, filteredGames, isDark)
                    else
                      _buildSingleColumnLayout(context, filteredGames, isDark),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Category filter pills matching the application's clean design.
  Widget _buildCategoryFilterRow(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          final activeColor = isDark
              ? AppColors.brandLime
              : AppColors.primaryLimeLight;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                SoundService.instance.playTap();
                setState(() {
                  _selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? AppColors.brandLime.withAlpha(35)
                            : AppColors.primaryLimeLight.withAlpha(25))
                      : (isDark
                            ? AppColors.surfaceContainerLowest
                            : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? activeColor
                        : (isDark
                              ? AppColors.borderDark
                              : const Color(0xFFD6DEE7)),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                    color: isSelected
                        ? activeColor
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Multi-column layout (2 columns) for tablet & desktop viewports.
  Widget _buildMultiColumnLayout(
    BuildContext context,
    List<CognitiveGameItem> games,
    bool isDark,
  ) {
    final rows = <Widget>[];
    for (int i = 0; i < games.length; i += 2) {
      final game1 = games[i];
      final game2 = i + 1 < games.length ? games[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildGameCard(context, game1, isDark)),
                const SizedBox(width: 16),
                Expanded(
                  child: game2 != null
                      ? _buildGameCard(context, game2, isDark)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  /// Single-column layout for mobile-sized layouts.
  Widget _buildSingleColumnLayout(
    BuildContext context,
    List<CognitiveGameItem> games,
    bool isDark,
  ) {
    return Column(
      children: games.map((game) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildGameCard(context, game, isDark),
        );
      }).toList(),
    );
  }

  /// Individual game card with icon, title, description, mode pill, and play button.
  Widget _buildGameCard(
    BuildContext context,
    CognitiveGameItem game,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFD6DEE7);

    return Container(
      key: ValueKey('game-card-${game.id}'),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 28 : 8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            SoundService.instance.playTap();
            context.push(game.route);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category dot & pill + Mode tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: game.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          game.category.toUpperCase(),
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: game.accentColor,
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: game.accentColor.withAlpha(isDark ? 25 : 18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: game.accentColor.withAlpha(isDark ? 90 : 60),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          game.mode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: game.accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Game Icon & Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: game.accentColor.withAlpha(isDark ? 30 : 20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: game.accentColor.withAlpha(isDark ? 100 : 70),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          game.icon,
                          size: 22,
                          color: game.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            game.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bottom Divider & Start Button
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.borderSubtle
                            : AppColors.borderLightClean,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Interactive training',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          SoundService.instance.playTap();
                          context.push(game.route);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.textPrimary
                              : AppColors.primaryLimeLight,
                          foregroundColor: isDark
                              ? const Color(0xFF131313)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          game.actionLabel,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
