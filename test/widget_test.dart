import 'package:flutter_test/flutter_test.dart';
import 'package:jnanetra/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JnanetraApp());
    expect(find.text('Jnanetra'), findsOneWidget);
    expect(find.text('AI Vision Assistant'), findsOneWidget);

    // Allow the navigation timer to fire
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
