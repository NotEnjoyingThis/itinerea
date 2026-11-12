// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Theme chosen by the user: follow the system, always light or always dark.
///
/// Kept in memory only: it resets when the app restarts.
// TODO(M6 F1.15): persist the choice with the real settings.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Language chosen by the user, or `null` to follow the system language.
///
/// Kept in memory only: it resets when the app restarts.
// TODO(M6 F1.15): persist the choice with the real settings.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Holds the selected [ThemeMode].
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Switches the app to [mode].
  void select(ThemeMode mode) => state = mode;
}

/// Holds the selected [Locale]; `null` means "same as the system".
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  /// Switches the app to [locale], or back to the system language if `null`.
  void select(Locale? locale) => state = locale;
}
