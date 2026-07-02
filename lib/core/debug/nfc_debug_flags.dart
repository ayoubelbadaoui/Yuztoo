/// Enables NFC/scan debug tools (emulator sheet, forced funnel overrides).
///
/// Opt-in ONLY — never shipped, even in a side-loaded debug APK. Enable
/// locally with either:
/// `--dart-define=SHOW_SCAN_SIMULATOR=true`
/// `--dart-define=SHOW_NFC_DEBUG=true`
///
/// (Previously this was also `true` whenever [kDebugMode] was set, which leaked
/// the simulator into the beta APKs distributed from the landing page — those
/// are `flutter build apk --debug`. Decoupling it keeps testers from ever
/// seeing the debug emulator.)
const bool kNfcDebugEnabled =
    bool.fromEnvironment('SHOW_SCAN_SIMULATOR', defaultValue: false) ||
    bool.fromEnvironment('SHOW_NFC_DEBUG', defaultValue: false);
