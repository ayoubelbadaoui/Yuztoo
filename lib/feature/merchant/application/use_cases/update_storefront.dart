import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../domain/entities/merchant.dart';
import '../../domain/merchant_failure.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../../../storage/application/use_cases/upload_banner.dart';
import '../../../storage/application/use_cases/upload_logo.dart';

/// Use case for updating merchant storefront.
///
/// Uploads logo and banner to Firebase Storage when provided, then updates
/// all storefront fields in Firestore (display_name, description, categories,
/// logo_url, banner_url, phone, address, website_url).
class UpdateStorefront {
  const UpdateStorefront({
    required this.merchantRepository,
    required this.uploadLogo,
    required this.uploadBanner,
  });

  final MerchantRepository merchantRepository;
  final UploadLogo uploadLogo;
  final UploadBanner uploadBanner;

  /// Update storefront for a merchant.
  ///
  /// [merchantId] - Merchant ID
  /// [displayName] - Display name for storefront (optional)
  /// [description] - Business description (optional)
  /// [categories] - List of categories (optional)
  /// [logoFilePath] - Local file path to upload as logo (optional)
  /// [bannerFilePath] - Local file path to upload as banner (optional)
  /// [phone] - Business phone (optional)
  /// [address] - Business address (optional)
  /// [city] - Business city (optional)
  /// [websiteUrl] - Website URL (optional)
  /// [newsImageUrls] - Actualite slider image URLs (optional)
  /// [status] - Merchant visibility status ('active'/'inactive')
  /// [hours] - Business hours map (optional)
  /// [clearMerchantCityField] - When true and [city] is null, removes `city` in Firestore (profile save).
  ///
  /// Returns Result<Merchant> - Updated merchant on success, failure on error
  Future<Result<Merchant>> call({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoFilePath,
    String? bannerFilePath,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? websiteUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    String? welcomeGiftDescription,
    String? merchantType,
    String? categoryId,
    String? subcategoryTitle,
    bool clearMerchantCityField = false,
  }) async {
    if (merchantId.isEmpty) {
      return const Left(
        MerchantUnexpectedFailure(
          message: 'L\'identifiant du commerce est requis',
        ),
      );
    }

    String? logoUrl;
    String? bannerUrl;

    // Step 1: Upload logo if provided
    if (logoFilePath != null && logoFilePath.isNotEmpty) {
      final uploadResult = await uploadLogo.call(
        filePath: logoFilePath,
        merchantId: merchantId,
      );

      uploadResult.fold(
        (failure) => null,
        (url) => logoUrl = url,
      );

      if (logoUrl == null) {
        return uploadResult.fold<Result<Merchant>>(
          (failure) => Left(
            MerchantUnexpectedFailure(
              message: 'Échec du téléversement',
              cause: failure.cause,
              stackTrace: failure.stackTrace,
            ),
          ),
          (_) => const Left(
            MerchantUnexpectedFailure(
              message: 'Échec du téléversement',
            ),
          ),
        );
      }
    }

    // Step 2: Upload banner if provided
    if (bannerFilePath != null && bannerFilePath.isNotEmpty) {
      final uploadResult = await uploadBanner.call(
        filePath: bannerFilePath,
        merchantId: merchantId,
      );

      uploadResult.fold(
        (failure) => null,
        (url) => bannerUrl = url,
      );

      if (bannerUrl == null) {
        return uploadResult.fold<Result<Merchant>>(
          (failure) => Left(
            MerchantUnexpectedFailure(
              message: 'Échec du téléversement de la bannière',
              cause: failure.cause,
              stackTrace: failure.stackTrace,
            ),
          ),
          (_) => const Left(
            MerchantUnexpectedFailure(
              message: 'Échec du téléversement de la bannière',
            ),
          ),
        );
      }
    }

    // Step 3: Update Firestore with all storefront fields (including hours)
    final updateResult = await merchantRepository.updateMerchant(
      merchantId: merchantId,
      displayName: displayName,
      description: description,
      categories: categories,
      logoUrl: logoUrl,
      phone: phone,
      email: email,
      address: address,
      city: city,
      websiteUrl: websiteUrl,
      bannerUrl: bannerUrl,
      newsImageUrls: newsImageUrls,
      status: status,
      hours: hours,
      welcomeGiftDescription: welcomeGiftDescription,
      merchantType: merchantType,
      categoryId: categoryId,
      subcategoryTitle: subcategoryTitle,
      clearCityField: clearMerchantCityField,
    );

    // Edge case: Upload succeeded but Firestore update failed
    // Logo is already uploaded but not linked to merchant
    // We still return the Firestore error (user can retry)
    return updateResult.fold<Result<Merchant>>(
      (failure) {
        // Firestore update failed - logo might be orphaned in Storage
        // But we return the error so user knows the save failed
        // In production, you might want to delete the uploaded logo here
        return Left(failure);
      },
      (merchant) => Right(merchant),
    );
  }
}

