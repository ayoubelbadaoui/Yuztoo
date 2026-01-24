import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/auth_failure.dart';
import '../domain/repositories/user_repository.dart';
import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/result.dart';
import '../../../types.dart';

/// Firebase implementation of UserRepository
class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Result<Unit>> createUserDocument({
    required String uid,
    required String email,
    required String phone,
    required Map<String, bool> roles,
    required String city,
  }) async {
    if (city.isEmpty) {
      return const Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(message: 'La ville est requise'),
      );
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'phone': phone,
        'roles': roles,
        'city': city,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));
      return const Right<AuthFailure, Unit>(unit);
    } catch (e, st) {
      return Left<AuthFailure, Unit>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la création du profil utilisateur: ${e.toString()}',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<UserRole?>> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Right<AuthFailure, UserRole?>(null);
      }

      final data = doc.data();
      if (data == null) {
        return const Right<AuthFailure, UserRole?>(null);
      }

      final roles = data['roles'] as Map<String, dynamic>?;
      if (roles == null) {
        return const Right<AuthFailure, UserRole?>(null);
      }

      // Check if user is merchant
      if (roles['merchant'] == true) {
        return const Right<AuthFailure, UserRole?>(UserRole.merchant);
      }

      // Default to client
      return const Right<AuthFailure, UserRole?>(UserRole.client);
    } catch (e, st) {
      return Left<AuthFailure, UserRole?>(
        AuthUnexpectedFailure(
          message: 'Erreur lors de la récupération du rôle utilisateur',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}

