import 'package:equatable/equatable.dart';

/// A new client who followed the merchant and is awaiting acknowledgement.
class PendingClientRow extends Equatable {
  const PendingClientRow({
    required this.clientUid,
    this.displayName,
    this.followedAt,
  });

  final String clientUid;
  final String? displayName;
  final DateTime? followedAt;

  String get displayLabel =>
      displayName?.isNotEmpty == true ? displayName! : '…${clientUid.substring(clientUid.length > 8 ? clientUid.length - 8 : 0)}';

  @override
  List<Object?> get props => <Object?>[clientUid, displayName, followedAt];
}
