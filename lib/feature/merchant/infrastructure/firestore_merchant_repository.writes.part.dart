part of 'firestore_merchant_repository.dart';

mixin _FirestoreMerchantRepositoryWrites on _FirestoreMerchantRepositoryBase {
  Future<Result<Unit>> linkExistingMerchantToUser({
    required String merchantId,
    required String userId,
  }) async {
    if (merchantId.isEmpty || userId.isEmpty) {
      return const Left<MerchantFailure, Unit>(
        MerchantUnexpectedFailure(
          message: 'L\'identifiant du commerce et l\'identifiant utilisateur sont requis',
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
            message: 'Le commerce est introuvable',
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
            message: 'Le propriétaire du commerce ne correspond pas',
          ),
        );
      }

      // Use batch write to ensure atomicity
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);
      
      final merchantCity =
          (merchantData?['city'] as String?)?.trim() ?? '';
      final linkUpdate = <String, dynamic>{
        'merchant_id': merchantId,
        'onboarding': {
          'merchant': 'completed',
        },
        'roles': {
          'merchant': true,
          'client': false,
          'provider': true,
        },
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (merchantCity.isNotEmpty && !CityInput.isPlaceholder(merchantCity)) {
        linkUpdate['city'] = merchantCity;
      }
      batch.update(userRef, linkUpdate);

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
            message: 'Impossible de lier le commerce à votre compte',
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
          message: 'Impossible de lier le commerce à votre compte',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Result<Merchant>> updateMerchant({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoUrl,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    String? welcomeGiftDescription,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
    LoyaltyProgramConfig? loyaltyProgram,
    bool? messagingEnabled,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabledStandalone,
    String? merchantType,
    bool clearCityField = false,
  }) async {
    if (merchantId.isEmpty) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'L\'identifiant du commerce est requis',
        ),
      );
    }

    try {
      final merchantRef = _firestore.collection('merchants').doc(merchantId);
      final merchantSnap = await merchantRef.get();
      if (!merchantSnap.exists) {
        return const Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(
            message:
                'Profil commerçant introuvable. Terminez l\'onboarding ou contactez le support.',
          ),
        );
      }

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
      if (email != null) {
        updateData['email'] = email.trim();
      }
      if (welcomeGiftDescription != null) {
        final trimmed = welcomeGiftDescription.trim();
        if (trimmed.isEmpty) {
          updateData['welcome_gift_description'] = FieldValue.delete();
        } else {
          updateData['welcome_gift_description'] = trimmed;
        }
      }
      if (address != null) {
        updateData['address'] = address;
      }
      final persistedCity = city != null ? CityInput.forFirestore(city) : null;
      final removeCity = clearCityField ||
          (city != null &&
              persistedCity == null &&
              CityInput.isPlaceholder(city));
      if (persistedCity != null) {
        updateData['city'] = persistedCity;
      } else if (removeCity) {
        updateData['city'] = FieldValue.delete();
      }
      if (websiteUrl != null) {
        updateData['website_url'] = websiteUrl;
      }
      if (bannerUrl != null) {
        updateData['banner_url'] = bannerUrl;
      }
      if (newsImageUrls != null) {
        updateData['news_image_urls'] = newsImageUrls;
      }
      if (status != null) {
        updateData['status'] = status;
      }
      if (hours != null) {
        updateData['hours'] = hours;
      }
      // Defensive: only persist values the schema knows about. Anything
      // exotic (typo, future caller) is silently dropped — better than
      // poisoning the field with a value that crashes downstream
      // segment filters.
      if (merchantType == 'b2b' || merchantType == 'b2c') {
        updateData['merchant_type'] = merchantType;
      }
      if (rappelsAutoClientValidation != null) {
        updateData['rappels_auto_client_validation'] = rappelsAutoClientValidation;
      }
      if (rappelsAutoPassageValidation != null) {
        updateData['rappels_auto_passage_validation'] = rappelsAutoPassageValidation;
      }
      if (loyaltyProgram != null) {
        updateData['loyalty_program'] =
            LoyaltyProgramFirestoreMapper.toFirestoreMap(loyaltyProgram);
        updateData['loyalty_enabled'] = loyaltyProgram.programEnabled;
      }
      if (messagingEnabled != null) {
        updateData['messaging_enabled'] = messagingEnabled;
      }
      if (notificationsAutoEnabled != null) {
        updateData['notifications_auto_enabled'] = notificationsAutoEnabled;
      }
      if (galerieEnabled != null) {
        updateData['galerie_enabled'] = galerieEnabled;
      }
      if (loyaltyEnabledStandalone != null) {
        updateData['loyalty_enabled'] = loyaltyEnabledStandalone;
        // loyalty_program.program_enabled takes priority in MerchantDto over
        // the root loyalty_enabled flag, so they must stay in sync. When the
        // wizard saves, it already updates both; when the settings toggle
        // fires (loyaltyEnabledStandalone only, no loyaltyProgram), we patch
        // the nested field using the already-fetched snapshot.
        if (loyaltyProgram == null) {
          final existingData =
              Map<String, dynamic>.from(merchantSnap.data() ?? {});
          final existingLp = existingData['loyalty_program'];
          if (existingLp is Map) {
            final updatedLp = Map<String, dynamic>.from(existingLp);
            updatedLp['program_enabled'] = loyaltyEnabledStandalone;
            updateData['loyalty_program'] = updatedLp;
          }
        }
      }

      // Merge partial fields (same as update; avoids update() on missing docs)
      await merchantRef.set(updateData, SetOptions(merge: true));

      // Fetch updated merchant to return
      final updatedDoc = await merchantRef.get();
      if (!updatedDoc.exists) {
        LoggerService.logError(
          'Merchant document not found after update',
          context: {'merchantId': merchantId},
        );
        return const Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(
            message: 'Impossible d\'enregistrer la vitrine',
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

      // Keep owner user doc city in sync so préférences + discovery stay aligned (MVP: merchantId == uid).
      if (persistedCity != null && persistedCity.isNotEmpty) {
        try {
          final userRef = _firestore.collection('users').doc(merchantId);
          final userSnap = await userRef.get();
          if (userSnap.exists && userSnap.data() != null) {
            final existing = Map<String, dynamic>.from(userSnap.data()!);
            final userPatch = <String, dynamic>{
              'city': persistedCity,
              'updated_at': FieldValue.serverTimestamp(),
            };
            mergeUserPatchForFirestoreRules(existing, userPatch);
            await userRef.set(userPatch, SetOptions(merge: true));
          }
        } catch (e, st) {
          LoggerService.logError(
            'Could not sync user city after storefront update (non-fatal)',
            error: e,
            stackTrace: st,
            context: {'merchantId': merchantId},
          );
        }
      } else if (removeCity) {
        try {
          final userRef = _firestore.collection('users').doc(merchantId);
          final userSnap = await userRef.get();
          if (userSnap.exists && userSnap.data() != null) {
            final existing = Map<String, dynamic>.from(userSnap.data()!);
            final userPatch = <String, dynamic>{
              'city': FieldValue.delete(),
              'updated_at': FieldValue.serverTimestamp(),
            };
            mergeUserPatchForFirestoreRules(existing, userPatch);
            await userRef.set(userPatch, SetOptions(merge: true));
          }
        } catch (e, st) {
          LoggerService.logError(
            'Could not clear user city after storefront update (non-fatal)',
            error: e,
            stackTrace: st,
            context: {'merchantId': merchantId},
          );
        }
      }

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
            message: 'Permission refusée (règles Firestore). Impossible d\'enregistrer la vitrine.',
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
          message: 'Impossible d\'enregistrer la vitrine',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
