import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

// ── Session state ──────────────────────────────────────────────────────────

class StudentSession {
  const StudentSession({
    this.profileId,
    this.isAuthenticated = false,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.lastActivityAt,
  });

  /// The profile ID selected on the student select screen.
  /// Null means no profile has been chosen yet.
  final String? profileId;

  /// True once the PIN has been verified for [profileId].
  final bool isAuthenticated;

  /// Number of consecutive wrong-PIN attempts since last reset.
  final int failedAttempts;

  /// When set, the PIN screen is locked until this moment has passed.
  final DateTime? lockoutUntil;

  /// The last time the student interacted with the student area.
  /// Used to drive the inactivity-timeout check.
  final DateTime? lastActivityAt;

  bool get isProfileSelected => profileId != null;

  /// True while [lockoutUntil] is still in the future.
  bool get isLockedOut =>
      lockoutUntil != null && lockoutUntil!.isAfter(DateTime.now());

  /// Remaining lockout duration, or [Duration.zero] if not locked.
  Duration get lockoutRemaining {
    if (lockoutUntil == null) return Duration.zero;
    final remaining = lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  StudentSession copyWith({
    String? profileId,
    bool? isAuthenticated,
    int? failedAttempts,
    DateTime? lockoutUntil,
    bool clearLockout = false,
    DateTime? lastActivityAt,
  }) {
    return StudentSession(
      profileId: profileId ?? this.profileId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StudentSession &&
      other.profileId == profileId &&
      other.isAuthenticated == isAuthenticated &&
      other.failedAttempts == failedAttempts &&
      other.lockoutUntil == lockoutUntil &&
      other.lastActivityAt == lastActivityAt;

  @override
  int get hashCode => Object.hash(
    profileId,
    isAuthenticated,
    failedAttempts,
    lockoutUntil,
    lastActivityAt,
  );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class StudentSessionNotifier extends Notifier<StudentSession> {
  Timer? _timeoutTimer;

  @override
  StudentSession build() => const StudentSession();

  /// Called when a student taps their name on the select screen.
  void selectProfile(String profileId) {
    _cancelTimer();
    state = StudentSession(profileId: profileId, isAuthenticated: false);
  }

  /// Called after PIN verification succeeds.
  void authenticate() {
    if (state.profileId == null) return;
    state = state.copyWith(
      isAuthenticated: true,
      failedAttempts: 0,
      clearLockout: true,
      lastActivityAt: DateTime.now(),
    );
    _startTimeoutTimer();
  }

  /// Records one failed PIN attempt. Locks the screen if the threshold is hit.
  void recordFailedAttempt() {
    final attempts = state.failedAttempts + 1;
    final lockout = attempts >= AppConstants.pinMaxAttempts
        ? DateTime.now().add(Duration(minutes: AppConstants.pinLockoutMinutes))
        : null;
    state = state.copyWith(failedAttempts: attempts, lockoutUntil: lockout);
  }

  /// Resets the failed-attempt counter and clears any active lockout.
  /// Called on successful authentication or when a lockout expires.
  void resetAttempts() {
    state = state.copyWith(failedAttempts: 0, clearLockout: true);
  }

  /// Stamps the last-activity time, refreshing the inactivity timeout.
  /// Call on any meaningful user interaction in the student area.
  void updateActivity() {
    if (!state.isAuthenticated) return;
    state = state.copyWith(lastActivityAt: DateTime.now());
  }

  /// Clears the session — returns to the select screen.
  void signOut() {
    _cancelTimer();
    state = const StudentSession();
  }

  // ── Timer management ───────────────────────────────────────────────────

  void _startTimeoutTimer() {
    _cancelTimer();
    // Poll every 30 s — cheap, and max 30 s drift on a 5-min window is fine.
    _timeoutTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final last = state.lastActivityAt;
      if (!state.isAuthenticated || last == null) return;
      final idle = DateTime.now().difference(last);
      if (idle.inMinutes >= AppConstants.studentSessionTimeoutMinutes) {
        signOut();
      }
    });
  }

  void _cancelTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }
}

final studentSessionProvider =
    NotifierProvider<StudentSessionNotifier, StudentSession>(
      StudentSessionNotifier.new,
    );
