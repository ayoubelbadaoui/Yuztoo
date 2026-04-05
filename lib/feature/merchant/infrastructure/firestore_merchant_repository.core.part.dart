part of 'firestore_merchant_repository.dart';

mixin _FirestoreMerchantRepositoryCore on _FirestoreMerchantRepositoryBase {
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

  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  }) async {
    // MVP: Use userId as merchantId (one merchant per user)
    // This ensures merchantId == user.uid for MVP
    final merchantId = merchant.id.isEmpty
        ? userId  // Use userId as merchantId (MVP requirement)
        : merchant.id;

    try {
      // Recover ville d'inscription from /users if onboarding sent a placeholder.
      final userSnap =
          await _firestore.collection('users').doc(userId).get();
      final signupCity =
          (userSnap.data()?['city'] as String?)?.trim() ?? '';

      var merchantToCreate = merchant.copyWith(id: merchantId);
      final resolvedCity = resolveMerchantCityForCreation(
        incomingMerchantCity: merchantToCreate.city,
        signupCityFromUserDoc: signupCity,
      );
      merchantToCreate = merchantToCreate.copyWith(city: resolvedCity);

      if (!merchantToCreate.isValid()) {
        return const Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(
            message: 'Unable to create merchant / Impossible de créer le profil commerçant',
          ),
        );
      }

      // Create batch write for atomic operation
      final batch = _firestore.batch();

      // Create merchant document
      final merchantRef = _firestore.collection('merchants').doc(merchantId);
      final merchantDto = MerchantDto.fromDomain(merchantToCreate);
      batch.set(merchantRef, merchantDto.toFirestore(), SetOptions(merge: false));

      // Update user document with merchant_id and merchant role flags
      final userRef = _firestore.collection('users').doc(userId);
      final userPayload = <String, dynamic>{
        'merchant_id': merchantId,
        'onboarding': {
          'merchant': 'completed',
        },
        // Write full roles map (no dotted keys) to avoid schema drift.
        'roles': {
          'merchant': true,
          'client': false,
          'provider': true,
        },
        'updated_at': FieldValue.serverTimestamp(),
      };
      // Keep signup city on the user doc in sync with the commerce (préférences compte).
      final trimmedCity = merchantToCreate.city.trim();
      if (trimmedCity.isNotEmpty &&
          trimmedCity.toLowerCase() != 'à compléter') {
        userPayload['city'] = trimmedCity;
      }
      batch.set(userRef, userPayload, SetOptions(merge: true));

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

  Future<Result<Merchant?>> getMerchantById(String merchantId) async {
    if (merchantId.isEmpty) {
      return const Right<MerchantFailure, Merchant?>(null);
    }
    try {
      final doc = await _firestore.collection('merchants').doc(merchantId).get();
      if (!doc.exists) {
        return const Right<MerchantFailure, Merchant?>(null);
      }
      final merchant = MerchantDto.fromFirestore(doc).toDomain();
      LoggerService.logInfo(
        'Merchant retrieved by ID',
        context: {'merchantId': merchantId},
      );
      return Right<MerchantFailure, Merchant?>(merchant);
    } catch (e, st) {
      LoggerService.logError(
        'Error getting merchant by ID',
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
    }
  }
}
