import '../../../domain/entities/discipline.dart';

class DisciplineConverter {
  DisciplineConverter._();

  static Discipline fromMap(String id, Map<String, dynamic> map) {
    return Discipline(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: map['isActive'] as bool,
    );
  }

  static Map<String, dynamic> toMap(Discipline discipline) {
    return {
      'name': discipline.name,
      'description': discipline.description,
      'isActive': discipline.isActive,
    };
  }
}
