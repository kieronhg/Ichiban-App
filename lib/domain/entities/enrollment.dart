import 'package:equatable/equatable.dart';

class Enrollment extends Equatable {
  final String id;
  final String studentId;
  final String disciplineId;
  final String currentRankId;
  final DateTime enrollmentDate;
  final bool isActive;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.disciplineId,
    required this.currentRankId,
    required this.enrollmentDate,
    required this.isActive,
  });

  Enrollment copyWith({
    String? id,
    String? studentId,
    String? disciplineId,
    String? currentRankId,
    DateTime? enrollmentDate,
    bool? isActive,
  }) {
    return Enrollment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      disciplineId: disciplineId ?? this.disciplineId,
      currentRankId: currentRankId ?? this.currentRankId,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    disciplineId,
    currentRankId,
    enrollmentDate,
    isActive,
  ];
}
