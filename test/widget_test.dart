import 'package:flutter_test/flutter_test.dart';
import 'package:pavetareeq/main.dart';

void main() {
  testWidgets('PaveTareeq launches', (WidgetTester tester) async {
    await tester.pumpWidget(const PaveTareeqApp());
    await tester.pump();

    expect(find.text('PaveTareeq'), findsOneWidget);
  });
}
