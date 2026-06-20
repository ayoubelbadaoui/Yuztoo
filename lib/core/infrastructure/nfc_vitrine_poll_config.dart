/// Technology flags passed to [FlutterNfcKit.poll] for Yuztoo NTAG213 stickers.
abstract final class NfcVitrinePollConfig {
  /// ISO 14443 Type A/B — required for NTAG213 on iOS and Android.
  static const int iso14443Mask = 0x1 | 0x2;

  /// FeliCa (ISO 18092) — Android only; needs extra iOS entitlements if enabled.
  static const int iso18092Mask = 0x4;

  /// ISO 15693 — Android only; needs extra iOS entitlements if enabled.
  static const int iso15693Mask = 0x8;

  /// Bitmask for [FlutterNfcKit.poll] `technologies` on each mobile OS.
  static int technologyBitmask({required bool isIos}) {
    var mask = iso14443Mask;
    if (!isIos) {
      mask |= iso18092Mask | iso15693Mask;
    }
    return mask;
  }
}
