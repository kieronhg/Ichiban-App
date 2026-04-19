import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/discipline.dart';

class DisciplineConverter {
  DisciplineConverter._();

  static Discipline fromMap(String id, Map<String, dynamic> map) {
    return Discipline(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: map['isActive'] as bool,
      createdByAdminId: map['createdByAdminId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> toMap(Discipline discipline) {
    return {
      'name': discipline.name,
      'description': discipline.description,
      'isActive': discipline.isActive,
      'createdByAdminId': discipline.createdByAdminId,
      'createdAt': Timestamp.fromDate(discipline.createdAt),
    };
  }
}
