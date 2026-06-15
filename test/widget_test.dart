import 'package:eld_management_system/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Material 3 theme renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Text('ELD Management')),
      ),
    );
    expect(find.text('ELD Management'), findsOneWidget);
  });
}