import 'package:equatable/equatable.dart';
import 'enums.dart';

class Rank extends Equatable {
  final String id;
  final String disciplineId;
  final String name;
  final int displayOrder;

  /// Belt/display colour as a hex string (e.g. "#FF0000").
  /// Null for ranks with no associated colour.
  final String? colourHex;

  /// Classifies the rank in the progression ladder.
  final RankType rankType;

  /// Number of tabs/mons at this grade level.
  /// Only set for ranks that use a mon/tab system (e.g. Judo junior grades,
  /// Jujitsu 7th & 6th Kyu). Null for all other ranks.
  final int? monCount;

  /// Minimum attended sessions required before a student is eligible to
  /// grade to this rank. Set by admin per rank. Null = no threshold set.
  final int? minAttendanceForGrading;

  final DateTime createdAt;

  const Rank({
    required this.id,
    required this.disciplineId,
    required this.name,
    required this.displayOrder,
    this.colourHex,
    required this.rankType,
    this.monCount,
    this.minAttendanceForGrading,
    required this.createdAt,
  });

  Rank copyWith({
    String? id,
    String? disciplineId,
    String? name,
    int? displayOrder,
    String? colourHex,
    RankType? rankType,
    int? monCount,
    int? minAttendanceForGrading,
    DateTime? createdAt,
  }) {
    return Rank(
      id: id ?? this.id,
      disciplineId: disciplineId ?? this.disciplineId,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
      colourHex: colourHex ?? this.colourHex,
      rankType: rankType ?? this.rankType,
      monCount: monCount ?? this.monCount,
      minAttendanceForGrading:
          minAttendanceForGrading ?? this.minAttendanceForGrading,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        disciplineId,
        name,
        displayOrder,
        colourHex,
        rankType,
        monCount,
        minAttendanceForGrading,
        createdAt,
      ];
}
