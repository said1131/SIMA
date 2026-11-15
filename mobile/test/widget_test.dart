import 'package:flutter_test/flutter_test.dart';
import 'package:sima_mobile/main.dart';

void main() {
  testWidgets('Carga inicial de SimaApp', (WidgetTester tester) async {
    await tester.pumpWidget(const SimaApp());
    expect(find.byType(SimaApp), findsOneWidget);
  });
}
