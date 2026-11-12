// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/app.dart';
import 'package:itinerea/features/settings/placeholder_screen.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Locale systemLocale = const Locale('en'),
    Brightness systemBrightness = Brightness.light,
  }) async {
    tester.platformDispatcher.localesTestValue = [systemLocale];
    tester.platformDispatcher.platformBrightnessTestValue = systemBrightness;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(const ProviderScope(child: ItinereaApp()));
    await tester.pumpAndSettle();
  }

  Brightness currentBrightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(PlaceholderScreen))).brightness;

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  group('language', () {
    testWidgets('starts in the system language (English)', (tester) async {
      await pumpApp(tester);

      expect(textOf(tester, 'currentLanguage'), 'Current language: English');
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('starts in the system language (Italian)', (tester) async {
      await pumpApp(tester, systemLocale: const Locale('it', 'IT'));

      expect(textOf(tester, 'currentLanguage'), 'Lingua attuale: Italiano');
      expect(find.text('Tema'), findsOneWidget);
    });

    testWidgets('falls back to English for an unsupported system language', (
      tester,
    ) async {
      await pumpApp(tester, systemLocale: const Locale('de', 'DE'));

      expect(textOf(tester, 'currentLanguage'), 'Current language: English');
    });

    testWidgets('the selector changes the language and goes back to system', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text('Italiano'));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'currentLanguage'), 'Lingua attuale: Italiano');
      expect(find.text('Tema'), findsOneWidget);

      await tester.tap(find.text('Sistema'));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'currentLanguage'), 'Current language: English');
    });
  });

  group('theme', () {
    testWidgets('follows the system brightness by default', (tester) async {
      await pumpApp(tester, systemBrightness: Brightness.dark);

      expect(currentBrightness(tester), Brightness.dark);
      expect(textOf(tester, 'currentTheme'), 'Current theme: dark');
    });

    testWidgets('the selector switches between light, dark and automatic', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(currentBrightness(tester), Brightness.light);
      expect(textOf(tester, 'currentTheme'), 'Current theme: light');

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.dark);
      expect(textOf(tester, 'currentTheme'), 'Current theme: dark');

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.light);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.dark);
    });
  });

  testWidgets('says clearly that the screen is temporary', (tester) async {
    await pumpApp(tester);

    expect(find.textContaining('under development'), findsOneWidget);
  });

  testWidgets('fits a small phone with large system text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);

    await pumpApp(tester, systemLocale: const Locale('it'));

    expect(tester.takeException(), isNull);
  });
}
