import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/membership_pricing.dart';
import '../../domain/use_cases/settings/clear_notification_logs_use_case.dart';
import '../../domain/use_cases/settings/get_anonymisation_eligible_count_use_case.dart';
import '../../domain/use_cases/settings/record_re_consent_use_case.dart';
import '../../domain/use_cases/settings/save_gdpr_retention_use_case.dart';
import '../../domain/use_cases/settings/save_general_settings_use_case.dart';
import '../../domain/use_cases/settings/save_membership_prices_use_case.dart';
import '../../domain/use_cases/settings/save_notification_timings_use_case.dart';
import '../../domain/use_cases/settings/trigger_bulk_anonymise_use_case.dart';
import 'repository_providers.dart';

// ── Use-case providers ─────────────────────────────────────────────────────

final saveGeneralSettingsUseCaseProvider = Provider<SaveGeneralSettingsUseCase>(
  (ref) => SaveGeneralSettingsUseCase(
    ref.watch(appSettingsRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  ),
);

final saveMembershipPricesUseCaseProvider =
    Provider<SaveMembershipPricesUseCase>(
      (ref) => SaveMembershipPricesUseCase(
        ref.watch(membershipPricingRepositoryProvider),
        ref.watch(pricingChangeLogRepositoryProvider),
      ),
    );

final saveNotificationTimingsUseCaseProvider =
    Provider<SaveNotificationTimingsUseCase>(
      (ref) => SaveNotificationTimingsUseCase(
        ref.watch(appSettingsRepositoryProvider),
      ),
    );

final saveGdprRetentionUseCaseProvider = Provider<SaveGdprRetentionUseCase>(
  (ref) => SaveGdprRetentionUseCase(ref.watch(appSettingsRepositoryProvider)),
);

final getAnonymisationEligibleCountUseCaseProvider =
    Provider<GetAnonymisationEligibleCountUseCase>(
      (ref) => GetAnonymisationEligibleCountUseCase(
        ref.watch(appSettingsRepositoryProvider),
        ref.watch(membershipRepositoryProvider),
        ref.watch(profileRepositoryProvider),
      ),
    );

final triggerBulkAnonymiseUseCaseProvider =
    Provider<TriggerBulkAnonymiseUseCase>(
      (ref) => const TriggerBulkAnonymiseUseCase(),
    );

final clearNotificationLogsUseCaseProvider =
    Provider<ClearNotificationLogsUseCase>(
      (ref) => const ClearNotificationLogsUseCase(),
    );

final recordReConsentUseCaseProvider = Provider<RecordReConsentUseCase>(
  (ref) => RecordReConsentUseCase(
    ref.watch(profileRepositoryProvider),
    ref.watch(appSettingsRepositoryProvider),
  ),
);

// ── Data providers ─────────────────────────────────────────────────────────

/// All app settings as a key→value map.
final allSettingsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(appSettingsRepositoryProvider).getAll(),
);

/// All membership pricing documents, live.
final membershipPricingListProvider = StreamProvider<List<MembershipPricing>>(
  (ref) => ref.watch(membershipPricingRepositoryProvider).watchAll(),
);

/// Count of profiles currently eligible for bulk anonymisation.
final anonymisationEligibleCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(getAnonymisationEligibleCountUseCaseProvider).call(),
);

// ── Form notifiers ─────────────────────────────────────────────────────────

// General settings form

class GeneralSettingsFormState {
  const GeneralSettingsFormState({
    required this.dojoName,
    required this.dojoEmail,
    required this.privacyPolicyVersion,
    this.isSaving = false,
    this.errorMessage,
  });

  final String dojoName;
  final String dojoEmail;
  final String privacyPolicyVersion;
  final bool isSaving;
  final String? errorMessage;

  GeneralSettingsFormState copyWith({
    String? dojoName,
    String? dojoEmail,
    String? privacyPolicyVersion,
    bool? isSaving,
    Object? errorMessage = _absent,
  }) {
    return GeneralSettingsFormState(
      dojoName: dojoName ?? this.dojoName,
      dojoEmail: dojoEmail ?? this.dojoEmail,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _absent
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class GeneralSettingsFormNotifier
    extends AsyncNotifier<GeneralSettingsFormState> {
  @override
  Future<GeneralSettingsFormState> build() async {
    final settings = await ref.watch(appSettingsRepositoryProvider).getAll();
    return GeneralSettingsFormState(
      dojoName: (settings['dojoName'] as String?) ?? '',
      dojoEmail: (settings['dojoEmail'] as String?) ?? '',
      privacyPolicyVersion:
          (settings['privacyPolicyVersion'] as String?) ?? '1.0',
    );
  }

  void setDojoName(String v) {
    state = state.whenData((s) => s.copyWith(dojoName: v));
  }

  void setDojoEmail(String v) {
    state = state.whenData((s) => s.copyWith(dojoEmail: v));
  }

  void setPrivacyPolicyVersion(String v) {
    state = state.whenData((s) => s.copyWith(privacyPolicyVersion: v));
  }

  Future<void> save() async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isSaving: true, errorMessage: null));
    try {
      await ref.read(saveGeneralSettingsUseCaseProvider)(
        dojoName: current.dojoName,
        dojoEmail: current.dojoEmail,
        privacyPolicyVersion: current.privacyPolicyVersion,
      );
      state = AsyncData(current.copyWith(isSaving: false));
      ref.invalidate(allSettingsProvider);
    } catch (e) {
      state = AsyncData(
        current.copyWith(isSaving: false, errorMessage: e.toString()),
      );
      rethrow;
    }
  }
}

final generalSettingsFormProvider =
    AsyncNotifierProvider.autoDispose<
      GeneralSettingsFormNotifier,
      GeneralSettingsFormState
    >(GeneralSettingsFormNotifier.new);

// Notification timings form

class NotificationTimingsFormState {
  const NotificationTimingsFormState({
    required this.renewalReminderDays,
    required this.lapseReminderPreDueDays,
    required this.lapseReminderPostDueDays,
    required this.trialExpiryReminderDays,
    required this.dbsExpiryAlertDays,
    required this.firstAidExpiryAlertDays,
    required this.licenceReminderDays,
    this.isSaving = false,
    this.errorMessage,
  });

  final int renewalReminderDays;
  final int lapseReminderPreDueDays;
  final int lapseReminderPostDueDays;
  final int trialExpiryReminderDays;
  final int dbsExpiryAlertDays;
  final int firstAidExpiryAlertDays;
  final int licenceReminderDays;
  final bool isSaving;
  final String? errorMessage;

  bool get isValid =>
      _valid(renewalReminderDays) &&
      _valid(lapseReminderPreDueDays) &&
      _valid(lapseReminderPostDueDays) &&
      _valid(trialExpiryReminderDays) &&
      _valid(dbsExpiryAlertDays) &&
      _valid(firstAidExpiryAlertDays) &&
      _valid(licenceReminderDays);

  static bool _valid(int v) => v >= 1 && v <= 365;

  NotificationTimingsFormState copyWith({
    int? renewalReminderDays,
    int? lapseReminderPreDueDays,
    int? lapseReminderPostDueDays,
    int? trialExpiryReminderDays,
    int? dbsExpiryAlertDays,
    int? firstAidExpiryAlertDays,
    int? licenceReminderDays,
    bool? isSaving,
    Object? errorMessage = _absent,
  }) {
    return NotificationTimingsFormState(
      renewalReminderDays: renewalReminderDays ?? this.renewalReminderDays,
      lapseReminderPreDueDays:
          lapseReminderPreDueDays ?? this.lapseReminderPreDueDays,
      lapseReminderPostDueDays:
          lapseReminderPostDueDays ?? this.lapseReminderPostDueDays,
      trialExpiryReminderDays:
          trialExpiryReminderDays ?? this.trialExpiryReminderDays,
      dbsExpiryAlertDays: dbsExpiryAlertDays ?? this.dbsExpiryAlertDays,
      firstAidExpiryAlertDays:
          firstAidExpiryAlertDays ?? this.firstAidExpiryAlertDays,
      licenceReminderDays: licenceReminderDays ?? this.licenceReminderDays,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _absent
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class NotificationTimingsFormNotifier
    extends AsyncNotifier<NotificationTimingsFormState> {
  @override
  Future<NotificationTimingsFormState> build() async {
    final s = await ref.watch(appSettingsRepositoryProvider).getAll();
    return NotificationTimingsFormState(
      renewalReminderDays: _int(s, 'renewalReminderDays', 14),
      lapseReminderPreDueDays: _int(s, 'lapseReminderPreDueDays', 5),
      lapseReminderPostDueDays: _int(s, 'lapseReminderPostDueDays', 5),
      trialExpiryReminderDays: _int(s, 'trialExpiryReminderDays', 2),
      dbsExpiryAlertDays: _int(s, 'dbsExpiryAlertDays', 60),
      firstAidExpiryAlertDays: _int(s, 'firstAidExpiryAlertDays', 60),
      licenceReminderDays: _int(s, 'licenceReminderDays', 30),
    );
  }

  static int _int(Map<String, dynamic> map, String key, int fallback) =>
      ((map[key] as num?)?.toInt()) ?? fallback;

  void setField(String field, int value) {
    state = state.whenData((s) {
      return switch (field) {
        'renewalReminderDays' => s.copyWith(renewalReminderDays: value),
        'lapseReminderPreDueDays' => s.copyWith(lapseReminderPreDueDays: value),
        'lapseReminderPostDueDays' => s.copyWith(
          lapseReminderPostDueDays: value,
        ),
        'trialExpiryReminderDays' => s.copyWith(trialExpiryReminderDays: value),
        'dbsExpiryAlertDays' => s.copyWith(dbsExpiryAlertDays: value),
        'firstAidExpiryAlertDays' => s.copyWith(firstAidExpiryAlertDays: value),
        'licenceReminderDays' => s.copyWith(licenceReminderDays: value),
        _ => s,
      };
    });
  }

  Future<void> save() async {
    final current = state.asData?.value;
    if (current == null || !current.isValid) return;
    state = AsyncData(current.copyWith(isSaving: true, errorMessage: null));
    try {
      await ref.read(saveNotificationTimingsUseCaseProvider)(
        renewalReminderDays: current.renewalReminderDays,
        lapseReminderPreDueDays: current.lapseReminderPreDueDays,
        lapseReminderPostDueDays: current.lapseReminderPostDueDays,
        trialExpiryReminderDays: current.trialExpiryReminderDays,
        dbsExpiryAlertDays: current.dbsExpiryAlertDays,
        firstAidExpiryAlertDays: current.firstAidExpiryAlertDays,
        licenceReminderDays: current.licenceReminderDays,
      );
      state = AsyncData(current.copyWith(isSaving: false));
      ref.invalidate(allSettingsProvider);
    } catch (e) {
      state = AsyncData(
        current.copyWith(isSaving: false, errorMessage: e.toString()),
      );
      rethrow;
    }
  }
}

final notificationTimingsFormProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationTimingsFormNotifier,
      NotificationTimingsFormState
    >(NotificationTimingsFormNotifier.new);

// GDPR retention form

class GdprRetentionFormState {
  const GdprRetentionFormState({
    required this.gdprRetentionMonths,
    this.isSaving = false,
    this.errorMessage,
  });

  final int gdprRetentionMonths;
  final bool isSaving;
  final String? errorMessage;

  bool get isValid => gdprRetentionMonths >= 1;

  GdprRetentionFormState copyWith({
    int? gdprRetentionMonths,
    bool? isSaving,
    Object? errorMessage = _absent,
  }) {
    return GdprRetentionFormState(
      gdprRetentionMonths: gdprRetentionMonths ?? this.gdprRetentionMonths,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _absent
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class GdprRetentionFormNotifier extends AsyncNotifier<GdprRetentionFormState> {
  @override
  Future<GdprRetentionFormState> build() async {
    final setting = await ref
        .watch(appSettingsRepositoryProvider)
        .get('gdprRetentionMonths');
    return GdprRetentionFormState(gdprRetentionMonths: setting?.intValue ?? 12);
  }

  void setRetentionMonths(int v) {
    state = state.whenData((s) => s.copyWith(gdprRetentionMonths: v));
  }

  Future<void> save() async {
    final current = state.asData?.value;
    if (current == null || !current.isValid) return;
    state = AsyncData(current.copyWith(isSaving: true, errorMessage: null));
    try {
      await ref.read(saveGdprRetentionUseCaseProvider)(
        gdprRetentionMonths: current.gdprRetentionMonths,
      );
      state = AsyncData(current.copyWith(isSaving: false));
    } catch (e) {
      state = AsyncData(
        current.copyWith(isSaving: false, errorMessage: e.toString()),
      );
      rethrow;
    }
  }
}

final gdprRetentionFormProvider =
    AsyncNotifierProvider.autoDispose<
      GdprRetentionFormNotifier,
      GdprRetentionFormState
    >(GdprRetentionFormNotifier.new);

// Pricing form

class PricingFormNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() async {
    final pricing = await ref
        .watch(membershipPricingRepositoryProvider)
        .getAll();
    return {for (final p in pricing) p.key: p.amount};
  }

  void setPrice(String key, double value) {
    state = state.whenData((map) => {...map, key: value});
  }

  Future<void> save({required String adminId}) async {
    final current = state.asData?.value;
    if (current == null) return;
    await ref.read(saveMembershipPricesUseCaseProvider)(
      prices: current,
      changedByAdminId: adminId,
    );
    ref.invalidateSelf();
  }
}

final pricingFormProvider =
    AsyncNotifierProvider.autoDispose<PricingFormNotifier, Map<String, double>>(
      PricingFormNotifier.new,
    );

const Object _absent = Object();
