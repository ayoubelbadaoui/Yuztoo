import 'package:equatable/equatable.dart';

/// How loyalty progress is counted across the stores of an enseigne.
enum LoyaltyMode {
  /// Each store keeps its own stamps / rewards (default).
  perStore,

  /// Stamps earned in any store count toward the same reward.
  shared;

  static LoyaltyMode fromFirestore(String? raw) =>
      raw == 'shared' ? LoyaltyMode.shared : LoyaltyMode.perStore;

  String get firestoreValue => switch (this) {
        LoyaltyMode.perStore => 'per_store',
        LoyaltyMode.shared => 'shared',
      };
}

/// An enseigne: one brand running several points de vente (stores).
///
/// Each store stays a regular merchant document linked through
/// `merchants/{id}.organization_id`.
class Organization extends Equatable {
  const Organization({
    required this.id,
    required this.name,
    required this.ownerUid,
    this.loyaltyMode = LoyaltyMode.perStore,
    this.logoUrl,
    this.description,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerUid;
  final LoyaltyMode loyaltyMode;
  final String? logoUrl;
  final String? description;
  final DateTime? createdAt;

  Organization copyWith({
    String? name,
    LoyaltyMode? loyaltyMode,
    String? logoUrl,
    String? description,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      ownerUid: ownerUid,
      loyaltyMode: loyaltyMode ?? this.loyaltyMode,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, ownerUid, loyaltyMode, logoUrl, description, createdAt];
}
