// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/theme/app_theme.dart';
import 'package:itinerea/core/theme/font_licenses.dart';
import 'package:material_ui/material_ui.dart';

/// Contrast ratio of two colours (WCAG 2.1).
double _contrast(Color a, Color b) {
  double luminance(Color color) {
    double channel(double value) => value <= 0.03928
        ? value / 12.92
        : pow((value + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  final la = luminance(a);
  final lb = luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    group('$name theme (docs/DESIGN.md)', () {
      final scheme = theme.colorScheme;
      final extra = theme.extension<ItinereaColors>()!;

      test('texts reach a contrast of 4.5 on their background', () {
        final pairs = <String, (Color, Color)>{
          'text on background': (
            scheme.onSurface,
            theme.scaffoldBackgroundColor,
          ),
          'text on surface': (scheme.onSurface, scheme.surface),
          'secondary text on surface': (
            scheme.onSurfaceVariant,
            scheme.surface,
          ),
          'secondary text on background': (
            scheme.onSurfaceVariant,
            theme.scaffoldBackgroundColor,
          ),
          'accent on surface': (scheme.primary, scheme.surface),
          'text on accent': (scheme.onPrimary, scheme.primary),
          'text on soft accent': (
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
          ),
          'error on surface': (scheme.error, scheme.surface),
          'warning on surface': (extra.warning, scheme.surface),
          'text on warning band': (
            extra.onWarningContainer,
            extra.warningContainer,
          ),
          'offline on surface': (extra.offline, scheme.surface),
          'done on surface': (extra.done, scheme.surface),
        };
        for (final MapEntry(key: pair, value: (foreground, background))
            in pairs.entries) {
          expect(
            _contrast(foreground, background),
            greaterThanOrEqualTo(4.5),
            reason: pair,
          );
        }
      });

      test('borders of controls reach a contrast of 3', () {
        expect(
          _contrast(scheme.outline, scheme.surface),
          greaterThanOrEqualTo(3),
        );
      });

      test('titles use Manrope and text uses Inter, as variable fonts', () {
        final text = theme.textTheme;

        for (final title in [
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
        ]) {
          expect(title!.fontFamily, AppTheme.titleFont);
        }
        for (final body in [
          text.titleSmall,
          text.bodyLarge,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
        ]) {
          expect(body!.fontFamily, AppTheme.textFont);
        }
        // The weight is an axis of the font file: it must be set explicitly.
        expect(
          text.titleLarge!.fontVariations,
          contains(const FontVariation('wght', 700)),
        );
        expect(
          text.bodyLarge!.fontVariations,
          contains(const FontVariation('wght', 400)),
        );
      });

      test('follows the type scale', () {
        final text = theme.textTheme;

        expect(text.headlineSmall!.fontSize, 24);
        expect(text.titleLarge!.fontSize, 20);
        expect(text.titleMedium!.fontSize, 17);
        expect(text.titleSmall!.fontSize, 16);
        expect(text.bodyLarge!.fontSize, 15);
        expect(text.bodySmall!.fontSize, 13);
        expect(text.labelMedium!.fontSize, 12);
      });
    });
  }

  group('bundled fonts', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    test('are files of the app, declared in the pubspec', () {
      for (final family in [AppTheme.textFont, AppTheme.titleFont]) {
        expect(pubspec, contains('family: $family'));
        expect(File('assets/fonts/$family-Variable.ttf').existsSync(), isTrue);
      }
    });

    test('are never fetched with the google_fonts package', () {
      expect(pubspec.contains('google_fonts'), isFalse);
    });

    test('each comes with the text of its licence, shipped in the app', () {
      expect(bundledFontLicenses.keys, {AppTheme.textFont, AppTheme.titleFont});
      for (final asset in bundledFontLicenses.values) {
        final text = File(asset).readAsStringSync();
        expect(text, contains('SIL Open Font License, Version 1.1'));
        expect(pubspec, contains('- $asset'));
      }
    });
  });
}
