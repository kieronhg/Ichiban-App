import 'package:equatable/equatable.dart';
import 'enums.dart';

class DbsRecord extends Equatable {
  const DbsRecord({
    required this.status,
    this.certificateNumber,
    this.issueDate,
    this.expiryDate,
    this.lastUpdatedByAdminId,
    this.lastUpdatedAt,
    required this.pendingVerification,
    this.submittedByCoachAt,
  });

  final DbsStatus status;
  final String? certificateNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? lastUpdatedByAdminId;
  final DateTime? lastUpdatedAt;
  final bool pendingVerification;
  final DateTime? submittedByCoachAt;

  DbsRecord copyWith({
    DbsStatus? status,
    String? certificateNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? lastUpdatedByAdminId,
    DateTime? lastUpdatedAt,
    bool? pendingVerification,
    DateTime? submittedByCoachAt,
  }) {
    return DbsRecord(
      status: status ?? this.status,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      lastUpdatedByAdminId: lastUpdatedByAdminId ?? this.lastUpdatedByAdminId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      pendingVerification: pendingVerification ?? this.pendingVerification,
      submittedByCoachAt: submittedByCoachAt ?? this.submittedByCoachAt,
    );
  }

  static DbsRecord get defaults => const DbsRecord(
    status: DbsStatus.notSubmitted,
    pendingVerification: false,
  );

  @override
  List<Object?> get props => [
    status,
    certificateNumber,
    issueDate,
    expiryDate,
    lastUpdatedByAdminId,
    lastUpdatedAt,
    pendingVerification,
    submittedByCoachAt,
  ];
}

class FirstAidRecord extends Equatable {
  const FirstAidRecord({
    this.certificationName,
    this.issuingBody,
    this.issueDate,
    this.expiryDate,
    this.lastUpdatedByAdminId,
    this.lastUpdatedAt,
    required this.pendingVerification,
    this.submittedByCoachAt,
  });

  final String? certificationName;
  final String? issuingBody;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? lastUpdatedByAdminId;
  final DateTime? lastUpdatedAt;
  final bool pendingVerification;
  final DateTime? submittedByCoachAt;

  FirstAidRecord copyWith({
    String? certificationName,
    String? issuingBody,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? lastUpdatedByAdminId,
    DateTime? lastUpdatedAt,
    bool? pendingVerification,
    DateTime? submittedByCoachAt,
  }) {
    return FirstAidRecord(
      certificationName: certificationName ?? this.certificationName,
      issuingBody: issuingBody ?? this.issuingBody,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      lastUpdatedByAdminId: lastUpdatedByAdminId ?? this.lastUpdatedByAdminId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      pendingVerification: pendingVerification ?? this.pendingVerification,
      submittedByCoachAt: submittedByCoachAt ?? this.submittedByCoachAt,
    );
  }

  static FirstAidRecord get defaults =>
      const FirstAidRecord(pendingVerification: false);

  @override
  List<Object?> get props => [
    certificationName,
    issuingBody,
    issueDate,
    expiryDate,
    lastUpdatedByAdminId,
    lastUpdatedAt,
    pendingVerification,
    submittedByCoachAt,
  ];
}

class CoachProfile extends Equatable {
  const CoachProfile({
    required this.adminUserId,
    this.profileId,
    this.qualificationsNotes,
    required this.dbs,
    required this.firstAid,
    required this.createdAt,
    required this.createdByAdminId,
  });

  /// Document ID == Firebase Auth UID == adminUsers document ID.
  final String adminUserId;
  final String? profileId;
  final String? qualificationsNotes;
  final DbsRecord dbs;
  final FirstAidRecord firstAid;
  final DateTime createdAt;
  final String createdByAdminId;

  CoachProfile copyWith({
    String? adminUserId,
    String? profileId,
    String? qualificationsNotes,
    DbsRecord? dbs,
    FirstAidRecord? firstAid,
    DateTime? createdAt,
    String? createdByAdminId,
  }) {
    return CoachProfile(
      adminUserId: adminUserId ?? this.adminUserId,
      profileId: profileId ?? this.profileId,
      qualificationsNotes: qualificationsNotes ?? this.qualificationsNotes,
      dbs: dbs ?? this.dbs,
      firstAid: firstAid ?? this.firstAid,
      createdAt: createdAt ?? this.createdAt,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
    );
  }

  @override
  List<Object?> get props => [
    adminUserId,
    profileId,
    qualificationsNotes,
    dbs,
    firstAid,
    createdAt,
    createdByAdminId,
  ];
}
