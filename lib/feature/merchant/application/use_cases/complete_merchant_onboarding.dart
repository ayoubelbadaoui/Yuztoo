import '../../domain/entities/merchant.dart';
import '../../domain/merchant_failure.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../domain/validators/merchant_validators.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

/// Use case for completing merchant onboarding.
/// 
/// This use case:
/// - Creates merchant entity
/// - Marks onboarding as complete in user document
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
    String? categoryId,
    String? subcategoryId,
    List<String>? categories,
    String? description,
    Map<String, dynamic>? hours,
  }) async {
    // Validate and trim userId
    if (userId.trim().isEmpty) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'User ID is required / L\'identifiant utilisateur est requis',
        ),
      );
    }
    final trimmedUserId = userId.trim();

    // Validate and trim name (FIX 1: Whitespace validation)
    final nameError = validateAndTrimString(
      name,
      'Merchant name',
      isRequired: true,
      maxLength: MerchantFieldLimits.maxNameLength,
    );
    if (nameError != null) {
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: nameError),
      );
    }
    final trimmedName = name.trim();

    // Validate email format (FIX 3: Email validation)
    final emailError = validateEmail(email);
    if (emailError != null) {
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: emailError),
      );
    }
    final trimmedEmail = email.trim();

    // Validate phone format (FIX 4: Phone validation)
    final phoneError = validatePhone(phone);
    if (phoneError != null) {
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: phoneError),
      );
    }
    final trimmedPhone = phone.trim();

    // Validate and trim city (FIX 1: Whitespace validation)
    final cityError = validateAndTrimString(
      city,
      'City',
      isRequired: true,
      maxLength: MerchantFieldLimits.maxCityLength,
    );
    if (cityError != null) {
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: cityError),
      );
    }
    final trimmedCity = city.trim();

    // Category is mandatory for onboarding
    final trimmedCategoryId = categoryId?.trim();
    final trimmedSubcategoryId = subcategoryId?.trim();
    
    if ((trimmedCategoryId == null || trimmedCategoryId.isEmpty) && 
        (categories == null || categories.isEmpty)) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Category is required / La catégorie est requise',
        ),
      );
    }

    // Build categories list from categoryId and subcategoryId
    // If categories list is provided, use it; otherwise build from categoryId/subcategoryId
    List<String>? finalCategories = categories;
    if (finalCategories == null && (trimmedCategoryId != null || trimmedSubcategoryId != null)) {
      finalCategories = <String>[];
      if (trimmedCategoryId != null && trimmedCategoryId.isNotEmpty) {
        finalCategories.add(trimmedCategoryId);
      }
      if (trimmedSubcategoryId != null && trimmedSubcategoryId.isNotEmpty) {
        finalCategories.add(trimmedSubcategoryId);
      }
      // If list is empty, set to null
      if (finalCategories.isEmpty) {
        finalCategories = null;
      }
    }
    
    // Validate categories list (FIX 8: Categories validation)
    final categoriesError = validateCategories(finalCategories);
    if (categoriesError != null) {
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: categoriesError),
      );
    }
    
    // Validate and trim optional fields
    String? trimmedAddress;
    if (address != null) {
      final addressError = validateAndTrimString(
        address,
        'Address',
        isRequired: false,
        maxLength: MerchantFieldLimits.maxAddressLength,
      );
      if (addressError != null) {
        return Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(message: addressError),
        );
      }
      trimmedAddress = address.trim().isEmpty ? null : address.trim();
    }
    
    String? trimmedDescription;
    if (description != null) {
      final descriptionError = validateAndTrimString(
        description,
        'Description',
        isRequired: false,
        maxLength: MerchantFieldLimits.maxDescriptionLength,
      );
      if (descriptionError != null) {
        return Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(message: descriptionError),
        );
      }
      trimmedDescription = description.trim().isEmpty ? null : description.trim();
      
      // Sanitize description to prevent XSS (FIX 7: Input sanitization)
      if (trimmedDescription != null) {
        trimmedDescription = sanitizeMultilineString(trimmedDescription);
      }
    }

    // FIX 5: Check document size before creation
    final estimatedSize = estimateDocumentSize(
      name: trimmedName,
      email: trimmedEmail,
      phone: trimmedPhone,
      city: trimmedCity,
      address: trimmedAddress,
      categories: finalCategories,
      description: trimmedDescription,
      hours: hours,
    );
    
    if (estimatedSize > MerchantFieldLimits.maxDocumentSizeBytes) {
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Merchant data is too large. Please reduce description or other fields. / Les données du commerce sont trop volumineuses. Veuillez réduire la description ou d\'autres champs.',
        ),
      );
    }

    // Check if merchant already exists (idempotency check)
    // This prevents duplicate creation if user verifies OTP multiple times
    final existsResult = await merchantRepository.merchantExists(trimmedUserId);
    final exists = existsResult.fold(
      (failure) => false, // On error, assume doesn't exist and proceed
      (exists) => exists,
    );

    if (exists) {
      // Merchant already exists - return existing merchant instead of creating new one
      // This handles the case where user verifies OTP multiple times
      // Try to get merchant by ownerUid first
      final existingMerchantResult = await merchantRepository.getMerchantByOwnerUid(trimmedUserId);
      final existingMerchant = existingMerchantResult.fold(
        (failure) => null, // On error, try by ID
        (merchant) => merchant,
      );

      if (existingMerchant != null) {
        // Found existing merchant by ownerUid
        return Right<MerchantFailure, Merchant>(existingMerchant);
      }

      // If not found by ownerUid, try by merchantId (since merchantId == user.uid for MVP)
      final merchantByIdResult = await merchantRepository.getMerchantById(trimmedUserId);
      final merchantById = merchantByIdResult.fold(
        (failure) => null, // On error, proceed with creation
        (merchant) => merchant,
      );

      if (merchantById != null) {
        // Found existing merchant by ID
        return Right<MerchantFailure, Merchant>(merchantById);
      }

      // If still null, this is an inconsistent state (exists check said true but can't find merchant)
      // Proceed with creation anyway - it's safe since merchantId == user.uid and we'll overwrite
      // This should not happen in normal flow, but handles edge case gracefully
    }

    // Create merchant entity with trimmed and sanitized values
    // Note: id will be set to userId in infrastructure layer (merchantId == user.uid for MVP)
    final merchant = Merchant(
      id: trimmedUserId, // Set to userId for MVP (merchantId == user.uid)
      ownerUid: trimmedUserId,
      name: trimmedName,
      email: trimmedEmail,
      phone: trimmedPhone,
      city: trimmedCity,
      address: trimmedAddress,
      categories: finalCategories,
      description: trimmedDescription,
      hours: hours,
      status: 'active',
    );

    // Create merchant and link to user (atomic batch write)
    // This also marks onboarding as complete in the same batch
    return await merchantRepository.createMerchantAndLinkUser(
      merchant: merchant,
      userId: trimmedUserId,
    );
  }
}

