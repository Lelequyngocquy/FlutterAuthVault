import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_pass_mobile/main.dart';
import 'package:vault_pass_mobile/src/common/configs/injection.dart';
import 'package:vault_pass_mobile/src/features/pin_fallback/presentation/scrambled_numpad.dart';

void main() {
  setUp(() {
    getIt.reset();
    setupDependencyInjection();
  });
  testWidgets('VaultPassApp mounts without crash', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({'DEVICE_ID': 'dev_test'});
    await tester.pumpWidget(const VaultPassApp());
  });
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
    expect(find.text('XÓA'), findsOneWidget);
    expect(find.text('LÙI'), findsOneWidget);
    for (int i = 0; i <= 9; i++) {
      expect(find.text(i.toString()), findsOneWidget);
    }
    expect(entered, isEmpty);
  });
}
