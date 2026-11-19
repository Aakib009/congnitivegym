import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/animal_avatar.dart';
import '../models/user_account.dart';
import '../utils/password_security.dart';
import 'analytics_service.dart';
import 'database_service.dart';
import 'progress_service.dart';

/// Result wrapper for authentication operations.
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserAccount? user;

  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.success(UserAccount user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}

/// Authentication service managing local user registration, login,
/// SQLite persistence, and session management.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _prefIsLoggedIn = 'pref_auth_is_logged_in';
  static const String _prefCurrentUserId = 'pref_auth_current_user_id';

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _hasAccount = false;
  UserAccount? _currentUser;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasAccount => _hasAccount;
  UserAccount? get currentUser => _currentUser;

  @visibleForTesting
  void setCurrentUserForTesting(UserAccount? user) {
    _currentUser = user;
    _isLoggedIn = user != null;
    notifyListeners();
  }

  /// Checks if any user account is registered in SQLite (async helper).
  Future<bool> hasAnyAccount() async {
    final count = await DatabaseService.instance.getUsersCount();
    _hasAccount = count > 0;
    return _hasAccount;
  }

  /// Initializes authentication state and restores active session.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final userCount = await DatabaseService.instance.getUsersCount();
      _hasAccount = userCount > 0;

      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_prefIsLoggedIn) ?? false;
      final userId = prefs.getString(_prefCurrentUserId);

      if (_isLoggedIn && userId != null && userId.isNotEmpty) {
        final user = await DatabaseService.instance.getUserById(userId);
        if (user != null) {
          _currentUser = user;
          await ProgressService.instance.loadForUser(
            user.id,
            displayName: user.fullName,
            avatarId: user.avatarId,
          );
        } else {
          // Reset corrupted session
          _isLoggedIn = false;
          _currentUser = null;
          await prefs.setBool(_prefIsLoggedIn, false);
          await prefs.remove(_prefCurrentUserId);
          ProgressService.instance.resetOnLogout();
        }
      } else {
        _isLoggedIn = false;
        _currentUser = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Error initializing session: $e');
      }
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Registers a new user account in SQLite and establishes the authenticated session.
  Future<AuthResult> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? avatarId,
  }) async {
    final cleanFullName = fullName.trim();
    final cleanUsername = username.trim();
    final cleanEmail = email.trim();

    if (cleanFullName.isEmpty ||
        cleanUsername.isEmpty ||
        cleanEmail.isEmpty ||
        password.isEmpty) {
      return AuthResult.error('All fields are required.');
    }

    if (cleanFullName.length < 2) {
      return AuthResult.error('Full name must be at least 2 characters.');
    }

    if (cleanUsername.length < 3) {
      return AuthResult.error('Username must be at least 3 characters.');
    }

    if (cleanUsername.contains(' ') || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(cleanUsername)) {
      return AuthResult.error('Username cannot contain spaces or special characters.');
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      return AuthResult.error('Please enter a valid email address.');
    }

    if (password.trim().isEmpty) {
      return AuthResult.error('Password cannot be whitespace only.');
    }

    if (password.length < 6) {
      return AuthResult.error('Password must be at least 6 characters.');
    }

    // Check username uniqueness (case-insensitive)
    final isUsernameTaken =
        await DatabaseService.instance.isUsernameTaken(cleanUsername);
    if (isUsernameTaken) {
      return AuthResult.error('Username "@$cleanUsername" is already taken. Please choose another.');
    }

    // Check email uniqueness (case-insensitive)
    final isEmailTaken = await DatabaseService.instance.isEmailTaken(cleanEmail);
    if (isEmailTaken) {
      return AuthResult.error('An account with this email address already exists.');
    }

    // Hash password securely with per-user salt
    final hashedPassword = PasswordSecurity.hashPassword(password);
    final effectiveAvatarId = AppAvatars.normalize(avatarId);

    final newUserId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final newAccount = UserAccount(
      id: newUserId,
      fullName: cleanFullName,
      username: cleanUsername,
      email: cleanEmail,
      password: hashedPassword,
      profileImage: effectiveAvatarId,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await DatabaseService.instance.insertUser(newAccount);
      _hasAccount = true;
      _isLoggedIn = true;
      _currentUser = newAccount;

      // Persist active session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setString(_prefCurrentUserId, newAccount.id);

      // Initialize clean user progress isolation
      await ProgressService.instance.loadForUser(
        newAccount.id,
        displayName: newAccount.fullName,
        avatarId: effectiveAvatarId,
      );

      notifyListeners();
      return AuthResult.success(newAccount);
    } catch (e) {
      return AuthResult.error('Failed to create account: ${e.toString()}');
    }
  }

  /// Authenticates user credentials against SQLite and establishes session.
  Future<AuthResult> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final identifier = emailOrUsername.trim();
    if (identifier.isEmpty || password.isEmpty) {
      return AuthResult.error('Please enter your email/username and password.');
    }

    final user = await DatabaseService.instance.getUserByEmailOrUsername(identifier);
    if (user == null) {
      return AuthResult.error('No account found matching "$identifier". Please check your credentials or Sign Up.');
    }

    // Verify password using secure salted hash with transparent plaintext upgrade fallback
    final isPasswordValid = PasswordSecurity.verifyPassword(password, user.password);
    if (!isPasswordValid) {
      return AuthResult.error('Incorrect password. Please try again.');
    }

    // Transparent upgrade if old plaintext password was stored
    if (PasswordSecurity.needsUpgrade(user.password)) {
      final secureHash = PasswordSecurity.hashPassword(password);
      final upgradedUser = user.copyWith(password: secureHash);
      await DatabaseService.instance.updateUser(upgradedUser);
    }

    // Save session
    _isLoggedIn = true;
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIsLoggedIn, true);
    await prefs.setString(_prefCurrentUserId, user.id);

    // Restore user-isolated progress
    await ProgressService.instance.loadForUser(
      user.id,
      displayName: user.fullName,
      avatarId: user.avatarId,
    );

    notifyListeners();
    return AuthResult.success(user);
  }

  /// Updates profile details in SQLite and active session.
  Future<AuthResult> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? profileImage,
  }) async {
    if (_currentUser == null) {
      return AuthResult.error('No active session.');
    }

    final updatedFullName = fullName?.trim() ?? _currentUser!.fullName;
    final updatedUsername = username?.trim() ?? _currentUser!.username;
    final updatedEmail = email?.trim() ?? _currentUser!.email;
    final updatedProfileImage = profileImage ?? _currentUser!.profileImage;

    // Check username conflict if changed
    if (updatedUsername.toLowerCase() != _currentUser!.username.toLowerCase()) {
      final isTaken = await DatabaseService.instance
          .isUsernameTaken(updatedUsername, excludeUserId: _currentUser!.id);
      if (isTaken) {
        return AuthResult.error('Username "@$updatedUsername" is already taken.');
      }
    }

    // Check email conflict if changed
    if (updatedEmail.toLowerCase() != _currentUser!.email.toLowerCase()) {
      final isTaken = await DatabaseService.instance
          .isEmailTaken(updatedEmail, excludeUserId: _currentUser!.id);
      if (isTaken) {
        return AuthResult.error('Email address "$updatedEmail" is already registered.');
      }
    }

    final updatedUser = _currentUser!.copyWith(
      fullName: updatedFullName,
      username: updatedUsername,
      email: updatedEmail,
      profileImage: updatedProfileImage,
    );

    try {
      await DatabaseService.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      if (profileImage != null) {
        await ProgressService.instance.updateAvatar(updatedUser.avatarId);
      }
      notifyListeners();
      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error('Failed to update profile: ${e.toString()}');
    }
  }

  /// Syncs cognitive points and XP from game progress into SQLite for active user.
  Future<void> syncProgress({
    required int totalXp,
    required int creativityPoints,
    required int observationPoints,
    required int logicPoints,
    required int decisionMakingPoints,
    required int knowledgePoints,
    required int exercisesCompleted,
    required int treeStage,
    required String currentRank,
  }) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      totalXP: totalXp,
      creativityPoints: creativityPoints,
      observationPoints: observationPoints,
      logicPoints: logicPoints,
      decisionMakingPoints: decisionMakingPoints,
      knowledgePoints: knowledgePoints,
      exercisesCompleted: exercisesCompleted,
      treeStage: treeStage,
      currentRank: currentRank,
    );

    try {
      await DatabaseService.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Error syncing progress to SQLite: $e');
      }
    }
  }

  /// Clears active login session without deleting SQLite user data.
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIsLoggedIn, false);
    await prefs.remove(_prefCurrentUserId);

    // Reset in-memory session caches across isolated services
    ProgressService.instance.resetOnLogout();
    AnalyticsService.instance.resetOnLogout();

    notifyListeners();
  }
}
