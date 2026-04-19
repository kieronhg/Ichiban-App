import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/membership_pricing.dart';
import '../../domain/entities/app_setting.dart';
import '../../domain/entities/email_template.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/rank.dart';
import '../../domain/entities/enums.dart';
import '../../data/firebase/firestore_collections.dart';

/// One-time database seeder.
///
/// Seeds the following Firestore collections with default data:
///   - membershipPricing    (8 documents)
///   - appSettings          (8 documents — includes GDPR settings)
///   - emailTemplates       (4 documents)
///   - disciplines          (5 documents + rank subcollections)
///
/// All methods are idempotent — they check whether the collection already
/// has documents before writing, so running seed() multiple times is safe.
///
/// Usage: called from the Admin app Settings screen via a one-time setup button.
class DatabaseSeeder {
  DatabaseSeeder._();

  /// Placeholder admin ID used for seeded disciplines.
  /// Replace with real admin profile ID after first admin account is created.
  static const _seedAdminId = 'SEED_ADMIN';

  static Future<void> seed() async {
    await _seedMembershipPricing();
    await _seedAppSettings();
    await _seedEmailTemplates();
    await _seedDisciplines();
  }

  // ── Membership Pricing ─────────────────────────────────────────────────────

  static Future<void> _seedMembershipPricing() async {
    final snap =
        await FirestoreCollections.membershipPricing().limit(1).get();
    if (snap.docs.isNotEmpty) return;

    const prices = {
      'monthlyAdult': 33.00,
      'monthlyJunior': 25.00,
      'annualAdult': 330.00,
      'annualJunior': 242.00,
      'familyMonthlyUpToThree': 55.00,
      'familyMonthlyFourOrMore': 66.00,
      'payAsYouTrainAdult': 10.00,
      'payAsYouTrainJunior': 7.00,
    };

    final batch = FirebaseFirestore.instance.batch();
    for (final entry in prices.entries) {
      final ref = FirestoreCollections.membershipPricing().doc(entry.key);
      batch.set(ref, MembershipPricing(key: entry.key, amount: entry.value));
    }
    await batch.commit();
  }

  // ── App Settings ───────────────────────────────────────────────────────────

  static Future<void> _seedAppSettings() async {
    final snap = await FirestoreCollections.appSettings().limit(1).get();
    if (snap.docs.isNotEmpty) return;

    const settings = {
      // Dojo identity
      'dojoName': 'Ichiban',
      'dojoEmail': '',
      // Lapse & trial reminders
      'lapseReminderPreDueDays': 5,
      'lapseReminderPostDueDays': 5,
      'trialExpiryReminderDays': 2,
      // GDPR
      'privacyPolicyVersion': '1.0',
      'gdprRetentionMonths': 12,
      'financialRetentionYears': 7,
    };

    final batch = FirebaseFirestore.instance.batch();
    for (final entry in settings.entries) {
      final ref = FirestoreCollections.appSettings().doc(entry.key);
      batch.set(ref, AppSetting(key: entry.key, value: entry.value));
    }
    await batch.commit();
  }

  // ── Email Templates ────────────────────────────────────────────────────────

  static Future<void> _seedEmailTemplates() async {
    final snap = await FirestoreCollections.emailTemplates().limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final templates = [
      EmailTemplate(
        key: 'lapseReminderPreDue',
        subject: 'Your {{dojoName}} membership renewal is coming up',
        bodyHtml: '''
<p>Hi {{memberName}},</p>
<p>This is a friendly reminder that your membership at {{dojoName}} is due for renewal on <strong>{{renewalDate}}</strong>.</p>
<p>Your renewal amount is <strong>£{{amount}}</strong>.</p>
<p>Please ensure payment is made on time to avoid any interruption to your training.</p>
<p>If you have any questions, please contact us.</p>
<p>Best regards,<br>{{dojoName}}</p>
''',
      ),
      EmailTemplate(
        key: 'lapseReminderPostDue',
        subject: 'Action required: Your {{dojoName}} membership has lapsed',
        bodyHtml: '''
<p>Hi {{memberName}},</p>
<p>We notice that your membership renewal at {{dojoName}} was due on <strong>{{renewalDate}}</strong> and payment has not yet been received.</p>
<p>Your outstanding amount is <strong>£{{amount}}</strong>.</p>
<p>Please contact us as soon as possible to arrange payment and keep your membership active.</p>
<p>Best regards,<br>{{dojoName}}</p>
''',
      ),
      EmailTemplate(
        key: 'trialExpiring',
        subject: 'Your free trial at {{dojoName}} is ending soon',
        bodyHtml: '''
<p>Hi {{memberName}},</p>
<p>Your free trial at {{dojoName}} expires on <strong>{{trialEndDate}}</strong>.</p>
<p>We hope you have enjoyed your sessions with us! To continue training, please speak to a member of our team about joining as a full member.</p>
<p>We would love to have you stay with us.</p>
<p>Best regards,<br>{{dojoName}}</p>
''',
      ),
      EmailTemplate(
        key: 'gradingEligibility',
        subject: 'Congratulations — you have been selected for grading!',
        bodyHtml: '''
<p>Hi {{memberName}},</p>
<p>Congratulations! Your instructor has selected you as eligible for your next grading.</p>
<p>Your grading is scheduled for <strong>{{gradingDate}}</strong>.</p>
<p>Please ensure you are well prepared and arrive on time. If you have any questions, speak to your instructor.</p>
<p>Good luck!</p>
<p>Best regards,<br>{{dojoName}}</p>
''',
      ),
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (final template in templates) {
      final ref = FirestoreCollections.emailTemplates().doc(template.key);
      batch.set(ref, template);
    }
    await batch.commit();
  }

  // ── Disciplines & Ranks ────────────────────────────────────────────────────

  static Future<void> _seedDisciplines() async {
    final snap = await FirestoreCollections.disciplines().limit(1).get();
    if (snap.docs.isNotEmpty) return;

    for (final data in _disciplineSeedData) {
      final disciplineRef = FirestoreCollections.disciplines().doc();
      final now = DateTime.now();
      final discipline = Discipline(
        id: disciplineRef.id,
        name: data.name,
        description: data.description,
        isActive: true,
        createdByAdminId: _seedAdminId,
        createdAt: now,
      );

      final batch = FirebaseFirestore.instance.batch();
      batch.set(disciplineRef, discipline);

      for (final r in data.ranks) {
        final rankRef =
            FirestoreCollections.ranks(disciplineRef.id).doc();
        final rank = Rank(
          id: rankRef.id,
          disciplineId: disciplineRef.id,
          name: r.name,
          displayOrder: r.displayOrder,
          colourHex: r.colourHex,
          rankType: r.rankType,
          monCount: r.monCount,
          createdAt: now,
        );
        batch.set(rankRef, rank);
      }

      await batch.commit();
    }
  }

  // ── Seed Data ──────────────────────────────────────────────────────────────

  static final _disciplineSeedData = [
    // ── Karate ───────────────────────────────────────────────────────────────
    _DisciplineSeed(
      name: 'Karate',
      description: 'Traditional Japanese striking art.',
      ranks: [
        _RankSeed(1,  '9th Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(2,  '8th Kyu',              '#FF0000', RankType.kyu),
        _RankSeed(3,  '7th Kyu',              '#FFD700', RankType.kyu),
        _RankSeed(4,  '6th Kyu',              '#FFA500', RankType.kyu),
        _RankSeed(5,  '5th Kyu',              '#008000', RankType.kyu),
        _RankSeed(6,  '4th Kyu',              '#0000FF', RankType.kyu),
        _RankSeed(7,  '3rd Kyu',              '#800080', RankType.kyu),
        _RankSeed(8,  '2nd Kyu',              '#8B4513', RankType.kyu),
        _RankSeed(9,  '1st Kyu',              '#6B3410', RankType.kyu),
        _RankSeed(10, '1st Dan',              '#000000', RankType.dan),
        _RankSeed(11, '2nd Dan',              '#000000', RankType.dan),
        _RankSeed(12, '3rd Dan',              '#000000', RankType.dan),
        _RankSeed(13, '4th Dan',              '#000000', RankType.dan),
        _RankSeed(14, '5th Dan',              '#000000', RankType.dan),
      ],
    ),

    // ── Judo ─────────────────────────────────────────────────────────────────
    _DisciplineSeed(
      name: 'Judo',
      description: 'Olympic grappling and throwing art.',
      ranks: [
        // Junior Mon grades (ages 8–17)
        _RankSeed(1,  '1st Mon',              '#FF0000', RankType.mon, monCount: 0),
        _RankSeed(2,  '2nd Mon',              '#FF0000', RankType.mon, monCount: 1),
        _RankSeed(3,  '3rd Mon',              '#FF0000', RankType.mon, monCount: 2),
        _RankSeed(4,  '4th Mon',              '#FFD700', RankType.mon, monCount: 0),
        _RankSeed(5,  '5th Mon',              '#FFD700', RankType.mon, monCount: 1),
        _RankSeed(6,  '6th Mon',              '#FFD700', RankType.mon, monCount: 2),
        _RankSeed(7,  '7th Mon',              '#FFA500', RankType.mon, monCount: 0),
        _RankSeed(8,  '8th Mon',              '#FFA500', RankType.mon, monCount: 1),
        _RankSeed(9,  '9th Mon',              '#FFA500', RankType.mon, monCount: 2),
        _RankSeed(10, '10th Mon',             '#008000', RankType.mon, monCount: 0),
        _RankSeed(11, '11th Mon',             '#008000', RankType.mon, monCount: 1),
        _RankSeed(12, '12th Mon',             '#008000', RankType.mon, monCount: 2),
        _RankSeed(13, '13th Mon',             '#0000FF', RankType.mon, monCount: 0),
        _RankSeed(14, '14th Mon',             '#0000FF', RankType.mon, monCount: 1),
        _RankSeed(15, '15th Mon',             '#0000FF', RankType.mon, monCount: 2),
        _RankSeed(16, '16th Mon',             '#8B4513', RankType.mon, monCount: 0),
        _RankSeed(17, '17th Mon',             '#8B4513', RankType.mon, monCount: 1),
        _RankSeed(18, '18th Mon',             '#8B4513', RankType.mon, monCount: 2),
        // Adult Kyu grades
        _RankSeed(19, '6th Kyu',              '#FF0000', RankType.kyu),
        _RankSeed(20, '5th Kyu',              '#FFD700', RankType.kyu),
        _RankSeed(21, '4th Kyu',              '#FFA500', RankType.kyu),
        _RankSeed(22, '3rd Kyu',              '#008000', RankType.kyu),
        _RankSeed(23, '2nd Kyu',              '#0000FF', RankType.kyu),
        _RankSeed(24, '1st Kyu',              '#8B4513', RankType.kyu),
        // Dan grades
        _RankSeed(25, '1st Dan',              '#000000', RankType.dan),
        _RankSeed(26, '2nd Dan',              '#000000', RankType.dan),
        _RankSeed(27, '3rd Dan',              '#000000', RankType.dan),
        _RankSeed(28, '4th Dan',              '#000000', RankType.dan),
        _RankSeed(29, '5th Dan',              '#000000', RankType.dan),
      ],
    ),

    // ── Jujitsu ───────────────────────────────────────────────────────────────
    _DisciplineSeed(
      name: 'Jujitsu',
      description: 'Traditional Japanese grappling art.',
      ranks: [
        _RankSeed(1,  '8th Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(2,  '7th Kyu',              '#FFD700', RankType.kyu, monCount: 0),
        _RankSeed(3,  '7th Kyu (good)',        '#FFD700', RankType.kyu, monCount: 1),
        _RankSeed(4,  '7th Kyu (excellent)',   '#FFD700', RankType.kyu, monCount: 2),
        _RankSeed(5,  '7th Kyu (exceptional)', '#FFD700', RankType.kyu, monCount: 3),
        _RankSeed(6,  '6th Kyu',              '#FFA500', RankType.kyu, monCount: 0),
        _RankSeed(7,  '6th Kyu (good)',        '#FFA500', RankType.kyu, monCount: 1),
        _RankSeed(8,  '6th Kyu (excellent)',   '#FFA500', RankType.kyu, monCount: 2),
        _RankSeed(9,  '6th Kyu (exceptional)', '#FFA500', RankType.kyu, monCount: 3),
        _RankSeed(10, '5th Kyu',              '#008000', RankType.kyu),
        _RankSeed(11, '4th Kyu',              '#800080', RankType.kyu),
        _RankSeed(12, '3rd Kyu',              '#ADD8E6', RankType.kyu),
        _RankSeed(13, '2nd Kyu',              '#00008B', RankType.kyu),
        _RankSeed(14, '1st Kyu',              '#8B4513', RankType.kyu),
        _RankSeed(15, '1st Dan',              '#000000', RankType.dan),
        _RankSeed(16, '2nd Dan',              '#000000', RankType.dan),
        _RankSeed(17, '3rd Dan',              '#000000', RankType.dan),
        _RankSeed(18, '4th Dan',              '#000000', RankType.dan),
        _RankSeed(19, '5th Dan',              '#000000', RankType.dan),
      ],
    ),

    // ── Aikido ────────────────────────────────────────────────────────────────
    _DisciplineSeed(
      name: 'Aikido',
      description: 'Japanese martial art focused on redirecting force.',
      ranks: [
        _RankSeed(1,  'Ungraded',             '#FF0000', RankType.ungraded),
        _RankSeed(2,  '6th Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(3,  '5th Kyu',              '#FFD700', RankType.kyu),
        _RankSeed(4,  '4th Kyu',              '#FFA500', RankType.kyu),
        _RankSeed(5,  '3rd Kyu',              '#008000', RankType.kyu),
        _RankSeed(6,  '2nd Kyu',              '#0000FF', RankType.kyu),
        _RankSeed(7,  '1st Kyu',              '#8B4513', RankType.kyu),
        _RankSeed(8,  '1st Dan',              '#000000', RankType.dan),
        _RankSeed(9,  '2nd Dan',              '#000000', RankType.dan),
        _RankSeed(10, '3rd Dan',              '#000000', RankType.dan),
        _RankSeed(11, '4th Dan',              '#000000', RankType.dan),
        _RankSeed(12, '5th Dan',              '#000000', RankType.dan),
      ],
    ),

    // ── Kendo ─────────────────────────────────────────────────────────────────
    _DisciplineSeed(
      name: 'Kendo',
      description:
          'Japanese sword art using bamboo shinai. '
          'Note: belt colours are UI placeholders only — '
          'Kendo has no physical belt colours.',
      ranks: [
        _RankSeed(1,  '6th Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(2,  '5th Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(3,  '4th Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(4,  '3rd Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(5,  '2nd Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(6,  '1st Kyu',              '#FFFFFF', RankType.kyu),
        _RankSeed(7,  '1st Dan',              '#000000', RankType.dan),
        _RankSeed(8,  '2nd Dan',              '#000000', RankType.dan),
        _RankSeed(9,  '3rd Dan',              '#000000', RankType.dan),
        _RankSeed(10, '4th Dan',              '#000000', RankType.dan),
        _RankSeed(11, '5th Dan',              '#000000', RankType.dan),
      ],
    ),
  ];
}

// ── Internal seed helpers ──────────────────────────────────────────────────

class _DisciplineSeed {
  final String name;
  final String? description;
  final List<_RankSeed> ranks;
  const _DisciplineSeed({
    required this.name,
    this.description,
    required this.ranks,
  });
}

class _RankSeed {
  final int displayOrder;
  final String name;
  final String? colourHex;
  final RankType rankType;
  final int? monCount;

  const _RankSeed(
    this.displayOrder,
    this.name,
    this.colourHex,
    this.rankType, {
    this.monCount,
  });
}
