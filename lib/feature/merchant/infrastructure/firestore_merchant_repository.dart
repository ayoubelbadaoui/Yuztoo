import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/merchant.dart';
import '../domain/merchant_failure.dart';
import '../domain/repositories/merchant_repository.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import 'dto/merchant_dto.dart';

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

    // MVP: Use userId as merchantId (one merchant per user)
    // This ensures merchantId == user.uid for MVP
    final merchantId = merchant.id.isEmpty
        ? userId  // Use userId as merchantId (MVP requirement)
        : merchant.id;

    try {
      // Create batch write for atomic operation
      final batch = _firestore.batch();

      // Create merchant document
      final merchantRef = _firestore.collection('merchants').doc(merchantId);
      final merchantDto = MerchantDto.fromDomain(
        merchant.copyWith(id: merchantId),
      );
      batch.set(merchantRef, merchantDto.toFirestore(), SetOptions(merge: false));

      // Update user document with merchant_id, mark onboarding as complete, and set merchant role
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(userRef, {
        'merchant_id': merchantId,
        'onboarding.merchant': true, // Use dot notation for nested field
        'roles.merchant': true, // Ensure merchant role is set
        'roles.client': false, // Unset client role
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Commit batch write atomically
      await batch.commit();

      // Fetch the created merchant to return with server timestamps
      final createdDoc = await merchantRef.get();
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
            message:
                'Permission denied (Firestore rules) / Permission refusée (règles Firestore). Impossible de créer le profil commerçant.',
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
      // MVP: merchantId == ownerUid, so we can do a direct document read
      // This is more efficient than a query
      final doc = await _firestore.collection('merchants').doc(ownerUid).get();

      if (!doc.exists) {
        return const Right<MerchantFailure, Merchant?>(null);
      }

      final merchant = MerchantDto.fromFirestore(doc).toDomain();
      LoggerService.logInfo(
        'Merchant retrieved by owner UID (direct read)',
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

  @override
  Future<Result<Merchant>> updateMerchant({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoUrl,
    String? phone,
    String? address,
    String? websiteUrl,
    String? bannerUrl,
    Map<String, dynamic>? hours,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
  }) async {
    if (merchantId.isEmpty) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Merchant ID is required',
        ),
      );
    }

    try {
      final merchantRef = _firestore.collection('merchants').doc(merchantId);
      
      // Build update map with only provided fields
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) {
        updateData['display_name'] = displayName;
      }
      if (description != null) {
        updateData['description'] = description;
      }
      if (categories != null) {
        updateData['categories'] = categories;
      }
      if (logoUrl != null) {
        updateData['logo_url'] = logoUrl;
      }
      if (phone != null) {
        updateData['phone'] = phone;
      }
      if (address != null) {
        updateData['address'] = address;
      }
      if (websiteUrl != null) {
        updateData['website_url'] = websiteUrl;
      }
      if (bannerUrl != null) {
        updateData['banner_url'] = bannerUrl;
      }
      if (hours != null) {
        updateData['hours'] = hours;
      }
      if (rappelsAutoClientValidation != null) {
        updateData['rappels_auto_client_validation'] = rappelsAutoClientValidation;
      }
      if (rappelsAutoPassageValidation != null) {
        updateData['rappels_auto_passage_validation'] = rappelsAutoPassageValidation;
      }

      // Update merchant document
      await merchantRef.update(updateData);

      // Fetch updated merchant to return
      final updatedDoc = await merchantRef.get();
      if (!updatedDoc.exists) {
        LoggerService.logError(
          'Merchant document not found after update',
          context: {'merchantId': merchantId},
        );
        return const Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(
            message: 'Could not save storefront / Impossible d\'enregistrer la vitrine',
          ),
        );
      }

      final updatedMerchant = MerchantDto.fromFirestore(updatedDoc).toDomain();
      LoggerService.logInfo(
        'Merchant storefront updated successfully',
        context: {
          'merchantId': merchantId,
          'displayName': displayName,
          'hasLogoUrl': logoUrl != null,
        },
      );

      return Right<MerchantFailure, Merchant>(updatedMerchant);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error updating merchant storefront',
        error: e,
        stackTrace: st,
        context: {
          'merchantId': merchantId,
          'code': e.code,
        },
      );

      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(
            message: 'Permission denied (Firestore rules) / Permission refusée (règles Firestore). Could not save storefront / Impossible d\'enregistrer la vitrine.',
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
        'Unexpected error updating merchant storefront',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Could not save storefront / Impossible d\'enregistrer la vitrine',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}

