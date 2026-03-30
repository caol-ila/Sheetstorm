import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';
import 'package:sheetstorm/features/cloud_sync/presentation/widgets/sync_status_indicator.dart';

Widget _buildIndicator(SyncStatus status, {double size = 20.0}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SyncStatusIndicator(status: status, size: size),
      ),
    ),
  );
}

void main() {
  group('SyncStatusIndicator — rendert für jeden Status', () {
    testWidgets('rendert ohne Fehler bei idle', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.idle));
      expect(tester.takeException(), isNull);
      expect(find.byType(SyncStatusIndicator), findsOneWidget);
    });

    testWidgets('rendert ohne Fehler bei synced', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.synced));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert ohne Fehler bei syncing', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.syncing));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert ohne Fehler bei conflict', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.conflict));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert ohne Fehler bei offline', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.offline));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert ohne Fehler bei error', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.error));
      expect(tester.takeException(), isNull);
    });
  });

  group('SyncStatusIndicator — korrekte Widgets', () {
    testWidgets('syncing zeigt CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.syncing));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('synced zeigt Icon', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.synced));
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('conflict zeigt Icon', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.conflict));
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('offline zeigt Icon', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.offline));
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('error zeigt Icon', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.error));
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('idle zeigt Icon', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.idle));
      expect(find.byType(Icon), findsOneWidget);
    });
  });

  group('SyncStatusIndicator — Größe', () {
    testWidgets('SizedBox hat korrekte Größe', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.idle, size: 32.0));

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SyncStatusIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 32.0);
      expect(sizedBox.height, 32.0);
    });
  });

  group('SyncStatusIndicator — Semantik', () {
    testWidgets('hat Semantics-Label bei syncing', (tester) async {
      await tester.pumpWidget(_buildIndicator(SyncStatus.syncing));
      // Should have a Semantics widget for accessibility
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
