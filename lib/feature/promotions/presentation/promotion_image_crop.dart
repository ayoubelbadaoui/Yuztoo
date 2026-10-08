import 'package:image_cropper/image_cropper.dart';

import '../../../core/utils/image_crop_utils.dart';

/// Picker cap applied before cropping: large enough that a zoomed-in crop of
/// a portrait photo stays sharp, small enough to avoid decoding 12 MP files.
const int promotionImagePickMaxSide = 2400;

/// Final size of the uploaded promotion image (longest side).
const int promotionImageUploadMaxSide = 1600;

/// Formats the merchant can switch between; "original" keeps the photo as is.
const List<CropAspectRatioPresetData> promotionImageCropPresets = [
  CropAspectRatioPreset.original,
  CropAspectRatioPreset.square,
  CropAspectRatioPortrait4x5(),
  CropAspectRatioPreset.ratio4x3,
  CropAspectRatioPreset.ratio16x9,
];

/// Lets the merchant crop a promotion photo in any format. Client screens
/// display it with its own proportions (see `AdaptiveImage`).
Future<String?> cropPromotionImage(String sourcePath) => cropImage(
      sourcePath,
      presets: promotionImageCropPresets,
      maxWidth: promotionImageUploadMaxSide,
      maxHeight: promotionImageUploadMaxSide,
      compressQuality: 85,
    );
