import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../domain/entities/client_notification.dart';
import '../domain/failures/client_notification_failure.dart';
import '../domain/repositories/client_notification_repository.dart';
import 'dto/client_notification_dto.dart';

/// Firestore implementation: `users/{clientId}/notifications/{notificationId}`.
class FirestoreClientNotificationRepository
    implements ClientNotificationRepository {
  FirestoreClientNotificationRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notificationsRef(
          String clientId) =>
      _firestore
          .collection('users')
          .doc(clientId)
          .collection('notifications');

  @override
  Stream<List<ClientNotification>> watchForClient(String clientId) {
    if (clientId.isEmpty) return const Stream.empty();
    return _notificationsRef(clientId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ClientNotificationDto.fromFirestore(d, clientId)
                  .toDomain())
              .toList(),
        );
  }

  @override
  Future<Result<ClientNotification>> create(
      ClientNotification notification) async {
    if (notification.clientId.isEmpty) {
      return const Left(ClientNotificationUnexpectedFailure(
          message: 'Identifiant client requis pour créer une notification.'));
    }
    try {
      final ref = _notificationsRef(notification.clientId).doc();
      final dto = ClientNotificationDto(
        id: ref.id,
        clientId: notification.clientId,
        merchantId: notification.merchantId,
        merchantName: notification.merchantName,
        type: ClientNotificationDto.typeToString(notification.type),
        title: notification.title,
        body: notification.body,
        isRead: false,
        createdAt: DateTime.now(),
        promotionId: notification.promotionId,
      );
      await ref.set(dto.toFirestore());

      LoggerService.logInfo(
        'Client notification created',
        context: {
          'clientId': notification.clientId,
          'notificationId': ref.id,
          'type': dto.type,
        },
      );
      return Right(dto.toDomain());
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error creating notification',
          error: e, stackTrace: st);
      return Left(
          ClientNotificationNetworkFailure(cause: e, stackTrace: st));
    } catch (e, st) {
      LoggerService.logError('Unexpected error creating notification',
          error: e, stackTrace: st);
      return Left(
          ClientNotificationUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<Unit>> markAsRead(
      String clientId, String notificationId) async {
    if (clientId.isEmpty || notificationId.isEmpty) {
      return const Right(unit);
    }
    try {
      await _notificationsRef(clientId)
          .doc(notificationId)
          .update({'is_read': true});
      return const Right(unit);
    } on FirebaseException catch (e, st) {
      return Left(
          ClientNotificationNetworkFailure(cause: e, stackTrace: st));
    } catch (e, st) {
      return Left(
          ClientNotificationUnexpectedFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<Unit>> markAllAsRead(String clientId) async {
    if (clientId.isEmpty) return const Right(unit);
    try {
      final snap = await _notificationsRef(clientId)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();

      LoggerService.logInfo(
        'All notifications marked as read',
        context: {'clientId': clientId, 'count': snap.docs.length},
      );
      return const Right(unit);
    } on FirebaseException catch (e, st) {
      return Left(
          ClientNotificationNetworkFailure(cause: e, stackTrace: st));
    } catch (e, st) {
      return Left(
          ClientNotificationUnexpectedFailure(cause: e, stackTrace: st));
    }
  }
}
