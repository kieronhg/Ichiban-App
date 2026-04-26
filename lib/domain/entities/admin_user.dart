import 'package:equatable/equatable.dart';
import 'enums.dart';

class AdminUser extends Equatable {
  const AdminUser({
    required this.firebaseUid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.assignedDisciplineIds,
    required this.isActive,
    this.profileId,
    required this.createdByAdminId,
    required this.createdAt,
    this.deactivatedAt,
    this.deactivatedByAdminId,
    this.lastLoginAt,
  });

  /// Firebase Auth UID — also the Firestore document ID.
  final String firebaseUid;
  final String email;
  final String firstName;
  final String lastName;
  final AdminRole role;

  /// Discipline IDs this coach can access. Empty for owners.
  final List<String> assignedDisciplineIds;

  /// False = deactivated; cannot log in.
  final bool isActive;

  /// Optional link to a member profile if this coach also trains.
  final String? profileId;

  final String createdByAdminId;
  final DateTime createdAt;
  final DateTime? deactivatedAt;
  final String? deactivatedByAdminId;
  final DateTime? lastLoginAt;

  String get fullName => '$firstName $lastName';

  bool get isOwner => role == AdminRole.owner;
  bool get isCoach => role == AdminRole.coach;

  @override
  List<Object?> get props => [
    firebaseUid,
    email,
    firstName,
    lastName,
    role,
    assignedDisciplineIds,
    isActive,
    profileId,
    createdByAdminId,
    createdAt,
    deactivatedAt,
    deactivatedByAdminId,
    lastLoginAt,
  ];
}
