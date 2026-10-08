import 'dart:developer' as developer;

import 'package:image_cropper/image_cropper.dart';
import '../shared/constants/merchant_colors.dart';

/// Same list image_cropper uses when none is given.
const List<CropAspectRatioPresetData> _defaultPresets = [
  CropAspectRatioPreset.original,
  CropAspectRatioPreset.square,
  CropAspectRatioPreset.ratio3x2,
  CropAspectRatioPreset.ratio4x3,
  CropAspectRatioPreset.ratio16x9,
];

/// Vertical 4:5 format (portrait product / storefront photos).
class CropAspectRatioPortrait4x5 implements CropAspectRatioPresetData {
  const CropAspectRatioPortrait4x5();

  @override
  String get name => '4x5';

  @override
  (int, int)? get data => (4, 5);
}

/// Launches the uCrop UI to let the user trim an image.
///
/// Pass [ratioX] + [ratioY] to lock the crop to a specific aspect ratio
/// (e.g. ratioX: 1, ratioY: 1 for square; 16:9 for banner).
/// Omit both to allow free-form cropping.
///
/// Pass [circleShape] = true for profile-photo flows — uCrop shows a circle
/// guide (output is still a square file, ready for circular clipping in Flutter).
///
/// Pass [presets] to choose which formats the user can switch between when
/// the ratio is not locked, and [maxWidth] / [maxHeight] to cap the output.
///
/// Returns the cropped file path on success, or `null` if the user cancels.
///
/// **Error handling:** any exception thrown by uCrop / iOS image cropper (e.g.
/// uCrop fails on certain Android device GPUs, file path resolution race on
/// iOS, OOM during decode) is caught here and a `null` is returned instead
/// — so the caller can fall back to the un-cropped path without an
/// unhandled async exception bubbling up to the framework. The error is
/// emitted via `dart:developer.log` so it's still observable in dev tools.
Future<String?> cropImage(
  String sourcePath, {
  double? ratioX,
  double? ratioY,
  bool circleShape = false,
  List<CropAspectRatioPresetData>? presets,
  int? maxWidth,
  int? maxHeight,
  int compressQuality = 90,
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

  try {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: aspectRatio,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      compressQuality: compressQuality,
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
          aspectRatioPresets: presets ?? _defaultPresets,
        ),
        IOSUiSettings(
          title: 'Recadrer',
          doneButtonTitle: 'Valider',
          cancelButtonTitle: 'Annuler',
          aspectRatioLockEnabled: hasRatio,
          resetAspectRatioEnabled: !hasRatio,
          cropStyle: style,
          aspectRatioPresets: presets ?? _defaultPresets,
        ),
      ],
    );
    return cropped?.path;
  } catch (error, stackTrace) {
    developer.log(
      'cropImage failed — falling back to source path',
      name: 'image_crop_utils',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
