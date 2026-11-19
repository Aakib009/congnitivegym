import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'app_drawer.dart';

/// Navigation wrapper widget for ShellRoute.
/// Adapts responsively: persistent sidebar on desktop viewports (>=900px),
/// and bottom navigation bar on mobile and tablet screens.
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairline =
        isDark ? AppColors.borderSubtle : AppColors.borderLightClean;

    if (isWide) {
      final user = AuthService.instance.currentUser;
      final displayName =
          user?.fullName.isNotEmpty == true ? user!.fullName : 'Operator';
      final initialLetter =
          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'O';

      return Scaffold(
        drawer: const AppDrawer(),
        body: Row(
          children: [
            Container(
              width: 232,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerLowest
                    : AppColors.surfaceLightClean,
                border: Border(right: BorderSide(color: hairline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand header
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: hairline)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceContainerHigh
                                : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: hairline),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.psychology_outlined,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cognitive Gym',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live status strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: hairline.withAlpha(120),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.brandLime
                                : AppColors.primaryLimeLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'System status: online',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sidebar navigation items
                  _buildSidebarItem(
                      context, 0, Icons.home_outlined, AppConstants.titleHome, isDark),
                  _buildSidebarItem(
                      context, 1, Icons.sports_esports_outlined, 'Games', isDark),
                  _buildSidebarItem(
                      context, 2, Icons.emoji_events_outlined, 'Achievements', isDark),
                  _buildSidebarItem(
                      context, 3, Icons.menu_book_outlined, 'Journal', isDark),
                  _buildSidebarItem(
                      context, 4, Icons.person_outline_rounded, 'Account', isDark),

                  const Spacer(),

                  // Bottom user pod
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: hairline)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceContainerLow
                                : AppColors.groundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: hairline),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceContainerHigh
                                      : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: hairline),
                                ),
                                child: Center(
                                  child: Text(
                                    initialLetter,
                                    style: GoogleFonts.barlowCondensed(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (ctx) => OutlinedButton.icon(
                            icon: const Icon(Icons.tune_outlined, size: 14),
                            label: const Text('Settings and theme'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(36),
                            ),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppConstants.titleHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Achievements',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    bool isDark,
  ) {
    final isSelected = navigationShell.currentIndex == index;
    final activeColor = isDark ? AppColors.brandLime : AppColors.primaryLimeLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: () => _onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.surfaceContainerHigh
                    : AppColors.cardLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isDark
                      ? AppColors.borderDarkStrong
                      : AppColors.borderLightStrong)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? activeColor
                    : (isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight)
                        : (isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
