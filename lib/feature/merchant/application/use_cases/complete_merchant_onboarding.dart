import '../../domain/entities/merchant.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../../../core/domain/core/result.dart';

/// Use case for completing merchant onboarding.
/// 
/// This use case:
/// - Creates merchant entity
/// - Links `users/{uid}.merchant_id` to the created merchant (completion signal)
/// - Both operations are atomic (handled by repository batch write)
class CompleteMerchantOnboarding {
  const CompleteMerchantOnboarding(this.merchantRepository);

  final MerchantRepository merchantRepository;

  Future<Result<Merchant>> call({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String city,
    String? address,
    List<String>? categories,
    String? description,
    String? websiteUrl,
    Map<String, dynamic>? hours,
    String? logoUrl,
    String? bannerUrl,
    String? merchantType,
    String? categoryId,
    String? subcategoryTitle,
  }) async {
    // Defensive: only persist the values the schema knows about. The
    // wizard picker is binary so this is a backstop; anything else
    // falls back to the entity default ('b2c').
    final cleanType =
        (merchantType == 'b2b' || merchantType == 'b2c') ? merchantType : null;
    // Create merchant entity
    // MVP: merchantId == user.uid (repository will use userId if id is empty)
    final merchant = Merchant(
      id: userId, // MVP: Use userId as merchantId (one merchant per user)
      ownerUid: userId,
      name: name,
      email: email,
      phone: phone,
      city: city,
      address: address,
      categories: categories,
      description: description,
      websiteUrl: websiteUrl,
      hours: hours,
      displayName: name,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      merchantType: cleanType ?? 'b2c',
      categoryId: categoryId,
      subcategoryTitle: subcategoryTitle,
      // Visible in Découvrir / listMerchants (query expects discoverable merchants).
      status: 'active',
    );

    // Create merchant and link to user (atomic batch write).
    return await merchantRepository.createMerchantAndLinkUser(
      merchant: merchant,
      userId: userId,
    );
  }
}

