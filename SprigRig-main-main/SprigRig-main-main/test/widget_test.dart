import 'package:flutter_test/flutter_test.dart';
import 'package:sprigrig/app.dart';
import 'package:sprigrig/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SprigRigApp());

    // Verify that our app starts properly
    expect(find.text('SprigRig'), findsOneWidget);
  });
}
