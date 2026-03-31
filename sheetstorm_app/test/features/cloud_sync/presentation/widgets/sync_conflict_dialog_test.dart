import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';
import 'package:sheetstorm/features/cloud_sync/presentation/widgets/sync_conflict_dialog.dart';

SyncConflict _conflict({String resolvedWith = 'server'}) {
  final version = SyncVersion(deviceId: 'dev1', timestamp: DateTime(2025, 6, 1));
  final delta = SyncDelta(
    entityType: 'sheet_music',
    entityId: 'sm-001',
    operation: 'update',
    version: version,
  );
  return SyncConflict(
    entityType: 'sheet_music',
    entityId: 'sm-001',
    localDelta: delta,
    serverDelta: delta,
    resolvedWith: resolvedWith,
  );
}

Widget _buildDialog(SyncConflict conflict, {VoidCallback? onDismiss}) {
  return MaterialApp(
    home: Scaffold(
      body: SyncConflictDialog(
        conflict: conflict,
        onDismiss: onDismiss ?? () {},
      ),
    ),
  );
}

void main() {
  group('SyncConflictDialog — rendert korrekt', () {
    testWidgets('rendert ohne Fehler', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict()));
      expect(tester.takeException(), isNull);
      expect(find.byType(SyncConflictDialog), findsOneWidget);
    });

    testWidgets('zeigt Titel', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict()));
      expect(find.text('Synchronisationskonflikt'), findsOneWidget);
    });

    testWidgets('zeigt EntityType im Text', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict()));
      expect(find.textContaining('sheet_music'), findsWidgets);
    });

    testWidgets('zeigt Last-Write-Wins Information', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict()));
      expect(find.textContaining('Last-Write-Wins'), findsOneWidget);
    });

    testWidgets('zeigt Server-Version für resolvedWith=server', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict(resolvedWith: 'server')));
      expect(find.textContaining('Server-Version'), findsOneWidget);
    });

    testWidgets('zeigt Lokale Version für resolvedWith=local', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict(resolvedWith: 'local')));
      expect(find.textContaining('Lokale Version'), findsOneWidget);
    });
  });

  group('SyncConflictDialog — Interaktion', () {
    testWidgets('Verstanden-Button ruft onDismiss auf', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        _buildDialog(_conflict(), onDismiss: () => dismissed = true),
      );

      await tester.tap(find.text('Verstanden'));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('Dismiss-Button ist vorhanden', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict()));
      expect(find.text('Verstanden'), findsOneWidget);
    });

    testWidgets('Button hat ausreichende Touch-Größe (min 44px)', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict()));

      final button = find.byType(TextButton);
      expect(button, findsOneWidget);

      final size = tester.getSize(button);
      // TextButton with padding should be >= 44px tall
      expect(size.height, greaterThanOrEqualTo(44.0));
    });
  });
}
