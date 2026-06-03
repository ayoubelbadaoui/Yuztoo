import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../shared/constants/merchant_colors.dart';
import '../shared/widgets/snackbar.dart';
import 'image_crop_utils.dart';

/// Outcome of [pickImageWithSourceChoice].
enum _PickOutcomeKind { picked, cancelled, error }

/// Single-entrypoint helper for the "pick a profile / logo / banner photo"
/// flow used across onboarding and account screens.
///
/// Behaviour:
/// 1. Shows a YuzToo-styled bottom sheet offering **Camera** and **Gallery**.
/// 2. On selection, calls [ImagePicker.pickImage] with the supplied bounds.
/// 3. If [cropRatioX]/[cropRatioY]/[cropCircleShape] are provided, runs the
///    image through [cropImage] and returns the cropped path (falls back to
///    the un-cropped path if the user cancels the cropper).
/// 4. Catches every exception thrown along the way (camera permission denied,
///    plugin internal failure, OS killed activity, OOM during decode), logs
///    via `dart:developer`, and shows a single user-facing SnackBar.
///
/// Returns the chosen file path on success, or `null` if the user cancelled
/// at any step (sheet dismissed, picker cancelled) **or** if an error was
/// caught (in which case the SnackBar has already been shown). Callers
/// therefore only need a `null`-check before applying the path.
Future<String?> pickImageWithSourceChoice({
  required BuildContext context,
  ImagePicker? picker,
  String sheetTitle = 'Choisir une photo',
  String cameraLabel = 'Prendre une photo',
  String galleryLabel = 'Choisir depuis la galerie',
  double? maxWidth,
  double? maxHeight,
  int imageQuality = 85,
  double? cropRatioX,
  double? cropRatioY,
  bool cropCircleShape = false,
}) async {
  final ImagePicker effectivePicker = picker ?? ImagePicker();

  final ImageSource? source = await _showSourceChoiceSheet(
    context: context,
    title: sheetTitle,
    cameraLabel: cameraLabel,
    galleryLabel: galleryLabel,
  );
  if (source == null || !context.mounted) return null;

  final _PickOutcome outcome = await _pickAndOptionallyCrop(
    picker: effectivePicker,
    source: source,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: imageQuality,
    cropRatioX: cropRatioX,
    cropRatioY: cropRatioY,
    cropCircleShape: cropCircleShape,
  );

  switch (outcome.kind) {
    case _PickOutcomeKind.picked:
      return outcome.path;
    case _PickOutcomeKind.cancelled:
      return null;
    case _PickOutcomeKind.error:
      if (context.mounted) {
        showErrorSnackbar(
          context,
          source == ImageSource.camera
              ? 'Impossible d\'ouvrir la caméra. Vérifiez l\'autorisation dans Réglages.'
              : 'Impossible d\'ouvrir la galerie. Vérifiez l\'autorisation dans Réglages.',
        );
      }
      return null;
  }
}

class _PickOutcome {
  const _PickOutcome.picked(this.path)
      : kind = _PickOutcomeKind.picked;
  const _PickOutcome.cancelled()
      : path = null,
        kind = _PickOutcomeKind.cancelled;
  const _PickOutcome.error()
      : path = null,
        kind = _PickOutcomeKind.error;

  final _PickOutcomeKind kind;
  final String? path;
}

Future<_PickOutcome> _pickAndOptionallyCrop({
  required ImagePicker picker,
  required ImageSource source,
  double? maxWidth,
  double? maxHeight,
  int imageQuality = 85,
  double? cropRatioX,
  double? cropRatioY,
  bool cropCircleShape = false,
}) async {
  XFile? picked;
  try {
    picked = await picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  } catch (error, stackTrace) {
    developer.log(
      'pickImage failed (source=$source)',
      name: 'image_pick_with_source',
      error: error,
      stackTrace: stackTrace,
    );
    return const _PickOutcome.error();
  }

  if (picked == null) {
    return const _PickOutcome.cancelled();
  }

  final bool wantsCrop = (cropRatioX != null && cropRatioY != null) ||
      cropCircleShape;
  if (!wantsCrop) {
    return _PickOutcome.picked(picked.path);
  }

  final cropped = await cropImage(
    picked.path,
    ratioX: cropRatioX,
    ratioY: cropRatioY,
    circleShape: cropCircleShape,
  );
  // [cropImage] already swallows internal errors and returns null. If the
  // user simply cancelled the cropper we still want the un-cropped pick
  // — better UX than forcing them to start over from the bottom sheet.
  // The picked file is guaranteed to exist at this point.
  if (cropped != null && File(cropped).existsSync()) {
    return _PickOutcome.picked(cropped);
  }
  return _PickOutcome.picked(picked.path);
}

Future<ImageSource?> _showSourceChoiceSheet({
  required BuildContext context,
  required String title,
  required String cameraLabel,
  required String galleryLabel,
}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: MerchantColors.bgMain,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: MerchantColors.textGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: MerchantColors.gold,
              ),
              title: Text(
                cameraLabel,
                style: GoogleFonts.outfit(color: MerchantColors.textWhite),
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: MerchantColors.gold,
              ),
              title: Text(
                galleryLabel,
                style: GoogleFonts.outfit(color: MerchantColors.textWhite),
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}
