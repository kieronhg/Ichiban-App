import 'package:equatable/equatable.dart';

class Discipline extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  /// Whether grading results include a numeric score for this discipline.
  /// True for Karate; false for all other disciplines by default.
  final bool hasGradingScore;

  /// Profile ID of the admin who created this discipline.
  final String createdByAdminId;

  final DateTime createdAt;

  const Discipline({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.hasGradingScore = false,
    required this.createdByAdminId,
    required this.createdAt,
  });

  Discipline copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    bool? hasGradingScore,
    String? createdByAdminId,
    DateTime? createdAt,
  }) {
    return Discipline(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      hasGradingScore: hasGradingScore ?? this.hasGradingScore,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    isActive,
    hasGradingScore,
    createdByAdminId,
    createdAt,
  ];
}
