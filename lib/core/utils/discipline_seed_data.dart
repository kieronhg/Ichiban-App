import '../../domain/entities/discipline.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/rank.dart';

/// Pre-built discipline + rank templates shown in the setup wizard Step 4.
///
/// The owner picks which disciplines their dojo teaches. The wizard seeds
/// the selected ones into Firestore. IDs are generated at call-time so
/// multiple seedings never clash.
class DisciplineSeedData {
  DisciplineSeedData._();

  /// Returns the full catalogue of seedable discipline templates.
  static List<DisciplineTemplate> get templates => [
    DisciplineTemplate(
      key: 'karate',
      name: 'Karate',
      description: 'Traditional striking art with kyu/dan belt progression.',
      hasGradingScore: true,
      ranks: _karateRanks,
    ),
    DisciplineTemplate(
      key: 'judo',
      name: 'Judo',
      description: 'Olympic throwing art with kyu/dan belt progression.',
      hasGradingScore: false,
      ranks: _judoRanks,
    ),
    DisciplineTemplate(
      key: 'jujitsu',
      name: 'Jujitsu',
      description: 'Traditional grappling art with mon/kyu/dan progression.',
      hasGradingScore: false,
      ranks: _jujitsuRanks,
    ),
    DisciplineTemplate(
      key: 'kickboxing',
      name: 'Kickboxing',
      description: 'Stand-up striking sport with tag/belt progression.',
      hasGradingScore: false,
      ranks: _kickboxingRanks,
    ),
    DisciplineTemplate(
      key: 'mma',
      name: 'MMA',
      description: 'Mixed martial arts — no formal grading system.',
      hasGradingScore: false,
      ranks: _mmaRanks,
    ),
  ];
}

// ── Rank template builders ─────────────────────────────────────────────────

/// A lightweight template; actual [Rank] / [Discipline] objects are built
/// when the wizard seeds data so they can use real Firestore IDs.
class DisciplineTemplate {
  const DisciplineTemplate({
    required this.key,
    required this.name,
    this.description,
    required this.hasGradingScore,
    required this.ranks,
  });

  /// Unique key within the template list (not persisted).
  final String key;
  final String name;
  final String? description;
  final bool hasGradingScore;
  final List<RankTemplate> ranks;

  /// Build a [Discipline] entity, using [id] and [createdByAdminId] from the caller.
  Discipline toDiscipline({
    required String id,
    required String createdByAdminId,
  }) {
    return Discipline(
      id: id,
      name: name,
      description: description,
      isActive: true,
      hasGradingScore: hasGradingScore,
      createdByAdminId: createdByAdminId,
      createdAt: DateTime.now(),
    );
  }
}

class RankTemplate {
  const RankTemplate({
    required this.name,
    required this.displayOrder,
    required this.rankType,
    this.colourHex,
    this.monCount,
  });

  final String name;
  final int displayOrder;
  final RankType rankType;
  final String? colourHex;
  final int? monCount;

  /// Build a [Rank] entity from this template.
  Rank toRank({required String id, required String disciplineId}) {
    return Rank(
      id: id,
      disciplineId: disciplineId,
      name: name,
      displayOrder: displayOrder,
      rankType: rankType,
      colourHex: colourHex,
      monCount: monCount,
      createdAt: DateTime.now(),
    );
  }
}

// ── Karate ─────────────────────────────────────────────────────────────────

const _karateRanks = [
  RankTemplate(
    name: 'Ungraded',
    displayOrder: 0,
    rankType: RankType.ungraded,
    colourHex: '#FFFFFF',
  ),
  RankTemplate(
    name: '9th Kyu',
    displayOrder: 1,
    rankType: RankType.kyu,
    colourHex: '#FFFFFF',
  ),
  RankTemplate(
    name: '8th Kyu',
    displayOrder: 2,
    rankType: RankType.kyu,
    colourHex: '#FFFF00',
  ),
  RankTemplate(
    name: '7th Kyu',
    displayOrder: 3,
    rankType: RankType.kyu,
    colourHex: '#FF8C00',
  ),
  RankTemplate(
    name: '6th Kyu',
    displayOrder: 4,
    rankType: RankType.kyu,
    colourHex: '#008000',
  ),
  RankTemplate(
    name: '5th Kyu',
    displayOrder: 5,
    rankType: RankType.kyu,
    colourHex: '#0000FF',
  ),
  RankTemplate(
    name: '4th Kyu',
    displayOrder: 6,
    rankType: RankType.kyu,
    colourHex: '#8B008B',
  ),
  RankTemplate(
    name: '3rd Kyu',
    displayOrder: 7,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: '2nd Kyu',
    displayOrder: 8,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: '1st Kyu',
    displayOrder: 9,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: '1st Dan',
    displayOrder: 10,
    rankType: RankType.dan,
    colourHex: '#000000',
  ),
  RankTemplate(
    name: '2nd Dan',
    displayOrder: 11,
    rankType: RankType.dan,
    colourHex: '#000000',
  ),
  RankTemplate(
    name: '3rd Dan',
    displayOrder: 12,
    rankType: RankType.dan,
    colourHex: '#000000',
  ),
];

// ── Judo ───────────────────────────────────────────────────────────────────

const _judoRanks = [
  RankTemplate(
    name: 'Ungraded',
    displayOrder: 0,
    rankType: RankType.ungraded,
    colourHex: '#FFFFFF',
  ),
  RankTemplate(
    name: '6th Mon',
    displayOrder: 1,
    rankType: RankType.mon,
    colourHex: '#FFFFFF',
    monCount: 6,
  ),
  RankTemplate(
    name: '5th Mon',
    displayOrder: 2,
    rankType: RankType.mon,
    colourHex: '#FFFF00',
    monCount: 5,
  ),
  RankTemplate(
    name: '4th Mon',
    displayOrder: 3,
    rankType: RankType.mon,
    colourHex: '#FF8C00',
    monCount: 4,
  ),
  RankTemplate(
    name: '3rd Mon',
    displayOrder: 4,
    rankType: RankType.mon,
    colourHex: '#008000',
    monCount: 3,
  ),
  RankTemplate(
    name: '2nd Mon',
    displayOrder: 5,
    rankType: RankType.mon,
    colourHex: '#0000FF',
    monCount: 2,
  ),
  RankTemplate(
    name: '1st Mon',
    displayOrder: 6,
    rankType: RankType.mon,
    colourHex: '#8B4513',
    monCount: 1,
  ),
  RankTemplate(
    name: '5th Kyu',
    displayOrder: 7,
    rankType: RankType.kyu,
    colourHex: '#FFFF00',
  ),
  RankTemplate(
    name: '4th Kyu',
    displayOrder: 8,
    rankType: RankType.kyu,
    colourHex: '#FF8C00',
  ),
  RankTemplate(
    name: '3rd Kyu',
    displayOrder: 9,
    rankType: RankType.kyu,
    colourHex: '#008000',
  ),
  RankTemplate(
    name: '2nd Kyu',
    displayOrder: 10,
    rankType: RankType.kyu,
    colourHex: '#0000FF',
  ),
  RankTemplate(
    name: '1st Kyu',
    displayOrder: 11,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: '1st Dan',
    displayOrder: 12,
    rankType: RankType.dan,
    colourHex: '#000000',
  ),
];

// ── Jujitsu ────────────────────────────────────────────────────────────────

const _jujitsuRanks = [
  RankTemplate(
    name: 'Ungraded',
    displayOrder: 0,
    rankType: RankType.ungraded,
    colourHex: '#FFFFFF',
  ),
  RankTemplate(
    name: '9th Kyu',
    displayOrder: 1,
    rankType: RankType.kyu,
    colourHex: '#FFFF00',
  ),
  RankTemplate(
    name: '8th Kyu',
    displayOrder: 2,
    rankType: RankType.kyu,
    colourHex: '#FF8C00',
  ),
  RankTemplate(
    name: '7th Kyu — 3 Mon',
    displayOrder: 3,
    rankType: RankType.mon,
    colourHex: '#008000',
    monCount: 3,
  ),
  RankTemplate(
    name: '7th Kyu — 2 Mon',
    displayOrder: 4,
    rankType: RankType.mon,
    colourHex: '#008000',
    monCount: 2,
  ),
  RankTemplate(
    name: '7th Kyu — 1 Mon',
    displayOrder: 5,
    rankType: RankType.mon,
    colourHex: '#008000',
    monCount: 1,
  ),
  RankTemplate(
    name: '7th Kyu',
    displayOrder: 6,
    rankType: RankType.kyu,
    colourHex: '#008000',
  ),
  RankTemplate(
    name: '6th Kyu — 3 Mon',
    displayOrder: 7,
    rankType: RankType.mon,
    colourHex: '#0000FF',
    monCount: 3,
  ),
  RankTemplate(
    name: '6th Kyu — 2 Mon',
    displayOrder: 8,
    rankType: RankType.mon,
    colourHex: '#0000FF',
    monCount: 2,
  ),
  RankTemplate(
    name: '6th Kyu — 1 Mon',
    displayOrder: 9,
    rankType: RankType.mon,
    colourHex: '#0000FF',
    monCount: 1,
  ),
  RankTemplate(
    name: '6th Kyu',
    displayOrder: 10,
    rankType: RankType.kyu,
    colourHex: '#0000FF',
  ),
  RankTemplate(
    name: '5th Kyu',
    displayOrder: 11,
    rankType: RankType.kyu,
    colourHex: '#8B008B',
  ),
  RankTemplate(
    name: '4th Kyu',
    displayOrder: 12,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: '3rd Kyu',
    displayOrder: 13,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: '2nd Kyu',
    displayOrder: 14,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: '1st Kyu',
    displayOrder: 15,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: '1st Dan',
    displayOrder: 16,
    rankType: RankType.dan,
    colourHex: '#000000',
  ),
];

// ── Kickboxing ─────────────────────────────────────────────────────────────

const _kickboxingRanks = [
  RankTemplate(
    name: 'Ungraded',
    displayOrder: 0,
    rankType: RankType.ungraded,
    colourHex: '#FFFFFF',
  ),
  RankTemplate(
    name: 'White Tag',
    displayOrder: 1,
    rankType: RankType.kyu,
    colourHex: '#FFFFFF',
  ),
  RankTemplate(
    name: 'Yellow Tag',
    displayOrder: 2,
    rankType: RankType.kyu,
    colourHex: '#FFFF00',
  ),
  RankTemplate(
    name: 'Orange Tag',
    displayOrder: 3,
    rankType: RankType.kyu,
    colourHex: '#FF8C00',
  ),
  RankTemplate(
    name: 'Green Tag',
    displayOrder: 4,
    rankType: RankType.kyu,
    colourHex: '#008000',
  ),
  RankTemplate(
    name: 'Blue Tag',
    displayOrder: 5,
    rankType: RankType.kyu,
    colourHex: '#0000FF',
  ),
  RankTemplate(
    name: 'Purple Tag',
    displayOrder: 6,
    rankType: RankType.kyu,
    colourHex: '#8B008B',
  ),
  RankTemplate(
    name: 'Brown Tag',
    displayOrder: 7,
    rankType: RankType.kyu,
    colourHex: '#8B4513',
  ),
  RankTemplate(
    name: 'Red Tag',
    displayOrder: 8,
    rankType: RankType.kyu,
    colourHex: '#FF0000',
  ),
  RankTemplate(
    name: 'Black Tag',
    displayOrder: 9,
    rankType: RankType.kyu,
    colourHex: '#000000',
  ),
  RankTemplate(
    name: '1st Dan',
    displayOrder: 10,
    rankType: RankType.dan,
    colourHex: '#000000',
  ),
];

// ── MMA ────────────────────────────────────────────────────────────────────

const _mmaRanks = [
  RankTemplate(name: 'Beginner', displayOrder: 0, rankType: RankType.ungraded),
  RankTemplate(name: 'Intermediate', displayOrder: 1, rankType: RankType.kyu),
  RankTemplate(name: 'Advanced', displayOrder: 2, rankType: RankType.kyu),
  RankTemplate(name: 'Elite', displayOrder: 3, rankType: RankType.dan),
];
