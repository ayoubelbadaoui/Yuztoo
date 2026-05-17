import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/store_profile/application/providers.dart';

void main() {
  test('pendingVitrineScanIntentProvider defaults to none', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(pendingVitrineScanIntentProvider),
      VitrineScanIntent.none,
    );
  });

  test('scan flow sets and clears fromQrOrNfc intent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pendingVitrineScanIntentProvider.notifier).state =
        VitrineScanIntent.fromQrOrNfc;
    expect(
      container.read(pendingVitrineScanIntentProvider),
      VitrineScanIntent.fromQrOrNfc,
    );

    container.read(pendingVitrineScanIntentProvider.notifier).state =
        VitrineScanIntent.none;
    expect(
      container.read(pendingVitrineScanIntentProvider),
      VitrineScanIntent.none,
    );
  });
}
