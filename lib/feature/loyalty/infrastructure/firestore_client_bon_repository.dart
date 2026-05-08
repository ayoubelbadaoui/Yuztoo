import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/client_bon.dart';
import '../domain/repositories/client_bon_repository.dart';

class FirestoreClientBonRepository implements ClientBonRepository {
  FirestoreClientBonRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ClientBon>> watchAll(String clientId) {
    if (clientId.isEmpty) return Stream<List<ClientBon>>.value(const []);
    return _firestore
        .collection('users')
        .doc(clientId)
        .collection('loyalty_bons')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _fromDoc(d.id, d.data()))
            .where((b) => b != null)
            .cast<ClientBon>()
            .toList());
  }

  // Defensive parser — a missing field on a corrupt doc must not crash
  // the whole stream (would blank out "Mes avantages" for the user).
  // Returns null on a doc we can't make sense of; the caller filters.
  ClientBon? _fromDoc(String id, Map<String, dynamic> data) {
    try {
      final merchantId = (data['merchant_id'] as String?)?.trim() ?? '';
      if (merchantId.isEmpty) return null;
      final rawKind = (data['kind'] as String?) ?? '';
      final kind = switch (rawKind) {
        'welcome' => ClientBonKind.welcome,
        'milestone' => ClientBonKind.milestone,
        _ => null,
      };
      if (kind == null) return null;
      final description = (data['description'] as String?) ?? '';
      final issuedAt = _ts(data['issued_at']) ?? DateTime.now();
      return ClientBon(
        id: id,
        merchantId: merchantId,
        kind: kind,
        description: description,
        issuedAt: issuedAt,
        validUntilAt: _ts(data['valid_until_at']),
        redeemedAt: _ts(data['redeemed_at']),
        notifiedExpiringAt: _ts(data['notified_expiring_at']),
        notifiedExpiredAt: _ts(data['notified_expired_at']),
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
