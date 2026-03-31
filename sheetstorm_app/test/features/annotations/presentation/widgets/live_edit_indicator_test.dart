import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_sync_notifier.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/live_edit_indicator.dart';

void main() {
  Widget _wrap(AnnotationSyncState syncState) {
    return ProviderScope(
      overrides: [
        annotationSyncNotifierProvider
            .overrideWith(() => _FakeSyncNotifier(syncState)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: LiveEditIndicator()),
      ),
    );
  }

  group('LiveEditIndicator', () {
    testWidgets('zeigt nichts wenn keine aktiven Editoren', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.connected,
      )));
      await tester.pump();

      // Should not show any editing banners
      expect(find.textContaining('zeichnet'), findsNothing);
    });

    testWidgets('zeigt Banner wenn ein User aktiv zeichnet', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.connected,
        activeEditors: {'Max M.': 'elem-1'},
      )));
      await tester.pump();

      expect(find.textContaining('Max M.'), findsOneWidget);
      expect(find.textContaining('zeichnet'), findsOneWidget);
    });

    testWidgets('zeigt mehrere aktive Editoren', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.connected,
        activeEditors: {'Max M.': 'elem-1', 'Anna H.': 'elem-2'},
      )));
      await tester.pump();

      expect(find.textContaining('Max M.'), findsOneWidget);
      expect(find.textContaining('Anna H.'), findsOneWidget);
    });

    testWidgets('hat Semantics für Accessibility', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.connected,
        activeEditors: {'Max M.': 'elem-1'},
      )));
      await tester.pump();

      expect(
        find.bySemanticsLabel(RegExp(r'zeichnet')),
        findsWidgets,
      );
    });
  });

  group('ConflictBanner', () {
    testWidgets('zeigt nichts wenn kein Konflikt', (tester) async {
      await tester.pumpWidget(_wrap(const AnnotationSyncState(
        status: AnnotationSyncStatus.connected,
      )));
      await tester.pump();

      expect(find.textContaining('übernommen'), findsNothing);
    });

    testWidgets('zeigt Banner wenn Konflikt vorhanden', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          annotationSyncNotifierProvider.overrideWith(() => _FakeSyncNotifier(
                AnnotationSyncState(
                  status: AnnotationSyncStatus.connected,
                  lastConflict: ConflictInfo(
                    elementId: 'elem-1',
                    winnerUserId: 'Max M.',
                    loserUserId: 'Anna H.',
                    resolvedAt: DateTime.utc(2026, 4, 1),
                  ),
                ),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LiveEditIndicator()),
        ),
      ));
      await tester.pump();

      expect(find.textContaining('Max M.'), findsOneWidget);
      expect(find.textContaining('übernommen'), findsOneWidget);
    });
  });
}

class _FakeSyncNotifier extends AnnotationSyncNotifier {
  _FakeSyncNotifier(this._initialState);
  final AnnotationSyncState _initialState;

  @override
  AnnotationSyncState build() => _initialState;
}
