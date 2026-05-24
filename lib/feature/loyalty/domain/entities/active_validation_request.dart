import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/infrastructure/loyalty_program_firestore_mapper.dart';

enum ActiveValidationStatus { awaiting, completed, cancelled }

/// How the validation session was opened.
enum ActiveValidationSource { vitrine, ble }

ActiveValidationSource _sourceFromString(String? raw) {
  switch (raw) {
    case 'ble':
      return ActiveValidationSource.ble;
    default:
      return ActiveValidationSource.vitrine;
  }
}

String _sourceToString(ActiveValidationSource s) {
  switch (s) {
    case ActiveValidationSource.ble:
      return 'ble';
    case ActiveValidationSource.vitrine:
      return 'vitrine';
  }
}

ActiveValidationStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'completed':
      return ActiveValidationStatus.completed;
    case 'cancelled':
      return ActiveValidationStatus.cancelled;
    default:
      return ActiveValidationStatus.awaiting;
  }
}

String _statusToString(ActiveValidationStatus s) {
  switch (s) {
    case ActiveValidationStatus.awaiting:
      return 'awaiting';
    case ActiveValidationStatus.completed:
      return 'completed';
    case ActiveValidationStatus.cancelled:
      return 'cancelled';
  }
}

/// Synchronous merchant-validates-client session. Lives at
/// `merchants/{merchantId}/active_validations/{clientUid}` — one doc per pair,
/// recycled on each new request (doc id = clientUid).
///
/// The merchant's app listens on the per-merchant collection and pops a smart
/// per-program form when a new 'awaiting' doc appears. The client's app
/// listens on its own doc to drive the live banner + celebration overlay.
class ActiveValidationRequest extends Equatable {
  const ActiveValidationRequest({
    required this.merchantId,
    required this.clientUid,
    required this.clientDisplayName,
    required this.status,
    required this.programSnapshot,
    this.clientPhotoUrl,
    this.createdAt,
    this.openedAt,
    this.cancelReason,
    this.declaredSpendEuros,
    this.resultValidatedDelta,
    this.resultSpendDelta,
    this.completedAt,
    this.source = ActiveValidationSource.vitrine,
    this.clientBleConnectedAt,
    this.merchantBleConnectedAt,
    this.merchantDisplayName,
  });

  /// Deserializes a Firestore doc snapshot. The merchantId comes from the
  /// parent collection path; clientUid is the doc id.
  factory ActiveValidationRequest.fromFirestoreMap({
    required String merchantId,
    required String clientUid,
    required Map<String, dynamic> data,
  }) {
    final snapshot = LoyaltyProgramFirestoreMapper.fromFirestoreMap(
          data['program_snapshot'],
        ) ??
        LoyaltyProgramConfig.initial();
    return ActiveValidationRequest(
      merchantId: merchantId,
      clientUid: clientUid,
      clientDisplayName: (data['client_display_name'] as String?) ?? '',
      clientPhotoUrl: data['client_photo_url'] as String?,
      status: _statusFromString(data['status'] as String?),
      programSnapshot: snapshot,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      openedAt: (data['opened_at'] as Timestamp?)?.toDate(),
      cancelReason: data['cancel_reason'] as String?,
      declaredSpendEuros:
          (data['declared_spend_euros'] as num?)?.toDouble(),
      resultValidatedDelta:
          (data['result_validated_delta'] as num?)?.toInt(),
      resultSpendDelta: (data['result_spend_delta'] as num?)?.toDouble(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      source: _sourceFromString(data['source'] as String?),
      clientBleConnectedAt:
          (data['client_ble_connected_at'] as Timestamp?)?.toDate(),
      merchantBleConnectedAt:
          (data['merchant_ble_connected_at'] as Timestamp?)?.toDate(),
      merchantDisplayName: (data['merchant_display_name'] as String?)?.trim(),
    );
  }

  /// Payload the client writes when creating the session. `created_at` is
  /// stamped server-side; `client_photo_url` is omitted when null so the rule
  /// allowlist still matches.
  static Map<String, dynamic> toFirestoreCreate({
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
  }) {
    final map = <String, dynamic>{
      'client_uid': clientUid,
      'client_display_name': clientDisplayName,
      'status': 'awaiting',
      'created_at': FieldValue.serverTimestamp(),
      'program_snapshot':
          LoyaltyProgramFirestoreMapper.toFirestoreMap(programSnapshot),
    };
    if (clientPhotoUrl != null && clientPhotoUrl.trim().isNotEmpty) {
      map['client_photo_url'] = clientPhotoUrl.trim();
    }
    return map;
  }

  /// Client BLE handshake: vitrine fields + BLE metadata.
  static Map<String, dynamic> toFirestoreBleCreate({
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
    required String merchantDisplayName,
  }) {
    final map = toFirestoreCreate(
      clientUid: clientUid,
      clientDisplayName: clientDisplayName,
      clientPhotoUrl: clientPhotoUrl,
      programSnapshot: programSnapshot,
    );
    map['source'] = 'ble';
    map['client_ble_connected_at'] = FieldValue.serverTimestamp();
    final name = merchantDisplayName.trim();
    if (name.isNotEmpty) {
      map['merchant_display_name'] = name;
    }
    return map;
  }

  final String merchantId;
  final String clientUid;
  final String clientDisplayName;
  final String? clientPhotoUrl;
  final ActiveValidationStatus status;
  final LoyaltyProgramConfig programSnapshot;
  final DateTime? createdAt;
  final DateTime? openedAt;
  final String? cancelReason;
  final double? declaredSpendEuros;
  final int? resultValidatedDelta;
  final double? resultSpendDelta;
  final DateTime? completedAt;
  final ActiveValidationSource source;
  final DateTime? clientBleConnectedAt;
  final DateTime? merchantBleConnectedAt;
  final String? merchantDisplayName;

  bool get isBle => source == ActiveValidationSource.ble;
  bool get isMerchantBleConnected => merchantBleConnectedAt != null;

  bool get isAwaiting => status == ActiveValidationStatus.awaiting;
  bool get isCompleted => status == ActiveValidationStatus.completed;
  bool get isCancelled => status == ActiveValidationStatus.cancelled;
  bool get isOpened => openedAt != null && isAwaiting;

  /// Sessions older than 15 minutes still in 'awaiting' are treated as stale.
  bool get isExpired {
    if (!isAwaiting || createdAt == null) return false;
    return DateTime.now().difference(createdAt!) > const Duration(minutes: 15);
  }

  @override
  List<Object?> get props => <Object?>[
        merchantId,
        clientUid,
        clientDisplayName,
        clientPhotoUrl,
        status,
        programSnapshot,
        createdAt,
        openedAt,
        cancelReason,
        declaredSpendEuros,
        resultValidatedDelta,
        resultSpendDelta,
        completedAt,
        source,
        clientBleConnectedAt,
        merchantBleConnectedAt,
        merchantDisplayName,
      ];

  static String statusToFirestoreString(ActiveValidationStatus s) =>
      _statusToString(s);
}
