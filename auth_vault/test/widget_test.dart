import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_pass_mobile/src/features/pin_fallback/presentation/scrambled_numpad.dart';

void main() {
  testWidgets('ScrambledNumpad renders 10 digits and action buttons', (WidgetTester tester) async {
    String entered = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScrambledNumpad(
          pinLength: 6,
          onCompleted: (val) => entered = val,
        ),
      ),
    ));
    expect(find.text('CLR'), findsOneWidget);
    expect(find.text('DEL'), findsOneWidget);
    for (int i = 0; i <= 9; i++) {
      expect(find.text(i.toString()), findsOneWidget);
    }
    expect(entered, isEmpty);
  });
}
