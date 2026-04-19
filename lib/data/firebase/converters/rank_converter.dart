import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/rank.dart';
import '../../../domain/entities/enums.dart';

class RankConverter {
  RankConverter._();

  static Rank fromMap(
      String id, String disciplineId, Map<String, dynamic> map) {
    return Rank(
      id: id,
      disciplineId: disciplineId,
      name: map['name'] as String,
      displayOrder: (map['displayOrder'] as num).toInt(),
      colourHex: map['colourHex'] as String?,
      rankType: RankType.values.byName(map['rankType'] as String),
      monCount: (map['monCount'] as num?)?.toInt(),
      minAttendanceForGrading:
          (map['minAttendanceForGrading'] as num?)?.toInt(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> toMap(Rank rank) {
    return {
      'name': rank.name,
      'displayOrder': rank.displayOrder,
      'colourHex': rank.colourHex,
      'rankType': rank.rankType.name,
      'monCount': rank.monCount,
      'minAttendanceForGrading': rank.minAttendanceForGrading,
      'createdAt': Timestamp.fromDate(rank.createdAt),
    };
  }
}
