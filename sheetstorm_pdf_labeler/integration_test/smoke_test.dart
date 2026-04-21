import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm_pdf_labeler/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Simple smoke tests for the UI
/// These are E2E-style tests that run in the flutter test environment
void main() {
  group('PDF Labeler UI Smoke Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    testWidgets('App launches and shows all main UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: PdfLabelerApp()));
      await tester.pumpAndSettle();

      expect(find.text('Sheetstorm PDF Labeler'), findsOneWidget);
      expect(find.text('Source Folder'), findsOneWidget);
      expect(find.text('Target Folder'), findsOneWidget);
      expect(find.text('GitHub PAT'), findsOneWidget);
      expect(find.text('Start Labeling'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Browse'), findsNWidgets(2));
    });

    testWidgets('Token field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: PdfLabelerApp()));
      await tester.pumpAndSettle();

      final tokenField = find.widgetWithText(TextField, 'GitHub PAT');
      expect(tokenField, findsOneWidget);

      await tester.enterText(tokenField, 'ghp_test_token_123');
      await tester.pumpAndSettle();

      final controller = tester.widget<TextField>(tokenField).controller;
      expect(controller?.text, 'ghp_test_token_123');
    });

    testWidgets('Remember checkbox works', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: PdfLabelerApp()));
      await tester.pumpAndSettle();

      final rememberCheckbox = find.widgetWithText(CheckboxListTile, 'Remember token securely');
      expect(rememberCheckbox, findsOneWidget);

      final initialValue = tester.widget<CheckboxListTile>(rememberCheckbox).value;
      expect(initialValue, isFalse);

      await tester.tap(rememberCheckbox);
      await tester.pumpAndSettle();

      final newValue = tester.widget<CheckboxListTile>(rememberCheckbox).value;
      expect(newValue, isTrue);
    });

    testWidgets('Start button disabled when fields incomplete', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: PdfLabelerApp()));
      await tester.pumpAndSettle();

      final startButton = find.widgetWithIcon(FilledButton, Icons.play_arrow);
      expect(startButton, findsOneWidget);

      final button = tester.widget<FilledButton>(startButton);
      expect(button.onPressed, isNull, reason: 'Button should be disabled when fields are not filled');
    });
  });
}
