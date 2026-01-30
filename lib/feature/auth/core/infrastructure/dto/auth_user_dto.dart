import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/entities/auth_user.dart';

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = 'client',
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String role;

  factory AuthUserDto.fromFirebase(
    firebase.User user, {
    DocumentSnapshot<Map<String, dynamic>>? profileDoc,
  }) {
    final data = profileDoc?.data();
    // ROOT FIX: If user was created with phone auth, email might not be in Firebase Auth
    // but will be in Firestore. Use Firestore email as fallback.
    final email = user.email ?? (data?['email'] as String?);
    return AuthUserDto(
      id: user.uid,
      email: email,
      displayName: user.displayName ?? data?['displayName'] as String?,
      photoUrl: user.photoURL ?? data?['photoUrl'] as String?,
      phoneNumber: user.phoneNumber ?? data?['phoneNumber'] as String?,
      role: data?['role'] as String? ?? 'client',
    );
  }

  AuthUser toDomain() => AuthUser(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        role: role,
      );

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'phoneNumber': phoneNumber,
        'role': role,
      };
}
