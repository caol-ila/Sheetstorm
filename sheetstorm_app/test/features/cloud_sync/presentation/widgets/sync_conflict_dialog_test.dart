import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';
import 'package:sheetstorm/features/cloud_sync/presentation/widgets/sync_conflict_dialog.dart';

SyncConflict _conflict({String resolution = 'server'}) {
  return SyncConflict(
    clientChangeId: 'cc-1',
    entityType: 'sheet_music',
    entityId: 'sm-001',
    serverChangedAt: DateTime(2025, 6, 1),
    resolution: resolution,
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

    testWidgets('zeigt Server-Version für resolution=server', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict(resolution: 'server')));
      expect(find.textContaining('Server-Version'), findsOneWidget);
    });

    testWidgets('zeigt Lokale Version für resolution=local', (tester) async {
      await tester.pumpWidget(_buildDialog(_conflict(resolution: 'local')));
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
