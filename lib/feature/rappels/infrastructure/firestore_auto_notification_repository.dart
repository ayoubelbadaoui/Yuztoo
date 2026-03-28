import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../domain/entities/active_notification.dart';
import '../domain/rappels_failure.dart';
import '../domain/repositories/auto_notification_repository.dart';
import 'dto/auto_notification_dto.dart';

/// Firestore: merchants/{merchantId}/auto_notifications/{id}
class FirestoreAutoNotificationRepository implements AutoNotificationRepository {
  FirestoreAutoNotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ref(String merchantId) =>
      _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('auto_notifications');

  @override
  Future<Result<ActiveNotification>> create({
    required String merchantId,
    required ActiveNotification notification,
  }) async {
    if (merchantId.isEmpty) {
      return Left(
        RappelsUnexpectedFailure(message: 'Merchant ID is required'),
      );
    }
    try {
      final col = _ref(merchantId);
      final docRef = col.doc();
      final id = docRef.id;

      final dto = AutoNotificationDto(
        id: id,
        merchantId: merchantId,
        text: notification.text,
        trigger: notification.trigger,
        audience: notification.audience,
        isEnabled: notification.isEnabled,
        createdAt: DateTime.now(),
      );
      await docRef.set(dto.toFirestore());

      final created = notification.copyWith(
        id: id,
        merchantId: merchantId,
        createdAt: dto.createdAt,
      );
      LoggerService.logInfo(
        'Auto-notification created',
        context: {'merchantId': merchantId, 'notificationId': id},
      );
      return Right(created);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error creating auto-notification',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left(RappelsNetworkFailure(cause: e, stackTrace: st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error creating auto-notification',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left(RappelsUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<List<ActiveNotification>>> listByMerchantId(
    String merchantId,
  ) async {
    if (merchantId.isEmpty) {
      return Right(<ActiveNotification>[]);
    }
    try {
      final snapshot = await _ref(merchantId)
          .orderBy('created_at', descending: true)
          .get();

      final list = snapshot.docs
          .map((d) => AutoNotificationDto.fromFirestore(d, merchantId).toDomain())
          .toList();

      LoggerService.logInfo(
        'Auto-notifications listed',
        context: {'merchantId': merchantId, 'count': list.length},
      );
      return Right(list);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error listing auto-notifications',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left(RappelsNetworkFailure(cause: e, stackTrace: st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error listing auto-notifications',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left(RappelsUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<ActiveNotification>> update(
    ActiveNotification notification,
  ) async {
    if (notification.merchantId.isEmpty || notification.id.isEmpty) {
      return Left(
        RappelsUnexpectedFailure(
          message: 'Merchant ID and Notification ID required',
        ),
      );
    }
    try {
      final ref = _ref(notification.merchantId).doc(notification.id);
      final dto = AutoNotificationDto(
        id: notification.id,
        merchantId: notification.merchantId,
        text: notification.text,
        trigger: notification.trigger,
        audience: notification.audience,
        isEnabled: notification.isEnabled,
        createdAt: notification.createdAt,
      );
      await ref.update(dto.toFirestore());

      LoggerService.logInfo(
        'Auto-notification updated',
        context: {
          'merchantId': notification.merchantId,
          'notificationId': notification.id,
        },
      );
      return Right(notification);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error updating auto-notification',
        error: e,
        stackTrace: st,
      );
      return Left(RappelsNetworkFailure(cause: e, stackTrace: st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error updating auto-notification',
        error: e,
        stackTrace: st,
      );
      return Left(RappelsUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<Unit>> delete({
    required String merchantId,
    required String notificationId,
  }) async {
    if (merchantId.isEmpty || notificationId.isEmpty) {
      return Left(
        RappelsUnexpectedFailure(
          message: 'Merchant ID and Notification ID required',
        ),
      );
    }
    try {
      await _ref(merchantId).doc(notificationId).delete();
      LoggerService.logInfo(
        'Auto-notification deleted',
        context: {'merchantId': merchantId, 'notificationId': notificationId},
      );
      return Right(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error deleting auto-notification',
        error: e,
        stackTrace: st,
      );
      return Left(RappelsNetworkFailure(cause: e, stackTrace: st));
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error deleting auto-notification',
        error: e,
        stackTrace: st,
      );
      return Left(RappelsUnexpectedFailure(cause: e, stackTrace: st));
    }
  }
}
