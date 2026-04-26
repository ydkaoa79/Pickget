import 'package:flutter_test/flutter_test.dart';

import 'package:pickget/main.dart';

void main() {
  testWidgets('앱 정상 실행 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const PickGetApp());
    expect(find.text('PickGet'), findsOneWidget);
  });
}
