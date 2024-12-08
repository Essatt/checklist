// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:checklist_flutter/main.dart';
import 'package:checklist_flutter/models/checklist_model.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('App starts with templates screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ChecklistModel(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial screen
      expect(find.text('Process Templates'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify bottom navigation
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
    });

    testWidgets('Can navigate between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ChecklistModel(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Start at templates
      expect(find.text('Process Templates'), findsOneWidget);

      // Navigate to active
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(find.text('Active Processes'), findsOneWidget);

      // Navigate to archive
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.text('Archived Processes'), findsOneWidget);
    });

    testWidgets('Shows empty state messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ChecklistModel(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Templates empty state
      expect(find.text('No templates yet'), findsOneWidget);

      // Active empty state
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(find.text('No active processes'), findsOneWidget);

      // Archive empty state
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.text('No archived processes'), findsOneWidget);
    });
  });
}
