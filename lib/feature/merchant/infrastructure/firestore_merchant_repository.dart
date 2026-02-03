import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/merchant.dart';
import '../domain/merchant_failure.dart';
import '../domain/repositories/merchant_repository.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import 'dto/merchant_dto.dart';

/// Timeout constants for Firestore operations
class FirestoreTimeouts {
  static const Duration getOperation = Duration(seconds: 10);
  static const Duration writeOperation = Duration(seconds: 30);
  static const Duration batchOperation = Duration(seconds: 30);
  static const Duration queryOperation = Duration(seconds: 15);
}

/// Firebase Firestore implementation of MerchantRepository.
class FirestoreMerchantRepository implements MerchantRepository {
  FirestoreMerchantRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Result<bool>> merchantExists(String ownerUid) async {
    if (ownerUid.isEmpty) {
      return const Right<MerchantFailure, bool>(false);
    }

    try {
      final querySnapshot = await _firestore
          .collection('merchants')
          .where('owner_uid', isEqualTo: ownerUid)
          .limit(1)
          .get();

      final exists = querySnapshot.docs.isNotEmpty;
      LoggerService.logInfo(
        'Merchant existence check',
        context: {'ownerUid': ownerUid, 'exists': exists},
      );
      return Right<MerchantFailure, bool>(exists);
    } catch (e, st) {
      LoggerService.logError(
        'Error checking merchant existence',
        error: e,
        stackTrace: st,
        context: {'ownerUid': ownerUid},
      );
      return Left<MerchantFailure, bool>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  }) async {
    // Validate merchant data
    if (!merchant.isValid()) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Unable to create merchant / Impossible de créer le profil commerçant',
        ),
      );
    }

    // For MVP: merchantId == user.uid
    // Use userId as merchantId (merchant.id should already be set to userId in use case)
    final merchantId = merchant.id.isNotEmpty
        ? merchant.id
        : userId; // Fallback to userId if merchant.id is empty

    try {
      // Create batch write for atomic operation
      final batch = _firestore.batch();

      // Create merchant document
      final merchantRef = _firestore.collection('merchants').doc(merchantId);
      final merchantDto = MerchantDto.fromDomain(
        merchant.copyWith(id: merchantId),
      );
      batch.set(merchantRef, merchantDto.toFirestore(), SetOptions(merge: false));

      // Update user document with merchant_id and mark onboarding as complete
      // Use set(merge: true) instead of update to handle case where user document might not exist
      // (though it should exist at this point in the flow)
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(userRef, {
        'merchant_id': merchantId,
        'onboarding': {
          'merchant': true,
        },
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Commit batch write atomically with timeout
      // FIX HIGH 3: Add timeout for batch operations
      await batch.commit().timeout(
        FirestoreTimeouts.batchOperation,
        onTimeout: () {
          throw TimeoutException(
            'Merchant creation timed out',
            FirestoreTimeouts.batchOperation,
          );
        },
      );

      // Fetch the created merchant to return with server timestamps
      // FIX HIGH 3: Add timeout for get operations
      final createdDoc = await merchantRef.get().timeout(
        FirestoreTimeouts.getOperation,
        onTimeout: () {
          throw TimeoutException(
            'Merchant fetch timed out',
            FirestoreTimeouts.getOperation,
          );
        },
      );
      if (!createdDoc.exists) {
        LoggerService.logError(
          'Merchant document not found after creation',
          context: {'merchantId': merchantId, 'userId': userId},
        );
        return const Left<MerchantFailure, Merchant>(
          UnableToCreateMerchantFailure(
            message: 'Unable to create merchant / Impossible de créer le profil commerçant',
          ),
        );
      }

      final createdMerchant = MerchantDto.fromFirestore(createdDoc).toDomain();
      LoggerService.logInfo(
        'Merchant created and linked to user successfully',
        context: {
          'merchantId': merchantId,
          'userId': userId,
          'merchantName': merchant.name,
        },
      );

      return Right<MerchantFailure, Merchant>(createdMerchant);
    } on TimeoutException catch (e, st) {
      // FIX HIGH 3: Handle timeout errors specifically
      LoggerService.logError(
        'Timeout creating merchant',
        error: e,
        stackTrace: st,
        context: {
          'merchantId': merchantId,
          'userId': userId,
          'timeout': e.duration?.inSeconds,
        },
      );
      return Left<MerchantFailure, Merchant>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error creating merchant',
        error: e,
        stackTrace: st,
        context: {
          'merchantId': merchantId,
          'userId': userId,
          'code': e.code,
        },
      );

      // Check for specific Firebase errors
      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, Merchant>(
          UnableToCreateMerchantFailure(
            message: 'Unable to create merchant / Impossible de créer le profil commerçant',
          ),
        );
      }

      return Left<MerchantFailure, Merchant>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error creating merchant',
        error: e,
        stackTrace: st,
        context: {
          'merchantId': merchantId,
          'userId': userId,
        },
      );
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Unable to create merchant / Impossible de créer le profil commerçant',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Merchant?>> getMerchantByOwnerUid(String ownerUid) async {
    if (ownerUid.isEmpty) {
      return const Right<MerchantFailure, Merchant?>(null);
    }

    try {
      // FIX HIGH 3: Add timeout for query operations
      final querySnapshot = await _firestore
          .collection('merchants')
          .where('owner_uid', isEqualTo: ownerUid)
          .limit(1)
          .get()
          .timeout(
            FirestoreTimeouts.queryOperation,
            onTimeout: () {
              throw TimeoutException(
                'Get merchant by owner UID timed out',
                FirestoreTimeouts.queryOperation,
              );
            },
          );

      if (querySnapshot.docs.isEmpty) {
        return const Right<MerchantFailure, Merchant?>(null);
      }

      final doc = querySnapshot.docs.first;
      final merchant = MerchantDto.fromFirestore(doc).toDomain();
      LoggerService.logInfo(
        'Merchant retrieved by owner UID',
        context: {'ownerUid': ownerUid, 'merchantId': merchant.id},
      );
      return Right<MerchantFailure, Merchant?>(merchant);
    } catch (e, st) {
      LoggerService.logError(
        'Error getting merchant by owner UID',
        error: e,
        stackTrace: st,
        context: {'ownerUid': ownerUid},
      );
      return Left<MerchantFailure, Merchant?>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Merchant?>> getMerchantById(String merchantId) async {
    if (merchantId.isEmpty) {
      return const Right<MerchantFailure, Merchant?>(null);
    }

    try {
      // FIX HIGH 3: Add timeout for get operations
      final doc = await _firestore
          .collection('merchants')
          .doc(merchantId)
          .get()
          .timeout(
            FirestoreTimeouts.getOperation,
            onTimeout: () {
              throw TimeoutException(
                'Get merchant by ID timed out',
                FirestoreTimeouts.getOperation,
              );
            },
          );

      if (!doc.exists) {
        LoggerService.logInfo(
          'Merchant not found by ID',
          context: {'merchantId': merchantId},
        );
        return const Right<MerchantFailure, Merchant?>(null);
      }

      final merchant = MerchantDto.fromFirestore(doc).toDomain();
      LoggerService.logInfo(
        'Merchant retrieved by ID',
        context: {'merchantId': merchantId, 'merchantName': merchant.name},
      );
      return Right<MerchantFailure, Merchant?>(merchant);
    } on TimeoutException catch (e, st) {
      // FIX HIGH 3: Handle timeout errors
      LoggerService.logError(
        'Timeout getting merchant by ID',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left<MerchantFailure, Merchant?>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error getting merchant by ID',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId, 'code': e.code},
      );

      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, Merchant?>(
          UnableToCreateMerchantFailure(
            message: 'Unable to access merchant / Impossible d\'accéder au commerce',
          ),
        );
      }

      return Left<MerchantFailure, Merchant?>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error getting merchant by ID',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left<MerchantFailure, Merchant?>(
        MerchantUnexpectedFailure(
          message: 'Unable to get merchant / Impossible de récupérer le commerce',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Merchant>>> getMerchants({String? city}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('merchants')
          .where('status', isEqualTo: 'active');

      // Add city filter if provided
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      // FIX HIGH 7: Add limit to prevent loading too many merchants at once
      // This improves performance and prevents memory issues with large datasets
      // For full pagination, we would need to modify the repository interface
      // For now, limit to 100 merchants (reasonable for initial load)
      query = query.limit(100);

      // FIX HIGH 3: Add timeout for query operations
      final querySnapshot = await query.get().timeout(
        FirestoreTimeouts.queryOperation,
        onTimeout: () {
          throw TimeoutException(
            'Get merchants query timed out',
            FirestoreTimeouts.queryOperation,
          );
        },
      );

      if (querySnapshot.docs.isEmpty) {
        LoggerService.logInfo(
          'No merchants found',
          context: {'city': city ?? 'all'},
        );
        return const Right<MerchantFailure, List<Merchant>>([]);
      }

      final merchants = querySnapshot.docs
          .map((doc) => MerchantDto.fromFirestore(doc).toDomain())
          .toList();

      LoggerService.logInfo(
        'Merchants retrieved',
        context: {
          'count': merchants.length,
          'city': city ?? 'all',
        },
      );
      return Right<MerchantFailure, List<Merchant>>(merchants);
    } on TimeoutException catch (e, st) {
      // FIX HIGH 3: Handle timeout errors
      LoggerService.logError(
        'Timeout getting merchants',
        error: e,
        stackTrace: st,
        context: {'city': city ?? 'all'},
      );
      return Left<MerchantFailure, List<Merchant>>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error getting merchants',
        error: e,
        stackTrace: st,
        context: {'city': city ?? 'all', 'code': e.code},
      );

      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, List<Merchant>>(
          UnableToCreateMerchantFailure(
            message: 'Unable to access merchants / Impossible d\'accéder aux commerces',
          ),
        );
      }

      return Left<MerchantFailure, List<Merchant>>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error getting merchants',
        error: e,
        stackTrace: st,
        context: {'city': city ?? 'all'},
      );
      return Left<MerchantFailure, List<Merchant>>(
        MerchantUnexpectedFailure(
          message: 'Unable to get merchants / Impossible de récupérer les commerces',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> linkExistingMerchantToUser({
    required String merchantId,
    required String userId,
  }) async {
    if (merchantId.isEmpty || userId.isEmpty) {
      return const Left<MerchantFailure, Unit>(
        MerchantUnexpectedFailure(
          message: 'Merchant ID and User ID are required',
        ),
      );
    }

    try {
      // Verify merchant exists
      final merchantDoc = await _firestore
          .collection('merchants')
          .doc(merchantId)
          .get();

      if (!merchantDoc.exists) {
        LoggerService.logError(
          'Merchant not found for linking',
          context: {'merchantId': merchantId, 'userId': userId},
        );
        return const Left<MerchantFailure, Unit>(
          MerchantUnexpectedFailure(
            message: 'Merchant not found / Le commerce n\'existe pas',
          ),
        );
      }

      // Verify merchant owner matches
      final merchantData = merchantDoc.data();
      final ownerUid = merchantData?['owner_uid'] as String?;
      if (ownerUid != userId) {
        LoggerService.logError(
          'Merchant owner mismatch',
          context: {
            'merchantId': merchantId,
            'userId': userId,
            'merchantOwnerUid': ownerUid,
          },
        );
        return const Left<MerchantFailure, Unit>(
          MerchantUnexpectedFailure(
            message: 'Merchant owner mismatch / Le propriétaire du commerce ne correspond pas',
          ),
        );
      }

      // Use batch write to ensure atomicity
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);
      
      batch.update(userRef, {
        'merchant_id': merchantId,
        'onboarding.merchant': true,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      LoggerService.logInfo(
        'Existing merchant linked to user successfully',
        context: {'merchantId': merchantId, 'userId': userId},
      );

      return const Right<MerchantFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error linking merchant to user',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId, 'userId': userId, 'code': e.code},
      );

      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, Unit>(
          UnableToCreateMerchantFailure(
            message: 'Unable to link merchant / Impossible de lier le commerce',
          ),
        );
      }

      return Left<MerchantFailure, Unit>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error linking merchant to user',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId, 'userId': userId},
      );
      return Left<MerchantFailure, Unit>(
        MerchantUnexpectedFailure(
          message: 'Unable to link merchant / Impossible de lier le commerce',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}

