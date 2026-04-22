import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../storage/domain/repositories/storage_repository.dart';
import '../domain/entities/promotion.dart';
import '../domain/promotion_failure.dart';
import '../domain/repositories/promotion_repository.dart';
import 'dto/promotion_dto.dart';

/// Firestore implementation: merchants/{merchantId}/promotions/{promoId}
class FirestorePromotionRepository implements PromotionRepository {
  FirestorePromotionRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  })  : _firestore = firestore,
        _storage = storageRepository;

  final FirebaseFirestore _firestore;
  final StorageRepository _storage;

  CollectionReference<Map<String, dynamic>> _promotionsRef(String merchantId) =>
      _firestore.collection('merchants').doc(merchantId).collection('promotions');

  @override
  Future<Result<Promotion>> create({
    required String merchantId,
    required Promotion promotion,
    String? imageFilePath,
  }) async {
    if (merchantId.isEmpty) {
      return const Left(
        PromotionUnexpectedFailure(message: 'Merchant ID is required'),
      );
    }
    try {
      final ref = _promotionsRef(merchantId).doc();
      final id = ref.id;

      String? imageUrl;
      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        final file = File(imageFilePath);
        if (file.existsSync()) {
          final storagePath = 'merchants/$merchantId/promotions/$id.jpg';
          final uploadResult = await _storage.uploadImage(
            filePath: imageFilePath,
            storagePath: storagePath,
          );
          uploadResult.fold(
            (_) {},
            (url) => imageUrl = url,
          );
        }
      }

      final promo = promotion.copyWith(
        id: id,
        merchantId: merchantId,
        imageUrl: imageUrl,
      );
      final dto = PromotionDto(
        id: id,
        merchantId: merchantId,
        title: promo.title,
        subtitle: promo.subtitle,
        dateFrom: promo.dateFrom,
        dateTo: promo.dateTo,
        clientType: promo.selectedClientType.value,
        isOnline: promo.isOnline,
        imageUrl: promo.imageUrl,
      );
      await ref.set(dto.toFirestore());

      LoggerService.logInfo(
        'Promotion created',
        context: {'merchantId': merchantId, 'promotionId': id},
      );
      return Right(promo);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error creating promotion',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left(
        PromotionNetworkFailure(cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error creating promotion',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left(
        PromotionUnexpectedFailure(cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<List<Promotion>>> listByMerchantId(String merchantId) async {
    if (merchantId.isEmpty) {
      return const Right([]);
    }
    try {
      final snapshot = await _promotionsRef(merchantId)
          .orderBy('date_from', descending: true)
          .get();

      final list = snapshot.docs
          .map((d) => PromotionDto.fromFirestore(d, merchantId).toDomain())
          .toList();

      LoggerService.logInfo(
        'Promotions listed',
        context: {'merchantId': merchantId, 'count': list.length},
      );
      return Right(list);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error listing promotions',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left(
        PromotionNetworkFailure(cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error listing promotions',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left(
        PromotionUnexpectedFailure(cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<Promotion>> update(
    Promotion promotion, {
    String? imageFilePath,
  }) async {
    if (promotion.merchantId.isEmpty || promotion.id.isEmpty) {
      return const Left(
        PromotionUnexpectedFailure(message: 'Merchant ID and Promotion ID required'),
      );
    }
    try {
      // Upload new image if provided.
      String? imageUrl = promotion.imageUrl;
      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        final file = File(imageFilePath);
        if (file.existsSync()) {
          final storagePath =
              'merchants/${promotion.merchantId}/promotions/${promotion.id}.jpg';
          final uploadResult = await _storage.uploadImage(
            filePath: imageFilePath,
            storagePath: storagePath,
          );
          uploadResult.fold(
            (f) {
              LoggerService.logError(
                'Image upload failed during promo update',
                error: f,
              );
            },
            (url) => imageUrl = url,
          );
        }
      }

      final updated = promotion.copyWith(imageUrl: imageUrl);
      final ref = _promotionsRef(updated.merchantId).doc(updated.id);
      final dto = PromotionDto(
        id: updated.id,
        merchantId: updated.merchantId,
        title: updated.title,
        subtitle: updated.subtitle,
        dateFrom: updated.dateFrom,
        dateTo: updated.dateTo,
        clientType: updated.selectedClientType.value,
        isOnline: updated.isOnline,
        imageUrl: updated.imageUrl,
      );
      await ref.update(dto.toFirestore());

      LoggerService.logInfo(
        'Promotion updated',
        context: {'merchantId': updated.merchantId, 'promotionId': updated.id},
      );
      return Right(updated);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error updating promotion',
        error: e,
        stackTrace: st,
      );
      return Left(PromotionNetworkFailure(cause: e, stackTrace: st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error updating promotion',
        error: e,
        stackTrace: st,
      );
      return Left(PromotionUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<Unit>> delete({
    required String merchantId,
    required String promotionId,
  }) async {
    if (merchantId.isEmpty || promotionId.isEmpty) {
      return const Left(
        PromotionUnexpectedFailure(message: 'Merchant ID and Promotion ID required'),
      );
    }
    try {
      await _promotionsRef(merchantId).doc(promotionId).delete();
      LoggerService.logInfo(
        'Promotion deleted',
        context: {'merchantId': merchantId, 'promotionId': promotionId},
      );
      return const Right(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error deleting promotion',
        error: e,
        stackTrace: st,
      );
      return Left(
        PromotionNetworkFailure(cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error deleting promotion',
        error: e,
        stackTrace: st,
      );
      return Left(
        PromotionUnexpectedFailure(cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<void> recordViews({
    required String merchantId,
    required List<String> promotionIds,
  }) async {
    if (merchantId.isEmpty || promotionIds.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final id in promotionIds) {
        batch.set(
          _promotionsRef(merchantId).doc(id),
          {'view_count': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (e) {
      // View tracking is best-effort — never crash the app for this
      LoggerService.logError('recordPromoViews', error: e);
    }
  }
}
