import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/infrastructure/firestore_field_readers.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/entities/auth_user.dart';

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.roles,
    this.primaryRole,
    this.role = 'client',
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final Map<String, bool>? roles;
  /// Firestore `primary_role` (`merchant` | `client`).
  final String? primaryRole;
  final String role;

  static Map<String, bool>? _normalizeRolesMap(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    return <String, bool>{
      'client': raw['client'] == true,
      'merchant': raw['merchant'] == true,
      'provider': raw['provider'] == true,
    };
  }

  static String _primaryRoleFromFlags(Map<String, bool> roles) {
    if (roles['merchant'] == true) return 'merchant';
    if (roles['client'] == true) return 'client';
    return 'client';
  }

  factory AuthUserDto.fromFirebase(
    firebase.User user, {
    DocumentSnapshot<Map<String, dynamic>>? profileDoc,
    String? oauthFirstName,
    String? oauthLastName,
  }) {
    final data = profileDoc?.data();
    // ROOT FIX: If user was created with phone auth, email might not be in Firebase Auth
    // but will be in Firestore. Use Firestore email as fallback.
    final email = user.email ?? (fsString(data?['email']));

    Map<String, bool>? rolesMap = _normalizeRolesMap(
      fsMap(data?['roles']),
    );
    String role = 'client';

    if (rolesMap != null) {
      role = _primaryRoleFromFlags(rolesMap);
    } else {
      final legacy = (fsString(data?['role']))?.toLowerCase();
      if (legacy == 'merchant') {
        role = 'merchant';
        rolesMap = const <String, bool>{
          'client': false,
          'merchant': true,
          'provider': false,
        };
      } else if (legacy == 'client') {
        role = 'client';
        rolesMap = const <String, bool>{
          'client': true,
          'merchant': false,
          'provider': false,
        };
      }
    }

    final primaryRaw = fsString(data?['primary_role']);
    final primaryNorm = primaryRaw?.toLowerCase();
    String? primaryRole = (primaryNorm == 'merchant' || primaryNorm == 'client')
        ? primaryNorm
        : null;

    // Align convenience [role] with signup intent when Firestore has primary_role.
    if (primaryRole == 'merchant') {
      role = 'merchant';
    } else if (primaryRole == 'client') {
      role = 'client';
    }

    final fsFirst = (fsString(data?['firstName']))?.trim() ?? '';
    final fsLast = (fsString(data?['lastName']))?.trim() ?? '';
    final oauthFirst = oauthFirstName?.trim() ?? '';
    final oauthLast = oauthLastName?.trim() ?? '';
    final resolvedFirst =
        fsFirst.isNotEmpty ? fsFirst : (oauthFirst.isNotEmpty ? oauthFirst : '');
    final resolvedLast =
        fsLast.isNotEmpty ? fsLast : (oauthLast.isNotEmpty ? oauthLast : '');
    String? displayName;
    if (resolvedFirst.isNotEmpty && resolvedLast.isNotEmpty) {
      displayName = '$resolvedFirst $resolvedLast';
    } else if (resolvedFirst.isNotEmpty) {
      displayName = resolvedFirst;
    } else if (resolvedLast.isNotEmpty) {
      displayName = resolvedLast;
    } else {
      displayName = user.displayName ?? fsString(data?['displayName']);
    }

    final fsPhoto = (fsString(data?['photoUrl']))?.trim();
    final authPhoto = user.photoURL?.trim();
    final photoUrl = (fsPhoto != null && fsPhoto.isNotEmpty)
        ? fsPhoto
        : (authPhoto != null && authPhoto.isNotEmpty ? authPhoto : null);

    return AuthUserDto(
      id: user.uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      phoneNumber: user.phoneNumber ?? fsString(data?['phone']),
      firstName: resolvedFirst.isNotEmpty ? resolvedFirst : null,
      lastName: resolvedLast.isNotEmpty ? resolvedLast : null,
      roles: rolesMap,
      primaryRole: primaryRole,
      role: role,
    );
  }

  AuthUser toDomain() => AuthUser(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        roles: roles,
        primaryRole: primaryRole,
        role: role,
      );

  /// Not used for `/users/{uid}` writes — profile updates go through [UserRepository].
  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'phoneNumber': phoneNumber,
      };
}
