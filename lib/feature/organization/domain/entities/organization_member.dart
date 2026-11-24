import 'package:equatable/equatable.dart';

/// Role of a team member inside an enseigne.
enum OrganizationRole {
  /// Propriétaire: every store, billing, team.
  owner,

  /// Gérant: runs the stores in [OrganizationMember.storeIds].
  manager,

  /// Employé: scans and validates passages only.
  employee;

  static OrganizationRole fromFirestore(String? raw) => switch (raw) {
        'owner' => OrganizationRole.owner,
        'manager' => OrganizationRole.manager,
        _ => OrganizationRole.employee,
      };

  String get firestoreValue => name;

  String get label => switch (this) {
        OrganizationRole.owner => 'Propriétaire',
        OrganizationRole.manager => 'Gérant',
        OrganizationRole.employee => 'Employé',
      };

  /// Vitrine, promotions, notifications and CRM.
  bool get canManageStore => this != OrganizationRole.employee;
}

/// Membership of one user in one enseigne
/// (`organizations/{orgId}/members/{uid}`).
class OrganizationMember extends Equatable {
  const OrganizationMember({
    required this.uid,
    required this.orgId,
    required this.role,
    this.storeIds = const <String>[],
    this.isActive = true,
    this.displayName,
  });

  final String uid;
  final String orgId;
  final OrganizationRole role;

  /// Stores the member works in. Ignored for [OrganizationRole.owner],
  /// who has every store of the enseigne.
  final List<String> storeIds;
  final bool isActive;
  final String? displayName;

  bool worksIn(String merchantId) =>
      isActive &&
      (role == OrganizationRole.owner || storeIds.contains(merchantId));

  @override
  List<Object?> get props =>
      [uid, orgId, role, storeIds, isActive, displayName];
}
