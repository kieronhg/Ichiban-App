import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/cash_payment.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/grading_event.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_history.dart';
import '../../domain/entities/profile.dart';
import 'coach_profile_providers.dart';
import 'membership_providers.dart';
import 'payments_providers.dart';
import 'profile_providers.dart';
import 'repository_providers.dart';

// ── Value objects ─────────────────────────────────────────────────────────────

class MemberMetrics {
  const MemberMetrics({
    required this.activeCount,
    required this.adultCount,
    required this.juniorCount,
    required this.trialCount,
    required this.lapsedCount,
    required this.newThisMonth,
  });

  final int activeCount;
  final int adultCount;
  final int juniorCount;
  final int trialCount;
  final int lapsedCount;
  final int newThisMonth;

  static const zero = MemberMetrics(
    activeCount: 0,
    adultCount: 0,
    juniorCount: 0,
    trialCount: 0,
    lapsedCount: 0,
    newThisMonth: 0,
  );
}

class FinancialMetrics {
  const FinancialMetrics({
    required this.paytOutstanding,
    required this.cashReceivedThisMonth,
  });

  final double paytOutstanding;
  final double cashReceivedThisMonth;

  static const zero = FinancialMetrics(
    paytOutstanding: 0,
    cashReceivedThisMonth: 0,
  );
}

enum AlertSeverity { warning, error }

class DashboardAlert {
  const DashboardAlert({
    required this.severity,
    required this.message,
    this.routeName,
  });

  final AlertSeverity severity;
  final String message;
  final String? routeName;
}

class ActivityItem {
  const ActivityItem({
    required this.timestamp,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final DateTime timestamp;
  final IconData icon;
  final String title;
  final String? subtitle;
}

class CoachDisciplineSummary {
  const CoachDisciplineSummary({
    required this.disciplineId,
    required this.activeMemberCount,
    required this.upcomingGradings,
  });

  final String disciplineId;
  final int activeMemberCount;
  final List<GradingEvent> upcomingGradings;
}

// ── Member metrics ────────────────────────────────────────────────────────────

final memberMetricsProvider = Provider<MemberMetrics>((ref) {
  final memberships = ref.watch(membershipListProvider).asData?.value ?? [];
  final profiles = ref.watch(profileListProvider).asData?.value ?? [];
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  var activeCount = 0;
  var trialCount = 0;
  var lapsedCount = 0;
  var newThisMonth = 0;

  // Track active member profile IDs for adult/junior split
  final activeMemberProfileIds = <String>{};

  for (final m in memberships) {
    switch (m.status) {
      case MembershipStatus.active:
      case MembershipStatus.payt:
        activeCount++;
        activeMemberProfileIds.addAll(m.memberProfileIds);
      case MembershipStatus.trial:
        trialCount++;
      case MembershipStatus.gracePeriod:
      case MembershipStatus.lapsed:
      case MembershipStatus.expired:
        lapsedCount++;
      case MembershipStatus.cancelled:
        break;
    }
    if (m.createdAt.isAfter(monthStart)) newThisMonth++;
  }

  // Derive adult/junior split from profile types
  var adultCount = 0;
  var juniorCount = 0;
  for (final p in profiles) {
    if (activeMemberProfileIds.contains(p.id)) {
      if (p.isJunior) {
        juniorCount++;
      } else if (p.isAdult) {
        adultCount++;
      }
    }
  }

  return MemberMetrics(
    activeCount: activeCount,
    adultCount: adultCount,
    juniorCount: juniorCount,
    trialCount: trialCount,
    lapsedCount: lapsedCount,
    newThisMonth: newThisMonth,
  );
});

// ── Financial metrics ─────────────────────────────────────────────────────────

final financialMetricsProvider = Provider<FinancialMetrics>((ref) {
  final pendingPayt =
      ref.watch(allPendingPaytSessionsProvider).asData?.value ?? [];
  final allPayments = ref.watch(allCashPaymentsProvider).asData?.value ?? [];

  final paytOutstanding = pendingPayt.fold<double>(
    0.0,
    (sum, s) => sum + s.amount,
  );

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final cashThisMonth = allPayments
      .where((p) => p.recordedAt.isAfter(monthStart))
      .fold<double>(0.0, (sum, p) => sum + p.amount);

  return FinancialMetrics(
    paytOutstanding: paytOutstanding,
    cashReceivedThisMonth: cashThisMonth,
  );
});

// ── Owner alert flags ─────────────────────────────────────────────────────────

final ownerAlertFlagsProvider = Provider<List<DashboardAlert>>((ref) {
  final memberships = ref.watch(membershipListProvider).asData?.value ?? [];
  final pendingPayt =
      ref.watch(allPendingPaytSessionsProvider).asData?.value ?? [];
  final coachProfiles = ref.watch(coachProfileListProvider).asData?.value ?? [];

  final alerts = <DashboardAlert>[];
  final now = DateTime.now();
  final thirtyDays = now.add(const Duration(days: 30));

  // Lapsed memberships
  final lapsedCount = memberships
      .where(
        (m) =>
            m.status == MembershipStatus.lapsed ||
            m.status == MembershipStatus.expired,
      )
      .length;
  if (lapsedCount > 0) {
    alerts.add(
      DashboardAlert(
        severity: AlertSeverity.warning,
        message: '$lapsedCount lapsed membership${lapsedCount == 1 ? '' : 's'}',
        routeName: 'adminMemberships',
      ),
    );
  }

  // Trials expiring in 7 days
  final trialExpiringCount = memberships
      .where(
        (m) =>
            m.status == MembershipStatus.trial &&
            m.trialEndDate != null &&
            m.trialEndDate!.isBefore(now.add(const Duration(days: 7))) &&
            m.trialEndDate!.isAfter(now),
      )
      .length;
  if (trialExpiringCount > 0) {
    alerts.add(
      DashboardAlert(
        severity: AlertSeverity.warning,
        message:
            '$trialExpiringCount trial${trialExpiringCount == 1 ? '' : 's'} expiring within 7 days',
        routeName: 'adminMemberships',
      ),
    );
  }

  // Pending PAYT outstanding
  if (pendingPayt.length > 5) {
    alerts.add(
      DashboardAlert(
        severity: AlertSeverity.warning,
        message: '${pendingPayt.length} unpaid PAYT sessions outstanding',
        routeName: 'adminPayments',
      ),
    );
  }

  // Coach DBS alerts
  for (final cp in coachProfiles) {
    final dbs = cp.dbs;
    if (dbs.status == DbsStatus.expired) {
      alerts.add(
        DashboardAlert(
          severity: AlertSeverity.error,
          message: 'Coach DBS expired — action required',
          routeName: 'adminUsers',
        ),
      );
    } else if (dbs.expiryDate != null &&
        dbs.expiryDate!.isBefore(thirtyDays) &&
        dbs.expiryDate!.isAfter(now)) {
      alerts.add(
        DashboardAlert(
          severity: AlertSeverity.warning,
          message: 'Coach DBS expiring within 30 days',
          routeName: 'adminUsers',
        ),
      );
    }
    // First aid expiry
    final fa = cp.firstAid;
    if (fa.expiryDate != null &&
        fa.expiryDate!.isBefore(thirtyDays) &&
        fa.expiryDate!.isAfter(now)) {
      alerts.add(
        DashboardAlert(
          severity: AlertSeverity.warning,
          message: 'Coach first-aid cert expiring within 30 days',
          routeName: 'adminUsers',
        ),
      );
    }
  }

  return alerts;
});

// ── Activity feed ─────────────────────────────────────────────────────────────

final activityFeedProvider = FutureProvider.autoDispose<List<ActivityItem>>((
  ref,
) async {
  final membershipHistoryRepo = ref.watch(membershipHistoryRepositoryProvider);
  final cashPaymentRepo = ref.watch(cashPaymentRepositoryProvider);
  final announcementRepo = ref.watch(announcementRepositoryProvider);
  final attendanceRepo = ref.watch(attendanceRepositoryProvider);

  final results = await Future.wait([
    membershipHistoryRepo.getRecent(20),
    cashPaymentRepo.getAll().then((list) => list.take(10).toList()),
    announcementRepo.getAll(),
    attendanceRepo.getRecentSessions(10),
  ]);

  final historyItems = (results[0] as List<MembershipHistory>)
      .map(
        (h) => ActivityItem(
          timestamp: h.changedAt,
          icon: Icons.card_membership_outlined,
          title: _membershipChangeLabel(h.changeType),
        ),
      )
      .toList();

  final paymentItems = (results[1] as List<CashPayment>)
      .map(
        (p) => ActivityItem(
          timestamp: p.recordedAt,
          icon: Icons.payments_outlined,
          title: 'Payment recorded — £${p.amount.toStringAsFixed(2)}',
        ),
      )
      .toList();

  final announcementItems = (results[2] as List<Announcement>)
      .take(5)
      .map(
        (a) => ActivityItem(
          timestamp: a.sentAt,
          icon: Icons.campaign_outlined,
          title: 'Announcement: ${a.title}',
          subtitle: '${a.recipientCount} recipients',
        ),
      )
      .toList();

  final gradingRepo = ref.watch(gradingEventRepositoryProvider);
  final gradingEvents = await gradingRepo.getAll().catchError(
    (_) => <GradingEvent>[],
  );
  final gradingItems = gradingEvents
      .take(5)
      .map(
        (g) => ActivityItem(
          timestamp: g.createdAt,
          icon: Icons.military_tech_outlined,
          title: g.title ?? 'Grading event created',
        ),
      )
      .toList();

  final all = [
    ...historyItems,
    ...paymentItems,
    ...announcementItems,
    ...gradingItems,
  ];
  all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return all.take(10).toList();
});

String _membershipChangeLabel(MembershipChangeType type) {
  switch (type) {
    case MembershipChangeType.created:
      return 'New membership created';
    case MembershipChangeType.renewed:
      return 'Membership renewed';
    case MembershipChangeType.lapsed:
      return 'Membership lapsed';
    case MembershipChangeType.cancelled:
      return 'Membership cancelled';
    case MembershipChangeType.reactivated:
      return 'Membership reactivated';
    case MembershipChangeType.planChanged:
      return 'Membership plan changed';
    case MembershipChangeType.statusOverride:
      return 'Membership status overridden';
  }
}

// ── Chart data providers ──────────────────────────────────────────────────────

/// Membership growth: active membership count per month for the last 6 months.
/// Returns a list of (monthIndex, count) as (x, y) pairs.
final membershipGrowthChartProvider =
    FutureProvider.autoDispose<List<({int x, double y})>>((ref) async {
      final memberships =
          ref.read(membershipListProvider).asData?.value ?? <Membership>[];
      final now = DateTime.now();
      final result = <({int x, double y})>[];

      for (var i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(month.year, month.month + 1, 1);
        final count = memberships
            .where(
              (m) =>
                  m.createdAt.isBefore(monthEnd) &&
                  (m.status == MembershipStatus.active ||
                      m.status == MembershipStatus.trial ||
                      m.status == MembershipStatus.payt),
            )
            .length;
        result.add((x: 5 - i, y: count.toDouble()));
      }
      return result;
    });

/// Attendance trend: total attendance records per week for the past 4 weeks.
final attendanceTrendChartProvider =
    FutureProvider.autoDispose<List<({int x, double y})>>((ref) async {
      final repo = ref.read(attendanceRepositoryProvider);
      final now = DateTime.now();
      final fourWeeksAgo = now.subtract(const Duration(days: 28));
      final records = await repo.getRecordsForPeriod(fourWeeksAgo, now);

      final result = <({int x, double y})>[];
      for (var i = 0; i < 4; i++) {
        final weekStart = now.subtract(Duration(days: 28 - (i * 7)));
        final weekEnd = weekStart.add(const Duration(days: 7));
        final count = records
            .where(
              (r) =>
                  r.sessionDate.isAfter(weekStart) &&
                  r.sessionDate.isBefore(weekEnd),
            )
            .length;
        result.add((x: i, y: count.toDouble()));
      }
      return result;
    });

/// Grading pass rate for the last 90 days.
final gradingPassRateChartProvider =
    FutureProvider.autoDispose<List<({int x, double y})>>((ref) async {
      final repo = ref.read(gradingEventStudentRepositoryProvider);
      final from = DateTime.now().subtract(const Duration(days: 90));
      final records = await repo.getWithOutcomeFrom(from);

      final total = records.length;
      final passed = records
          .where((r) => r.outcome == GradingOutcome.promoted)
          .length;
      final failed = records
          .where((r) => r.outcome == GradingOutcome.failed)
          .length;
      final absent = records
          .where((r) => r.outcome == GradingOutcome.absent)
          .length;

      if (total == 0) return [];
      return [
        (x: 0, y: passed.toDouble()),
        (x: 1, y: failed.toDouble()),
        (x: 2, y: absent.toDouble()),
      ];
    });

// ── Coach discipline summary ───────────────────────────────────────────────���──

final coachDisciplineSummaryProvider = FutureProvider.autoDispose
    .family<CoachDisciplineSummary, String>((ref, disciplineId) async {
      final enrollmentsRepo = ref.read(enrollmentRepositoryProvider);
      final gradingEventsRepo = ref.read(gradingEventRepositoryProvider);

      final enrollments = await enrollmentsRepo.getForDiscipline(disciplineId);
      final events = await gradingEventsRepo.getAll();
      final upcoming =
          events
              .where(
                (e) =>
                    e.disciplineId == disciplineId &&
                    e.status == GradingEventStatus.upcoming,
              )
              .toList()
            ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

      return CoachDisciplineSummary(
        disciplineId: disciplineId,
        activeMemberCount: enrollments.length,
        upcomingGradings: upcoming.take(3).toList(),
      );
    });

// ── Coach remaining sessions this week ───────────────────────────────────────

/// Count of sessions remaining this week (from now until Sunday) for the
/// given discipline IDs. Uses getRecentSessions as a proxy because there is
/// no range-future query; sessions for the current week are typically already
/// persisted.
final coachRemainingWeekSessionsProvider = FutureProvider.autoDispose
    .family<int, List<String>>((ref, disciplineIds) async {
      final repo = ref.read(attendanceRepositoryProvider);
      final now = DateTime.now();
      // Monday = weekday 1, Sunday = 7
      final daysUntilSunday = 7 - now.weekday;
      final weekEnd = DateTime(
        now.year,
        now.month,
        now.day + daysUntilSunday + 1,
      );
      final sessions = await repo.getRecentSessions(100);
      return sessions.where((s) {
        if (!s.sessionDate.isBefore(weekEnd)) return false;
        if (disciplineIds.isNotEmpty &&
            !disciplineIds.contains(s.disciplineId)) {
          return false;
        }
        // Parse startTime "HH:mm" to determine if session is still upcoming
        final parts = s.startTime.split(':');
        if (parts.length < 2) return false;
        final sessionStart = DateTime(
          s.sessionDate.year,
          s.sessionDate.month,
          s.sessionDate.day,
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0,
        );
        return sessionStart.isAfter(now);
      }).length;
    });

// ── Coach discipline stats (enrolled / lapsed / PAYT) ─────────────────────────

class CoachDisciplineStats {
  const CoachDisciplineStats({
    required this.enrolled,
    required this.lapsed,
    required this.payt,
  });

  final int enrolled;
  final int lapsed;
  final int payt;
}

final coachDisciplineStatsProvider = FutureProvider.autoDispose
    .family<CoachDisciplineStats, String>((ref, disciplineId) async {
      final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
      final memberships =
          ref.read(membershipListProvider).asData?.value ?? <Membership>[];

      final enrollments = await enrollmentRepo.getForDiscipline(disciplineId);
      final enrolledProfileIds = enrollments.map((e) => e.studentId).toSet();

      var lapsed = 0;
      var payt = 0;

      for (final m in memberships) {
        final hasEnrolled = m.memberProfileIds.any(
          (id) => enrolledProfileIds.contains(id),
        );
        if (!hasEnrolled) continue;
        if (m.status == MembershipStatus.lapsed ||
            m.status == MembershipStatus.expired) {
          lapsed++;
        } else if (m.status == MembershipStatus.payt) {
          payt++;
        }
      }

      return CoachDisciplineStats(
        enrolled: enrollments.length,
        lapsed: lapsed,
        payt: payt,
      );
    });

// ── Sessions this week ────────────────────────────────────────────────────────

final sessionsThisWeekProvider =
    FutureProvider.autoDispose<({int sessionCount, int checkInCount})>((
      ref,
    ) async {
      final repo = ref.read(attendanceRepositoryProvider);
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartMidnight = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );
      final sessions = await repo.getRecentSessions(50);
      final thisWeekSessions = sessions
          .where((s) => s.sessionDate.isAfter(weekStartMidnight))
          .toList();
      final records = thisWeekSessions.isEmpty
          ? <AttendanceRecord>[]
          : await repo.getRecordsForPeriod(weekStartMidnight, now);
      return (
        sessionCount: thisWeekSessions.length,
        checkInCount: records.length,
      );
    });

// ── Upcoming grading ──────────────────────────────────────────────────────────

final upcomingGradingProvider = FutureProvider.autoDispose<GradingEvent?>((
  ref,
) async {
  final repo = ref.read(gradingEventRepositoryProvider);
  final events = await repo.getAll();
  final now = DateTime.now();
  final upcoming =
      events
          .where(
            (e) =>
                e.status == GradingEventStatus.upcoming &&
                e.eventDate.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  return upcoming.isEmpty ? null : upcoming.first;
});

// ── Student portal helpers ────────────────────────────────────────────────────

/// Children linked to a parent profile via parentProfileId or secondParentProfileId.
final childProfilesForParentProvider = Provider.family<List<Profile>, String>((
  ref,
  parentId,
) {
  final profiles = ref.watch(profileListProvider).asData?.value ?? [];
  return profiles
      .where(
        (p) =>
            p.parentProfileId == parentId ||
            p.secondParentProfileId == parentId,
      )
      .toList();
});

/// Active membership for a student profile — for student portal display.
final membershipForStudentPortalProvider = Provider.family<Membership?, String>(
  (ref, profileId) {
    final memberships = ref.watch(membershipListProvider).asData?.value ?? [];
    try {
      return memberships.firstWhere(
        (m) =>
            m.memberProfileIds.contains(profileId) &&
            (m.status == MembershipStatus.active ||
                m.status == MembershipStatus.trial ||
                m.status == MembershipStatus.payt),
      );
    } catch (_) {
      return null;
    }
  },
);
