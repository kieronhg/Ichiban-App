import 'package:equatable/equatable.dart';

class Rank extends Equatable {
  final String id;
  final String disciplineId;
  final String name;
  final int displayOrder;
  final String? colourHex;

  const Rank({
    required this.id,
    required this.disciplineId,
    required this.name,
    required this.displayOrder,
    this.colourHex,
  });

  Rank copyWith({
    String? id,
    String? disciplineId,
    String? name,
    int? displayOrder,
    String? colourHex,
  }) {
    return Rank(
      id: id ?? this.id,
      disciplineId: disciplineId ?? this.disciplineId,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
      colourHex: colourHex ?? this.colourHex,
    );
  }

  @override
  List<Object?> get props => [id, disciplineId, name, displayOrder, colourHex];
}
