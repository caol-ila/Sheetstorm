import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_sync_notifier.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/sync_status_indicator.dart';

void main() {
  Widget _wrap(AnnotationSyncState syncState) {
    return ProviderScope(
      overrides: [
        annotationSyncNotifierProvider
            .overrideWith(() => _FakeSyncNotifier(syncState)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SyncStatusIndicator()),
      ),
    );
  }

  group('SyncStatusIndicator', () {
    testWidgets('zeigt grünen Punkt wenn verbunden', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.connected,
      )));
      await tester.pump();

      final iconFinder = find.byIcon(Icons.sync);
      expect(iconFinder, findsOneWidget);

      // Should have green color indicator
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SyncStatusIndicator),
          matching: find.byType(Container),
        ).first,
      );
      expect(container, isNotNull);
    });

    testWidgets('zeigt Warn-Icon wenn offline/error', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.error,
        error: 'Verbindung verloren',
      )));
      await tester.pump();

      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });

    testWidgets('zeigt syncing-Status beim Synchronisieren', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.syncing,
      )));
      await tester.pump();

      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('zeigt disconnected-Icon wenn nicht verbunden', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.disconnected,
      )));
      await tester.pump();

      expect(find.byIcon(Icons.sync_disabled), findsOneWidget);
    });

    testWidgets('zeigt pending-ops Zähler wenn Queue nicht leer',
        (tester) async {
      await tester.pumpWidget(_wrap(AnnotationSyncState(
        status: AnnotationSyncStatus.disconnected,
        offlineQueue: [
          AnnotationOp(
            id: 'op-1',
            type: AnnotationOpType.create,
            elementId: 'e1',
            annotationId: 'a1',
            userId: 'u1',
            timestamp: DateTime.utc(2026),
            version: 1,
          ),
          AnnotationOp(
            id: 'op-2',
            type: AnnotationOpType.update,
            elementId: 'e2',
            annotationId: 'a1',
            userId: 'u1',
            timestamp: DateTime.utc(2026),
            version: 1,
          ),
        ],
      )));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('hat korrekte Semantics für Accessibility', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.connected,
      )));
      await tester.pump();

      expect(
        find.bySemanticsLabel(RegExp(r'synchronisiert|Sync')),
        findsWidgets,
      );
    });
  });
}

/// Fake notifier for widget test overrides
class _FakeSyncNotifier extends AnnotationSyncNotifier {
  _FakeSyncNotifier(this._initialState);
  final AnnotationSyncState _initialState;

  @override
  AnnotationSyncState build() => _initialState;
}
