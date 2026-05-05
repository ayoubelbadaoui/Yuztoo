import 'package:image_cropper/image_cropper.dart';
import '../shared/constants/merchant_colors.dart';

/// Launches the uCrop UI to let the user trim an image.
///
/// Pass [ratioX] + [ratioY] to lock the crop to a specific aspect ratio
/// (e.g. ratioX: 1, ratioY: 1 for square; 16:9 for banner).
/// Omit both to allow free-form cropping.
///
/// Returns the cropped file path on success, or `null` if the user cancels
/// or an error occurs.
Future<String?> cropImage(
  String sourcePath, {
  double? ratioX,
  double? ratioY,
}) async {
  final CropAspectRatio? aspectRatio =
      (ratioX != null && ratioY != null && ratioX > 0 && ratioY > 0)
          ? CropAspectRatio(ratioX: ratioX, ratioY: ratioY)
          : null;

  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: aspectRatio,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Recadrer',
        toolbarColor: MerchantColors.bgHeader,
        toolbarWidgetColor: MerchantColors.gold,
        activeControlsWidgetColor: MerchantColors.gold,
        initAspectRatio: aspectRatio != null
            ? CropAspectRatioPreset.original
            : CropAspectRatioPreset.original,
        lockAspectRatio: aspectRatio != null,
        hideBottomControls: false,
      ),
      IOSUiSettings(
        title: 'Recadrer',
        doneButtonTitle: 'Valider',
        cancelButtonTitle: 'Annuler',
        aspectRatioLockEnabled: aspectRatio != null,
        resetAspectRatioEnabled: aspectRatio == null,
      ),
    ],
  );
  return cropped?.path;
}
