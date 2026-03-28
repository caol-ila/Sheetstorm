import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/core/constants/app_constants.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

void main() {
  group('AppConstants', () {
    test('App-Name ist Sheetstorm', () {
      expect(AppConstants.appName, 'Sheetstorm');
    });

    test('Onboarding hat maximal 5 Schritte', () {
      expect(AppConstants.onboardingMaxSteps, lessThanOrEqualTo(5));
    });

    test('Kontextmenü hat maximal 5 Einträge', () {
      expect(AppConstants.contextMenuMaxItems, lessThanOrEqualTo(5));
    });

    test('Undo-Toast dauert 5 Sekunden', () {
      expect(AppConstants.undoToastDurationSeconds, 5);
    });
  });

  group('AppSpacing — Touch-Targets (ux-design.md § 1.2)', () {
    test('Minimales Touch-Target ist 44px', () {
      expect(AppSpacing.touchTargetMin, greaterThanOrEqualTo(44.0));
    });

    test('Spielmodus Touch-Target ist 64px', () {
      expect(AppSpacing.touchTargetPlay, greaterThanOrEqualTo(64.0));
    });
  });

  group('AppColors — Design Tokens', () {
    test('Primary-Farbe stimmt mit ux-design.md überein', () {
      expect(AppColors.primary.value, equals(const Color(0xFF1A56DB).value));
    });

    test('Dark-Background ist schwarz (Spielmodus)', () {
      expect(AppColors.darkBackground.value, equals(const Color(0xFF000000).value));
    });
  });
}
