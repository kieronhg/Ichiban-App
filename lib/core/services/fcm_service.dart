import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../constants/app_constants.dart';

/// Manages Firebase Cloud Messaging token capture and storage.
///
/// Token lifecycle:
/// - Admin login  → captureAndSaveAdminToken  → adminUsers/{id}
/// - Student login → captureAndSaveMemberToken → profiles/{id}
/// - Token refresh → onTokenRefresh listener re-writes to active user's doc
/// - Stale token   → Cloud Function nullifies fcmToken in Firestore
class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  // Track active identity so onTokenRefresh knows where to write.
  static String? _activeMemberProfileId;
  static String? _activeAdminUserId;

  static Future<void> initialise() async {
    // Re-save token whenever FCM rotates it.
    _messaging.onTokenRefresh.listen((token) async {
      try {
        if (_activeMemberProfileId != null) {
          await _writeToProfile(_activeMemberProfileId!, token);
        } else if (_activeAdminUserId != null) {
          await _writeToAdmin(_activeAdminUserId!, token);
        }
      } catch (_) {
        // Non-fatal — next login will re-capture.
      }
    });
  }

  /// Called after successful admin Firebase Auth sign-in.
  static Future<void> captureAndSaveAdminToken(String adminUserId) async {
    _activeAdminUserId = adminUserId;
    _activeMemberProfileId = null;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _messaging.getToken();
        if (token != null) await _writeToAdmin(adminUserId, token);
      }
    } catch (_) {
      // Non-fatal — the admin can still use the app without push.
    }
  }

  /// Called after successful student PIN login.
  static Future<void> captureAndSaveMemberToken(String profileId) async {
    _activeMemberProfileId = profileId;
    _activeAdminUserId = null;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _messaging.getToken();
        if (token != null) await _writeToProfile(profileId, token);
      }
    } catch (_) {
      // Non-fatal — the student can still use the app without push.
    }
  }

  /// Clears the active identity on sign-out so onTokenRefresh stops writing.
  static void clearActiveUser() {
    _activeMemberProfileId = null;
    _activeAdminUserId = null;
  }

  static Future<void> _writeToAdmin(String adminUserId, String token) async {
    await _db.collection(AppConstants.colAdminUsers).doc(adminUserId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _writeToProfile(String profileId, String token) async {
    await _db.collection(AppConstants.colProfiles).doc(profileId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
