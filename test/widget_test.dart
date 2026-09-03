// Basic smoke test for the Lessify app root widget.
//
// The full app talks to Firebase, shared_preferences, and the network on
// startup, so this test only asserts that `MyApp` builds a `CupertinoApp`
// without throwing. Deeper localization coverage lives in `l10n_test.dart`.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_app/main.dart';

void main() {
  testWidgets('MyApp boots and renders a CupertinoApp root',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CupertinoApp), findsOneWidget);
  });
}
