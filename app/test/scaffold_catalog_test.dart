// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/features/scaffold/scaffold_catalog_screen.dart';
import 'package:itinerea/features/scaffold/scaffold_entries.dart';
import 'package:itinerea/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import 'support/test_app.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required bool catalogEnabled,
    Locale locale = const Locale('en'),
  }) => pumpItinerea(
    tester,
    systemLocale: locale,
    scaffoldCatalog: catalogEnabled,
  );

  test('the scaffolding lists the screens that are still placeholders', () {
    // S01 (home) and S20 (settings) are real since milestone M3.
    expect(scaffoldEntries.map((entry) => entry.code), [
      for (var n = 2; n <= 21; n++)
        if (n != 20) 'S${n.toString().padLeft(2, '0')}',
    ]);
  });

  test('screens S13 to S19 belong to phases 2 to 4', () {
    final later = scaffoldEntries
        .where((entry) => entry.target.isLaterPhase)
        .map((entry) => entry.code);
    expect(later, ['S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19']);
  });

  testWidgets('published builds give no way to reach the placeholders', (
    tester,
  ) async {
    await pumpApp(tester, catalogEnabled: false);

    expect(find.byKey(const Key('openScaffoldCatalog')), findsNothing);
  });

  testWidgets('debug builds open the list of placeholders', (tester) async {
    await pumpApp(tester, catalogEnabled: true);

    await tester.tap(find.byKey(const Key('openScaffoldCatalog')));
    await tester.pumpAndSettle();

    expect(find.byType(ScaffoldCatalogScreen), findsOneWidget);
    expect(find.text('Scaffolding (debug)'), findsOneWidget);
  });

  testWidgets('a phase 2 placeholder says it is not available yet', (
    tester,
  ) async {
    await pumpApp(tester, catalogEnabled: true, locale: const Locale('it'));

    await tester.tap(find.byKey(const Key('openScaffoldCatalog')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('scaffold-S13')), 200);
    await tester.ensureVisible(find.byKey(const Key('scaffold-S13')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scaffold-S13')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('scaffoldNotice'))).data,
      'Fase 2 – non ancora disponibile',
    );
    expect(find.text('Partecipanti'), findsOneWidget);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('every placeholder builds and names its target ($locale)', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(locale);
      for (final entry in scaffoldEntries) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: Builder(builder: entry.builder),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(entry.title(l10n)), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('scaffoldNotice'))).data,
          entry.target.notice(l10n),
        );
        expect(tester.takeException(), isNull);
      }
    });
  }
}
