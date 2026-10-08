import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/shared/widgets/adaptive_image.dart';

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.red,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

Future<Size> _layout(
  WidgetTester tester, {
  required int imageWidth,
  required int imageHeight,
}) async {
  await tester.pumpWidget(const SizedBox());
  final bytes = await tester.runAsync(() => _png(imageWidth, imageHeight));
  final provider = MemoryImage(bytes!);
  await tester.runAsync(() => precacheImage(
        provider,
        tester.element(find.byType(SizedBox).first),
      ));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 300,
          child: AdaptiveImage(image: provider, maxHeight: 400),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.getSize(find.byType(AdaptiveImage));
}

void main() {
  testWidgets('landscape photo keeps its proportions', (tester) async {
    final size = await _layout(tester, imageWidth: 160, imageHeight: 90);
    expect(size.width, 300);
    expect(size.height, closeTo(300 * 9 / 16, 0.5));
  });

  testWidgets('square photo is shown square', (tester) async {
    final size = await _layout(tester, imageWidth: 100, imageHeight: 100);
    expect(size, const Size(300, 300));
  });

  testWidgets('portrait photo is taller, up to maxHeight', (tester) async {
    final portrait = await _layout(tester, imageWidth: 80, imageHeight: 100);
    expect(portrait.height, closeTo(375, 0.5));

    final veryTall = await _layout(tester, imageWidth: 50, imageHeight: 200);
    expect(veryTall.height, 400);
  });
}
