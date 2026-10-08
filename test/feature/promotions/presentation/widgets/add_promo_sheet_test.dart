import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/promotions/presentation/widgets/add_promo_sheet.dart';

Finder _descriptionField() => find.byWidgetPredicate(
      (w) =>
          w is TextField && w.decoration?.hintText == 'Description (optionnel)',
    );

void main() {
  testWidgets('promotion description accepts up to 150 characters',
      (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddPromoSheet())),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(_descriptionField());
    expect(field.maxLength, 150);
    expect(field.maxLines, 4);

    await tester.enterText(_descriptionField(), 'a' * 200);
    await tester.pump();

    expect(field.controller!.text.length, 150);
    expect(find.text('150 / 150'), findsOneWidget);
  });
}
