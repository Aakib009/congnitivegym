import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Local password security utility using PBKDF2-HMAC-SHA256.
/// Implements OWASP-compliant key derivation with backward compatibility
/// for legacy salted sha256 and plaintext passwords.
class PasswordSecurity {
  PasswordSecurity._();

  static final Random _secureRandom = Random.secure();

  /// Default iterations for PBKDF2-HMAC-SHA256 (balanced for mobile/desktop security and responsiveness).
  static const int defaultIterations = 10000;

  /// Generates a cryptographically secure random alphanumeric salt.
  static String generateSalt([int length = 16]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[_secureRandom.nextInt(chars.length)]).join();
  }

  /// Derives PBKDF2-HMAC-SHA256 key block for given [passwordBytes] and [saltBytes].
  static Uint8List _pbkdf2Sha256(List<int> passwordBytes, List<int> saltBytes, int iterations) {
    final hmac = Hmac(sha256, passwordBytes);
    // Block index 1 in big-endian (4 bytes)
    final initialMessage = Uint8List(saltBytes.length + 4);
    initialMessage.setRange(0, saltBytes.length, saltBytes);
    initialMessage[saltBytes.length + 3] = 1;

    var u = Uint8List.fromList(hmac.convert(initialMessage).bytes);
    final result = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  /// Converts bytes to a lowercase hexadecimal string.
  static String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Constant-time string equality check to prevent timing attacks.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Hashes a plaintext [password] using PBKDF2-HMAC-SHA256 with [salt] and [iterations].
  /// Formats the result as `pbkdf2_sha256$<iterations>$<salt>$<hex_hash>`.
  static String hashPassword(String password, {String? salt, int iterations = defaultIterations}) {
    final effectiveSalt = salt ?? generateSalt();
    final pwBytes = utf8.encode(password);
    final saltBytes = utf8.encode(effectiveSalt);
    final derived = _pbkdf2Sha256(pwBytes, saltBytes, iterations);
    final hexHash = _bytesToHex(derived);
    return 'pbkdf2_sha256\$$iterations\$$effectiveSalt\$$hexHash';
  }

  /// Verifies a plaintext [password] against the [storedPasswordHash].
  ///
  /// Supports:
  /// 1. Modern PBKDF2: `pbkdf2_sha256$<iterations>$<salt>$<hex_hash>`
  /// 2. Legacy single-round SHA-256: `sha256$<salt>$<hex_hash>`
  /// 3. Legacy plaintext passwords (upgraded upon authentication)
  static bool verifyPassword(String password, String storedPasswordHash) {
    if (storedPasswordHash.isEmpty) return false;

    // 1. PBKDF2-HMAC-SHA256 format
    if (storedPasswordHash.startsWith('pbkdf2_sha256\$')) {
      final parts = storedPasswordHash.split('\$');
      if (parts.length != 4) return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations <= 0) return false;
      final salt = parts[2];
      final expectedHash = parts[3];

      final pwBytes = utf8.encode(password);
      final saltBytes = utf8.encode(salt);
      final derived = _pbkdf2Sha256(pwBytes, saltBytes, iterations);
      final actualHash = _bytesToHex(derived);

      return _constantTimeEquals(actualHash, expectedHash);
    }

    // 2. Legacy single-round SHA-256 format
    if (storedPasswordHash.startsWith('sha256\$')) {
      final parts = storedPasswordHash.split('\$');
      if (parts.length != 3) return false;
      final salt = parts[1];
      final expectedHash = parts[2];
      final actualHash = sha256.convert(utf8.encode('$salt:$password')).toString();
      return _constantTimeEquals(actualHash, expectedHash);
    }

    // 3. Legacy fallback: plain text comparison
    return _constantTimeEquals(storedPasswordHash, password);
  }

  /// Checks whether [storedPasswordHash] is in an older format and should be upgraded
  /// to modern PBKDF2-HMAC-SHA256 upon successful login.
  static bool needsUpgrade(String storedPasswordHash) {
    return !storedPasswordHash.startsWith('pbkdf2_sha256\$');
  }
}

