import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';
import '../services/anti_gravity_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';

/// Styled About Screen placeholder detailing application architecture,
/// design principles, and Google Anti-Gravity API integration status.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final AntiGravityService _antiGravityService = AntiGravityService();
  bool _isServiceInitializing = false;
  AntiGravityMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    _loadAntiGravityMetrics();
  }

  Future<void> _loadAntiGravityMetrics() async {
    final metrics = await _antiGravityService.fetchMetrics();
    if (mounted) {
      setState(() {
        _metrics = metrics;
      });
    }
  }

  Future<void> _triggerApiInit() async {
    setState(() {
      _isServiceInitializing = true;
    });
    await _antiGravityService.initializeApi();
    final updated = await _antiGravityService.fetchMetrics();
    if (mounted) {
      setState(() {
        _isServiceInitializing = false;
        _metrics = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Architecture & Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.homeRoute);
            }
          },
        ),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Branding Banner
            GymCard(
              padding: const EdgeInsets.all(24),
              borderColor: colorScheme.primary.withAlpha(80),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withAlpha(80)),
                      ),
                      child: Icon(Icons.shield_rounded, color: colorScheme.primary, size: 40),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.appTagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.outline.withAlpha(80)),
                      ),
                      child: Text(
                        'Version ${AppConstants.appVersion} · Tactical Architecture',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Telemetry & Experimental Engine Card
            GymCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.blur_on_rounded, color: AppColors.warmAmber),
                          const SizedBox(width: 8),
                          Text('Telemetry Engine Sandbox',
                              style: theme.textTheme.titleLarge),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _antiGravityService.isInitialized
                              ? AppColors.successGreen.withAlpha(40)
                              : AppColors.warningOrange.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _antiGravityService.isInitialized
                              ? 'ACTIVE'
                              : 'STANDBY',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _antiGravityService.isInitialized
                                ? AppColors.pineGreen
                                : AppColors.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Developer sandbox harness (lib/services/anti_gravity_service.dart). Simulates spatial equilibrium and real-time state telemetry for experimental UI micro-interactions.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_metrics != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pineGreen.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Field Equilibrium: ${(_metrics!.spatialEquilibrium * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cognitive Equilibrium Score: ${_metrics!.cognitiveLevitationScore}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Initialize Telemetry API',
                    style: CustomButtonStyle.outline,
                    isLoading: _isServiceInitializing,
                    onPressed: _triggerApiInit,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Clean Architecture Structure Details
            Text('Production Architecture', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),

            _buildArchTile(
              context,
              icon: Icons.psychology_outlined,
              title: 'Cognitive Modules (/screens)',
              description:
                  'Story Builder (Fluency), Observation Challenge (Memory), Scenario Lab (Executive Function), Debate Arena (Critical Reasoning).',
            ),
            _buildArchTile(
              context,
              icon: Icons.shield_outlined,
              title: 'Security & Auth (/utils, /services)',
              description:
                  'PBKDF2-HMAC-SHA256 password security, offline deterministic evaluation, and session management.',
            ),
            _buildArchTile(
              context,
              icon: Icons.storage_outlined,
              title: 'Persistence Engine (/services)',
              description:
                  'SQLite database (users, analytics_events, journal_entries) with cross-platform FFI and in-memory test isolation.',
            ),
            _buildArchTile(
              context,
              icon: Icons.analytics_outlined,
              title: 'Scoring & Analytics (/services)',
              description:
                  'Deterministic exercise scoring engine, rolling cognitive skill indices, and trend analytics.',
            ),
            _buildArchTile(
              context,
              icon: Icons.palette_outlined,
              title: 'Design System (/utils, /widgets)',
              description:
                  'Material 3 gaming-inspired tactical design system, high-contrast typography, crisp card containers, and competitive rank progression.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GymCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withAlpha(60)),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(description, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: colorScheme.onSurface.withAlpha(160))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
