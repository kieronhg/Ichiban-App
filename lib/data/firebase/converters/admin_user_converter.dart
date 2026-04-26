import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/admin_user.dart';
import '../../../domain/entities/enums.dart';

class AdminUserConverter {
  AdminUserConverter._();

  static AdminUser fromMap(String id, Map<String, dynamic> map) {
    return AdminUser(
      firebaseUid: id,
      email: map['email'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      role: AdminRole.values.byName(map['role'] as String),
      assignedDisciplineIds: List<String>.from(
        map['assignedDisciplineIds'] as List? ?? [],
      ),
      isActive: map['isActive'] as bool,
      profileId: map['profileId'] as String?,
      createdByAdminId: map['createdByAdminId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deactivatedAt: (map['deactivatedAt'] as Timestamp?)?.toDate(),
      deactivatedByAdminId: map['deactivatedByAdminId'] as String?,
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(AdminUser adminUser) {
    return {
      'email': adminUser.email,
      'firstName': adminUser.firstName,
      'lastName': adminUser.lastName,
      'role': adminUser.role.name,
      'assignedDisciplineIds': adminUser.assignedDisciplineIds,
      'isActive': adminUser.isActive,
      'profileId': adminUser.profileId,
      'createdByAdminId': adminUser.createdByAdminId,
      'createdAt': Timestamp.fromDate(adminUser.createdAt),
      'deactivatedAt': adminUser.deactivatedAt != null
          ? Timestamp.fromDate(adminUser.deactivatedAt!)
          : null,
      'deactivatedByAdminId': adminUser.deactivatedByAdminId,
      'lastLoginAt': adminUser.lastLoginAt != null
          ? Timestamp.fromDate(adminUser.lastLoginAt!)
          : null,
    };
  }
}
