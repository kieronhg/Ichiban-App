import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Session state ──────────────────────────────────────────────────────────

class StudentSession {
  const StudentSession({
    this.profileId,
    this.isAuthenticated = false,
  });

  /// The profile ID selected on the student select screen.
  /// Null means no profile has been chosen yet.
  final String? profileId;

  /// True once the PIN has been verified for [profileId].
  final bool isAuthenticated;

  bool get isProfileSelected => profileId != null;

  StudentSession copyWith({
    String? profileId,
    bool? isAuthenticated,
  }) {
    return StudentSession(
      profileId: profileId ?? this.profileId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StudentSession &&
      other.profileId == profileId &&
      other.isAuthenticated == isAuthenticated;

  @override
  int get hashCode => Object.hash(profileId, isAuthenticated);
}

// ── Notifier ───────────────────────────────────────────────────────────────

class StudentSessionNotifier extends Notifier<StudentSession> {
  @override
  StudentSession build() => const StudentSession();

  /// Called when a student taps their name on the select screen.
  void selectProfile(String profileId) {
    state = StudentSession(profileId: profileId, isAuthenticated: false);
  }

  /// Called after PIN verification succeeds.
  void authenticate() {
    if (state.profileId == null) return;
    state = state.copyWith(isAuthenticated: true);
  }

  /// Clears the session — returns to the select screen.
  void signOut() {
    state = const StudentSession();
  }
}

final studentSessionProvider =
    NotifierProvider<StudentSessionNotifier, StudentSession>(
  StudentSessionNotifier.new,
);
