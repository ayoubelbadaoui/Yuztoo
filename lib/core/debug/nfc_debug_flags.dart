import 'package:flutter/foundation.dart';

/// Enables NFC/scan debug tools (emulator sheet, forced funnel overrides).
///
/// Active in debug builds, or when built with either:
/// `--dart-define=SHOW_SCAN_SIMULATOR=true`
/// `--dart-define=SHOW_NFC_DEBUG=true`
const bool kNfcDebugEnabled =
    kDebugMode ||
    bool.fromEnvironment('SHOW_SCAN_SIMULATOR', defaultValue: false) ||
    bool.fromEnvironment('SHOW_NFC_DEBUG', defaultValue: false);
