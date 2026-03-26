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
  Future<Result<Promotion>> update(Promotion promotion) async {
    if (promotion.merchantId.isEmpty || promotion.id.isEmpty) {
      return const Left(
        PromotionUnexpectedFailure(message: 'Merchant ID and Promotion ID required'),
      );
    }
    try {
      final ref = _promotionsRef(promotion.merchantId).doc(promotion.id);
      final dto = PromotionDto(
        id: promotion.id,
        merchantId: promotion.merchantId,
        title: promotion.title,
        subtitle: promotion.subtitle,
        dateFrom: promotion.dateFrom,
        dateTo: promotion.dateTo,
        clientType: promotion.selectedClientType.value,
        isOnline: promotion.isOnline,
        imageUrl: promotion.imageUrl,
      );
      await ref.update(dto.toFirestore());

      LoggerService.logInfo(
        'Promotion updated',
        context: {'merchantId': promotion.merchantId, 'promotionId': promotion.id},
      );
      return Right(promotion);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error updating promotion',
        error: e,
        stackTrace: st,
      );
      return Left(
        PromotionNetworkFailure(cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error updating promotion',
        error: e,
        stackTrace: st,
      );
      return Left(
        PromotionUnexpectedFailure(cause: e, stackTrace: st),
      );
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
}
