import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/membership_pricing.dart';
import '../../domain/entities/app_setting.dart';
import '../../domain/entities/email_template.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/rank.dart';
import '../../data/firebase/firestore_collections.dart';

/// One-time database seeder.
///
/// Seeds the following Firestore collections with default data:
///   - membershipPricing    (8 documents)
///   - appSettings          (5 documents)
///   - emailTemplates       (4 documents)
///   - disciplines          (5 documents + rank subcollections)
///
/// All methods are idempotent — they check whether the collection already
/// has documents before writing, so running seed() multiple times is safe.
///
/// Usage: called from the Admin app Settings screen via a one-time setup button.
class DatabaseSeeder {
  DatabaseSeeder._();

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
      'lapseReminderPreDueDays': 5,
      'lapseReminderPostDueDays': 5,
      'trialExpiryReminderDays': 2,
      'dojoName': 'Ichiban',
      'dojoEmail': '',
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
      // Create discipline document with auto-generated ID
      final disciplineRef = FirestoreCollections.disciplines().doc();
      final discipline = Discipline(
        id: disciplineRef.id,
        name: data['name'] as String,
        description: data['description'] as String?,
        isActive: true,
      );

      final batch = FirebaseFirestore.instance.batch();
      batch.set(disciplineRef, discipline);

      // Create rank subcollection documents
      final ranks = data['ranks'] as List<_RankSeed>;
      for (int i = 0; i < ranks.length; i++) {
        final rankRef =
            FirestoreCollections.ranks(disciplineRef.id).doc();
        final rank = Rank(
          id: rankRef.id,
          disciplineId: disciplineRef.id,
          name: ranks[i].name,
          displayOrder: i,
          colourHex: ranks[i].colourHex,
        );
        batch.set(rankRef, rank);
      }

      await batch.commit();
    }
  }

  // ── Seed Data ──────────────────────────────────────────────────────────────

  static final _disciplineSeedData = [
    {
      'name': 'Karate',
      'description': 'Traditional Japanese striking art.',
      'ranks': [
        _RankSeed('9th Kyu', '#FFFFFF'),
        _RankSeed('8th Kyu', '#FFEB3B'),
        _RankSeed('7th Kyu', '#FF9800'),
        _RankSeed('6th Kyu', '#F44336'),
        _RankSeed('5th Kyu', '#FFEB3B'),
        _RankSeed('4th Kyu', '#4CAF50'),
        _RankSeed('3rd Kyu', '#9C27B0'),
        _RankSeed('2nd Kyu', '#795548'),
        _RankSeed('1st Kyu', '#795548'),
        _RankSeed('1st Dan (Shodan)', '#212121'),
        _RankSeed('2nd Dan (Nidan)', '#212121'),
        _RankSeed('3rd Dan (Sandan)', '#212121'),
      ],
    },
    {
      'name': 'Judo',
      'description': 'Olympic grappling and throwing art.',
      'ranks': [
        _RankSeed('6th Kyu', '#FFFFFF'),
        _RankSeed('5th Kyu', '#FFEB3B'),
        _RankSeed('4th Kyu', '#FF9800'),
        _RankSeed('3rd Kyu', '#4CAF50'),
        _RankSeed('2nd Kyu', '#2196F3'),
        _RankSeed('1st Kyu', '#795548'),
        _RankSeed('1st Dan', '#212121'),
        _RankSeed('2nd Dan', '#212121'),
        _RankSeed('3rd Dan', '#212121'),
      ],
    },
    {
      'name': 'Jujitsu',
      'description': 'Traditional Japanese grappling art.',
      'ranks': [
        _RankSeed('White Belt', '#FFFFFF'),
        _RankSeed('Yellow Belt', '#FFEB3B'),
        _RankSeed('Orange Belt', '#FF9800'),
        _RankSeed('Green Belt', '#4CAF50'),
        _RankSeed('Blue Belt', '#2196F3'),
        _RankSeed('Purple Belt', '#9C27B0'),
        _RankSeed('Brown Belt', '#795548'),
        _RankSeed('Black Belt', '#212121'),
      ],
    },
    {
      'name': 'Aikido',
      'description': 'Japanese martial art focused on redirecting force.',
      'ranks': [
        _RankSeed('5th Kyu', '#FFFFFF'),
        _RankSeed('4th Kyu', '#FFEB3B'),
        _RankSeed('3rd Kyu', '#FF9800'),
        _RankSeed('2nd Kyu', '#4CAF50'),
        _RankSeed('1st Kyu', '#795548'),
        _RankSeed('1st Dan (Shodan)', '#212121'),
        _RankSeed('2nd Dan (Nidan)', '#212121'),
        _RankSeed('3rd Dan (Sandan)', '#212121'),
      ],
    },
    {
      'name': 'Kendo',
      'description': 'Japanese sword art using bamboo shinai.',
      'ranks': [
        _RankSeed('6th Kyu', '#FFFFFF'),
        _RankSeed('5th Kyu', '#FFFFFF'),
        _RankSeed('4th Kyu', '#FFFFFF'),
        _RankSeed('3rd Kyu', '#FFFFFF'),
        _RankSeed('2nd Kyu', '#FFFFFF'),
        _RankSeed('1st Kyu', '#FFFFFF'),
        _RankSeed('1st Dan', '#212121'),
        _RankSeed('2nd Dan', '#212121'),
        _RankSeed('3rd Dan', '#212121'),
      ],
    },
  ];
}

class _RankSeed {
  final String name;
  final String colourHex;
  const _RankSeed(this.name, this.colourHex);
}
