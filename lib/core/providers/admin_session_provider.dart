import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_user.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ── Session state ──────────────────────────────────────────────────────────

class AdminSessionState {
  const AdminSessionState({
    this.adminUser,
    this.isLoading = false,
    this.errorMessage,
  });

  /// The currently authenticated admin. Null if not yet loaded or signed out.
  final AdminUser? adminUser;

  /// True while the adminUsers document is being fetched after sign-in.
  final bool isLoading;

  /// Set when the account is deactivated or the document is missing.
  final String? errorMessage;

  bool get isLoaded => !isLoading && adminUser != null;

  AdminSessionState copyWith({
    AdminUser? adminUser,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AdminSessionState(
      adminUser: adminUser ?? this.adminUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class AdminSessionNotifier extends Notifier<AdminSessionState> {
  @override
  AdminSessionState build() {
    // Watch Firebase auth state. Whenever the UID changes, reload the session.
    ref.listen<AsyncValue<String?>>(authStateProvider, (prev, next) {
      final uid = next.value;
      if (uid != null) {
        _loadSession(uid);
      } else {
        state = const AdminSessionState();
      }
    });

    // Kick off load immediately if already signed in on build.
    final uid = ref.read(authStateProvider).value;
    if (uid != null) {
      _loadSession(uid);
    }

    return const AdminSessionState();
  }

  Future<void> _loadSession(String uid) async {
    state = const AdminSessionState(isLoading: true);
    try {
      final repo = ref.read(adminUserRepositoryProvider);
      final adminUser = await repo.getById(uid);

      if (adminUser == null) {
        // No adminUsers document — this UID belongs to a student or parent,
        // not an admin. Stay empty so student auth provider can handle routing.
        state = const AdminSessionState();
        return;
      }

      if (!adminUser.isActive) {
        // Deactivated account — sign out immediately.
        await ref.read(authRepositoryProvider).signOut();
        state = const AdminSessionState(
          errorMessage:
              'Your account has been deactivated. '
              'Please contact the dojo owner.',
        );
        return;
      }

      // Stamp last login time (fire-and-forget — don't await).
      repo.recordLogin(uid);

      state = AdminSessionState(adminUser: adminUser);
    } catch (e) {
      state = AdminSessionState(
        errorMessage: 'Failed to load account details. Please try again.',
      );
    }
  }

  /// Call after sign-out to wipe session state.
  void clearSession() {
    state = const AdminSessionState();
  }
}

final adminSessionProvider =
    NotifierProvider<AdminSessionNotifier, AdminSessionState>(
      AdminSessionNotifier.new,
    );

// ── Convenience providers ──────────────────────────────────────────────────

/// The current signed-in admin, or null if not loaded.
final currentAdminUserProvider = Provider<AdminUser?>(
  (ref) => ref.watch(adminSessionProvider).adminUser,
);

/// True if the current admin is an owner.
final isOwnerProvider = Provider<bool>(
  (ref) => ref.watch(currentAdminUserProvider)?.isOwner ?? false,
);

/// True if the current admin is a coach.
final isCoachProvider = Provider<bool>(
  (ref) => ref.watch(currentAdminUserProvider)?.isCoach ?? false,
);

/// The discipline IDs the current coach is assigned to.
/// Empty for owners (who have access to all disciplines).
final assignedDisciplineIdsProvider = Provider<List<String>>(
  (ref) =>
      ref.watch(currentAdminUserProvider)?.assignedDisciplineIds ?? const [],
);

/// True if the current admin has access to the given discipline.
/// Owners always return true. Coaches return true only for their disciplines.
final hasDisciplineAccessProvider = Provider.family<bool, String>((
  ref,
  disciplineId,
) {
  final adminUser = ref.watch(currentAdminUserProvider);
  if (adminUser == null) return false;
  if (adminUser.isOwner) return true;
  return adminUser.assignedDisciplineIds.contains(disciplineId);
});

/// Error message from the last session load attempt, if any.
final adminSessionErrorProvider = Provider<String?>(
  (ref) => ref.watch(adminSessionProvider).errorMessage,
);
