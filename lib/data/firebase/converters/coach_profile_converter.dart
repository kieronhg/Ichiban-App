import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/coach_profile.dart';
import '../../../domain/entities/enums.dart';

class CoachProfileConverter {
  CoachProfileConverter._();

  static CoachProfile fromMap(String id, Map<String, dynamic> map) {
    return CoachProfile(
      adminUserId: id,
      profileId: map['profileId'] as String?,
      qualificationsNotes: map['qualificationsNotes'] as String?,
      dbs: dbsFromMap(map['dbs'] as Map<String, dynamic>? ?? {}),
      firstAid: firstAidFromMap(map['firstAid'] as Map<String, dynamic>? ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdByAdminId: map['createdByAdminId'] as String,
    );
  }

  static Map<String, dynamic> toMap(CoachProfile p) {
    return {
      'profileId': p.profileId,
      'qualificationsNotes': p.qualificationsNotes,
      'dbs': dbsToMap(p.dbs),
      'firstAid': firstAidToMap(p.firstAid),
      'createdAt': Timestamp.fromDate(p.createdAt),
      'createdByAdminId': p.createdByAdminId,
    };
  }

  static DbsRecord dbsFromMap(Map<String, dynamic> m) {
    return DbsRecord(
      status: DbsStatus.values.byName(
        (m['status'] as String?) ?? DbsStatus.notSubmitted.name,
      ),
      certificateNumber: m['certificateNumber'] as String?,
      issueDate: (m['issueDate'] as Timestamp?)?.toDate(),
      expiryDate: (m['expiryDate'] as Timestamp?)?.toDate(),
      lastUpdatedByAdminId: m['lastUpdatedByAdminId'] as String?,
      lastUpdatedAt: (m['lastUpdatedAt'] as Timestamp?)?.toDate(),
      pendingVerification: (m['pendingVerification'] as bool?) ?? false,
      submittedByCoachAt: (m['submittedByCoachAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> dbsToMap(DbsRecord d) {
    return {
      'status': d.status.name,
      'certificateNumber': d.certificateNumber,
      'issueDate': d.issueDate != null
          ? Timestamp.fromDate(d.issueDate!)
          : null,
      'expiryDate': d.expiryDate != null
          ? Timestamp.fromDate(d.expiryDate!)
          : null,
      'lastUpdatedByAdminId': d.lastUpdatedByAdminId,
      'lastUpdatedAt': d.lastUpdatedAt != null
          ? Timestamp.fromDate(d.lastUpdatedAt!)
          : null,
      'pendingVerification': d.pendingVerification,
      'submittedByCoachAt': d.submittedByCoachAt != null
          ? Timestamp.fromDate(d.submittedByCoachAt!)
          : null,
    };
  }

  static FirstAidRecord firstAidFromMap(Map<String, dynamic> m) {
    return FirstAidRecord(
      certificationName: m['certificationName'] as String?,
      issuingBody: m['issuingBody'] as String?,
      issueDate: (m['issueDate'] as Timestamp?)?.toDate(),
      expiryDate: (m['expiryDate'] as Timestamp?)?.toDate(),
      lastUpdatedByAdminId: m['lastUpdatedByAdminId'] as String?,
      lastUpdatedAt: (m['lastUpdatedAt'] as Timestamp?)?.toDate(),
      pendingVerification: (m['pendingVerification'] as bool?) ?? false,
      submittedByCoachAt: (m['submittedByCoachAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> firstAidToMap(FirstAidRecord f) {
    return {
      'certificationName': f.certificationName,
      'issuingBody': f.issuingBody,
      'issueDate': f.issueDate != null
          ? Timestamp.fromDate(f.issueDate!)
          : null,
      'expiryDate': f.expiryDate != null
          ? Timestamp.fromDate(f.expiryDate!)
          : null,
      'lastUpdatedByAdminId': f.lastUpdatedByAdminId,
      'lastUpdatedAt': f.lastUpdatedAt != null
          ? Timestamp.fromDate(f.lastUpdatedAt!)
          : null,
      'pendingVerification': f.pendingVerification,
      'submittedByCoachAt': f.submittedByCoachAt != null
          ? Timestamp.fromDate(f.submittedByCoachAt!)
          : null,
    };
  }
}
