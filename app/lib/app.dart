// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/trips/trips_home_screen.dart';
import 'l10n/generated/app_localizations.dart';

/// Root widget: wires language, theme and the first screen.
class ItinereaApp extends ConsumerWidget {
  /// Creates the root widget.
  const ItinereaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      // Not AppLocalizations.localizationsDelegates: that list carries the
      // delegates of flutter_localizations, which do not serve the widgets of
      // the material_ui package. Its own delegates cover Material, Cupertino
      // and Widgets.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      themeMode: ref.watch(themeModeProvider),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const TripsHomeScreen(),
    );
  }
}
