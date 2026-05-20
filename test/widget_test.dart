import 'package:flutter_test/flutter_test.dart';
import 'package:ft_hangouts/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
  });
}