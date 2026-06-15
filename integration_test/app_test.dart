import 'package:eld_management_system/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches splash screen', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('ELD Management'), findsOneWidget);
  });
}