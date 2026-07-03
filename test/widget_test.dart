import 'package:flutter_test/flutter_test.dart';
import 'package:olt_inventory/main.dart';

void main() {
  testWidgets('App shows setup screen when Supabase is not configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OltInventoryApp());
    await tester.pumpAndSettle();

    expect(find.text('Setup Required'), findsOneWidget);
  });
}
