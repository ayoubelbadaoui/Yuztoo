import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/failure.dart';
import '../../../core/domain/core/result.dart';
import '../domain/entities/notification_template.dart';
import '../domain/repositories/notification_template_repository.dart';

class FirestoreNotificationTemplateRepository
    implements NotificationTemplateRepository {
  FirestoreNotificationTemplateRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _coll(String merchantId) =>
      _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('notification_templates');

  @override
  Stream<List<NotificationTemplate>> watchAll(String merchantId) {
    if (merchantId.isEmpty) {
      return Stream<List<NotificationTemplate>>.value(const []);
    }
    return _coll(merchantId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _fromDoc(d.id, d.data()))
            .where((t) => t != null)
            .cast<NotificationTemplate>()
            .toList());
  }

  @override
  Future<Result<String>> create({
    required String merchantId,
    required NotificationTemplate template,
  }) async {
    if (merchantId.isEmpty) {
      return const Left<AppFailure, String>(
          UnexpectedFailure(message: 'merchantId required'));
    }
    final cleaned = _validate(template);
    if (cleaned.isLeft) {
      return Left<AppFailure, String>(cleaned.leftOrNull!);
    }
    try {
      final ref = await _coll(merchantId).add({
        'name': cleaned.rightOrNull!.name,
        'text': cleaned.rightOrNull!.text,
        'audience': cleaned.rightOrNull!.audience,
        'segments': cleaned.rightOrNull!.segments,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return Right<AppFailure, String>(ref.id);
    } catch (e) {
      return Left<AppFailure, String>(UnexpectedFailure(
          message: 'Impossible de créer le template', cause: e));
    }
  }

  @override
  Future<Result<Unit>> update({
    required String merchantId,
    required NotificationTemplate template,
  }) async {
    if (merchantId.isEmpty || template.id.isEmpty) {
      return const Left<AppFailure, Unit>(
          UnexpectedFailure(message: 'merchantId & template id required'));
    }
    final cleaned = _validate(template);
    if (cleaned.isLeft) {
      return Left<AppFailure, Unit>(cleaned.leftOrNull!);
    }
    try {
      await _coll(merchantId).doc(template.id).update({
        'name': cleaned.rightOrNull!.name,
        'text': cleaned.rightOrNull!.text,
        'audience': cleaned.rightOrNull!.audience,
        'segments': cleaned.rightOrNull!.segments,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return const Right<AppFailure, Unit>(unit);
    } catch (e) {
      return Left<AppFailure, Unit>(UnexpectedFailure(
          message: 'Impossible de mettre à jour le template', cause: e));
    }
  }

  @override
  Future<Result<Unit>> delete({
    required String merchantId,
    required String templateId,
  }) async {
    if (merchantId.isEmpty || templateId.isEmpty) {
      return const Left<AppFailure, Unit>(
          UnexpectedFailure(message: 'merchantId & template id required'));
    }
    try {
      await _coll(merchantId).doc(templateId).delete();
      return const Right<AppFailure, Unit>(unit);
    } catch (e) {
      return Left<AppFailure, Unit>(
          UnexpectedFailure(message: 'Impossible de supprimer', cause: e));
    }
  }

  // Single source of truth for the bounds enforced both client-side AND
  // by the firestore.rules schema gate. Names ≤80 chars (picker tile
  // would truncate beyond that anyway), bodies ≤500 chars (matches the
  // notification body limit on the wire).
  static const int _maxNameLen = 80;
  static const int _maxTextLen = 500;
  static const _validAudiences = {'Tous mes clients', 'Certains clients'};

  Result<NotificationTemplate> _validate(NotificationTemplate t) {
    final name = t.name.trim();
    final text = t.text.trim();
    if (name.isEmpty) {
      return const Left<AppFailure, NotificationTemplate>(
          UnexpectedFailure(message: 'Donnez un nom au template'));
    }
    if (name.length > _maxNameLen) {
      return const Left<AppFailure, NotificationTemplate>(
          UnexpectedFailure(
              message: 'Nom trop long (max $_maxNameLen caractères)'));
    }
    if (text.isEmpty) {
      return const Left<AppFailure, NotificationTemplate>(
          UnexpectedFailure(message: 'Le message ne peut pas être vide'));
    }
    if (text.length > _maxTextLen) {
      return const Left<AppFailure, NotificationTemplate>(
          UnexpectedFailure(
              message: 'Message trop long (max $_maxTextLen caractères)'));
    }
    if (!_validAudiences.contains(t.audience)) {
      return const Left<AppFailure, NotificationTemplate>(
          UnexpectedFailure(message: 'Audience invalide'));
    }
    return Right<AppFailure, NotificationTemplate>(
      t.copyWith(name: name, text: text),
    );
  }

  NotificationTemplate? _fromDoc(String id, Map<String, dynamic> data) {
    try {
      final name = (data['name'] as String?)?.trim() ?? '';
      final text = (data['text'] as String?)?.trim() ?? '';
      if (name.isEmpty || text.isEmpty) return null;
      final audience =
          (data['audience'] as String?) ?? 'Tous mes clients';
      final rawSegments = data['segments'];
      final segments = rawSegments is List
          ? rawSegments.whereType<String>().toList()
          : <String>[];
      return NotificationTemplate(
        id: id,
        name: name,
        text: text,
        audience: audience,
        segments: segments,
        createdAt: _ts(data['created_at']),
        updatedAt: _ts(data['updated_at']),
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
