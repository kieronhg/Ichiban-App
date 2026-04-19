import 'package:equatable/equatable.dart';

class Discipline extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  /// Profile ID of the admin who created this discipline.
  final String createdByAdminId;

  final DateTime createdAt;

  const Discipline({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdByAdminId,
    required this.createdAt,
  });

  Discipline copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    String? createdByAdminId,
    DateTime? createdAt,
  }) {
    return Discipline(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, isActive, createdByAdminId, createdAt];
}
