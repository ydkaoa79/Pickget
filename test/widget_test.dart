import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickget/main.dart';

void main() {
  testWidgets('PickGetApp builds with an injected test home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const PickGetApp(home: SizedBox(key: Key('test-home'))),
    );

    expect(find.byKey(const Key('test-home')), findsOneWidget);
  });
}
