import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../loyalty/application/use_cases/process_vitrine_scan_visit.dart';

/// Debug-only: when set, [StoreProfileScreen] applies this [ScanVisitResult]
/// instead of calling [ProcessVitrineScanVisit] once on the next scan arrival.
/// Cleared automatically after consumption. Gated by [kNfcDebugEnabled].
final nfcDebugForcedScanVisitResultProvider =
    StateProvider<ScanVisitResult?>((ref) => null);
