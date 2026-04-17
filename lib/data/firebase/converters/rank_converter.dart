import '../../../domain/entities/rank.dart';

class RankConverter {
  RankConverter._();

  static Rank fromMap(String id, String disciplineId, Map<String, dynamic> map) {
    return Rank(
      id: id,
      disciplineId: disciplineId,
      name: map['name'] as String,
      displayOrder: (map['displayOrder'] as num).toInt(),
      colourHex: map['colourHex'] as String?,
    );
  }

  static Map<String, dynamic> toMap(Rank rank) {
    return {
      'name': rank.name,
      'displayOrder': rank.displayOrder,
      'colourHex': rank.colourHex,
    };
  }
}
