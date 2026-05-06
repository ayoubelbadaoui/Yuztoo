import 'package:image_cropper/image_cropper.dart';
import '../shared/constants/merchant_colors.dart';

/// Launches the uCrop UI to let the user trim an image.
///
/// Pass [ratioX] + [ratioY] to lock the crop to a specific aspect ratio
/// (e.g. ratioX: 1, ratioY: 1 for square; 16:9 for banner).
/// Omit both to allow free-form cropping.
///
/// Pass [circleShape] = true for profile-photo flows — uCrop shows a circle
/// guide (output is still a square file, ready for circular clipping in Flutter).
///
/// Returns the cropped file path on success, or `null` if the user cancels
/// or an error occurs.
Future<String?> cropImage(
  String sourcePath, {
  double? ratioX,
  double? ratioY,
  bool circleShape = false,
}) async {
  final double rx = ratioX ?? 0;
  final double ry = ratioY ?? 0;
  final bool hasRatio = rx > 0 && ry > 0;
  final CropAspectRatio? aspectRatio =
      hasRatio ? CropAspectRatio(ratioX: rx, ratioY: ry) : null;

  // Pick the closest built-in preset for the initial state (cosmetic only;
  // if lockAspectRatio is true the user cannot change it anyway).
  CropAspectRatioPreset initPreset() {
    if (!hasRatio) return CropAspectRatioPreset.original;
    final ratio = rx / ry;
    if ((ratio - 1.0).abs() < 0.01) return CropAspectRatioPreset.square;
    if ((ratio - 16 / 9).abs() < 0.1) return CropAspectRatioPreset.ratio16x9;
    if ((ratio - 4 / 3).abs() < 0.05) return CropAspectRatioPreset.ratio4x3;
    if ((ratio - 3 / 2).abs() < 0.05) return CropAspectRatioPreset.ratio3x2;
    return CropAspectRatioPreset.original;
  }

  // In image_cropper v12, cropStyle is set per-platform via uiSettings.
  final style = circleShape ? CropStyle.circle : CropStyle.rectangle;

  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: aspectRatio,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Recadrer',
        toolbarColor: MerchantColors.bgHeader,
        toolbarWidgetColor: MerchantColors.gold,
        activeControlsWidgetColor: MerchantColors.gold,
        initAspectRatio: initPreset(),
        lockAspectRatio: hasRatio,
        hideBottomControls: false,
        cropStyle: style,
      ),
      IOSUiSettings(
        title: 'Recadrer',
        doneButtonTitle: 'Valider',
        cancelButtonTitle: 'Annuler',
        aspectRatioLockEnabled: hasRatio,
        resetAspectRatioEnabled: !hasRatio,
        cropStyle: style,
      ),
    ],
  );
  return cropped?.path;
}
