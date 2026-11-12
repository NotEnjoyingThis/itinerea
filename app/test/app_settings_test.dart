// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/settings/app_settings.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('themeModeProvider', () {
    test('follows the system by default', () {
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('select() changes the theme mode and can go back to system', () {
      final notifier = container.read(themeModeProvider.notifier);

      notifier.select(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      notifier.select(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      notifier.select(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('localeProvider', () {
    test('follows the system language by default', () {
      expect(container.read(localeProvider), isNull);
    });

    test('select() changes the language and null goes back to system', () {
      final notifier = container.read(localeProvider.notifier);

      notifier.select(const Locale('it'));
      expect(container.read(localeProvider), const Locale('it'));

      notifier.select(null);
      expect(container.read(localeProvider), isNull);
    });
  });
}
