import 'package:equatable/equatable.dart';

import 'client_merchant_loyalty_progress.dart';

/// Client avec au moins un passage en attente de validation marchand.
class LoyaltyPendingClientRow extends Equatable {
  const LoyaltyPendingClientRow({
    required this.clientUid,
    required this.progress,
  });

  final String clientUid;
  final ClientMerchantLoyaltyProgress progress;

  @override
  List<Object?> get props => <Object?>[clientUid, progress];
}
