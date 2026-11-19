import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/animal_avatar.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';

/// Sign up screen for Cognitive Gym.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedAvatar = AppAvatars.defaultAvatarId;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.instance.signUp(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        avatarId: _selectedAvatar,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created. Welcome, ${result.user?.fullName ?? ""}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        context.go(AppRouter.homeRoute);
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred during sign up: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textMuted : AppColors.textMutedLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceCanvas : AppColors.groundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GymCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Interactive Avatar Selector
                        AvatarSelector(
                          selectedAvatarId: _selectedAvatar,
                          previewSize: 84.0,
                          onAvatarSelected: (newId) {
                            setState(() {
                              _selectedAvatar = newId;
                            });
                          },
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          'Set up your account to start training',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: mutedColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.errorRed.withAlpha(120)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 18, color: AppColors.errorRed),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.errorRed,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Full name', isDark: isDark),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('signup_fullname_field'),
                                controller: _fullNameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Alex Mindful',
                                  prefixIcon: Icon(
                                    Icons.badge_outlined,
                                    size: 20,
                                    color: mutedColor,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Full name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _buildFieldLabel('Username', isDark: isDark),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('signup_username_field'),
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'alexmindful',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_outlined,
                                    size: 20,
                                    color: mutedColor,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  final clean = value.trim();
                                  if (clean.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  if (clean.contains(' ') ||
                                      !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(clean)) {
                                    return 'Username cannot contain spaces or special characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _buildFieldLabel('Email', isDark: isDark),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('signup_email_field'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'alex@cognitivegym.io',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                    color: mutedColor,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  final clean = value.trim();
                                  final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                  if (!emailRegex.hasMatch(clean)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _buildFieldLabel('Password', isDark: isDark),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('signup_password_field'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: '6 or more characters',
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                    color: mutedColor,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: mutedColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.trim().isEmpty) {
                                    return 'Password cannot be whitespace only';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _buildFieldLabel('Confirm password', isDark: isDark),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('signup_confirm_password_field'),
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                enabled: !_isLoading,
                                onFieldSubmitted: (_) => _handleSignUp(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Repeat your password',
                                  prefixIcon: Icon(
                                    Icons.lock_reset_outlined,
                                    size: 20,
                                    color: mutedColor,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: mutedColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              CustomButton(
                                key: const Key('signup_submit_button'),
                                label: _isLoading
                                    ? 'Creating account'
                                    : 'Create account',
                                icon: Icons.arrow_forward_outlined,
                                style: CustomButtonStyle.primary,
                                isLoading: _isLoading,
                                width: double.infinity,
                                onPressed: _isLoading ? null : _handleSignUp,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: mutedColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => context.go(AppRouter.loginRoute),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Sign in',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.brandLime
                                        : AppColors.primaryLimeLight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required bool isDark}) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
      ),
    );
  }
}
