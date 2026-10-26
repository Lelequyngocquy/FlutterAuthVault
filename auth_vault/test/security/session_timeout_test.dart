import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_pass_mobile/src/core/infrastructure/security/session_timeout_manager.dart';

void main() {
  testWidgets('SessionTimeoutManager triggers timeout when idle', (WidgetTester tester) async {
    bool timedOut = false;
    await tester.pumpWidget(MaterialApp(
      home: SessionTimeoutManager(
        timeoutDuration: const Duration(milliseconds: 100),
        onTimeout: () => timedOut = true,
        child: const Scaffold(body: Center(child: Text('Protected Vault Screen'))),
      ),
    ));
    expect(timedOut, isFalse);
    await tester.pump(const Duration(milliseconds: 150));
    expect(timedOut, isTrue);
  });
  testWidgets('SessionTimeoutManager resets timer on user tap', (WidgetTester tester) async {
    bool timedOut = false;
    await tester.pumpWidget(MaterialApp(
      home: SessionTimeoutManager(
        timeoutDuration: const Duration(milliseconds: 100),
        onTimeout: () => timedOut = true,
        child: const Scaffold(body: Center(child: Text('Tap Me'))),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 60));
    expect(timedOut, isFalse);
    await tester.tap(find.text('Tap Me'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(timedOut, isFalse);
    await tester.pump(const Duration(milliseconds: 60));
    expect(timedOut, isTrue);
  });
}
