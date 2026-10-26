import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_pass_mobile/src/core/infrastructure/security/app_lifecycle_privacy_observer.dart';

void main() {
  testWidgets('PrivacyCurtainContainer shows blur curtain when inactive', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PrivacyCurtainContainer(
        child: Scaffold(body: Center(child: Text('Confidential Banking Data'))),
      ),
    ));
    expect(find.text('Confidential Banking Data'), findsOneWidget);
    expect(find.text('[PRIVACY CURTAIN ACTIVE]'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('[PRIVACY CURTAIN ACTIVE]'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('[PRIVACY CURTAIN ACTIVE]'), findsNothing);
  });
}
