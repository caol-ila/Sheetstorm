import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm_app/features/home/home_screen.dart';
import 'package:sheetstorm_app/shared/services/api_client.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  testWidgets('HomeScreen has semantic labels for navigation', (tester) async {
    final mockApiClient = MockApiClient();
    when(() => mockApiClient.ping()).thenAnswer((_) async => 'Pong');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('de'),
            Locale('en'),
          ],
          locale: const Locale('de'),
        ),
      ),
    );

    final handle = tester.ensureSemantics();

    // Verify text is present
    expect(find.text('Sheetstorm'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    // Verify semantic structure (Framework-Spec §4.2: Every widget test needs semantics check)
    final semantics = tester.getSemantics(find.text('Sheetstorm'));
    expect(semantics, isNotNull);
    expect(semantics.label, contains('Sheetstorm'));

    handle.dispose();
  });
}
