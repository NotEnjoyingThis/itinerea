// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/settings/app_settings.dart';
import '../../l10n/generated/app_localizations.dart';

/// Temporary screen of milestone M0: shows the current language and theme and
/// lets the user change them. It is not a finished feature.
// TODO(M3 F1.1): replace with the Trips home (S01).
// TODO(M6 F1.15): move language and theme into the Settings screen (S20).
class PlaceholderScreen extends ConsumerWidget {
  /// Creates the temporary screen.
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedLocale = ref.watch(localeProvider);
    final selectedThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.placeholderNotice,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.languageSectionTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.currentLanguage(
                      Localizations.localeOf(context).languageCode,
                    ),
                    key: const Key('currentLanguage'),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: l10n.languageSectionTitle,
                    container: true,
                    child: SegmentedButton<String>(
                      key: const Key('languageSelector'),
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: _systemLanguage,
                          label: Text(l10n.languageSystem),
                        ),
                        ButtonSegment(
                          value: 'it',
                          label: Text(l10n.languageItalian),
                        ),
                        ButtonSegment(
                          value: 'en',
                          label: Text(l10n.languageEnglish),
                        ),
                      ],
                      selected: {
                        selectedLocale?.languageCode ?? _systemLanguage,
                      },
                      onSelectionChanged: (selection) {
                        final code = selection.single;
                        ref
                            .read(localeProvider.notifier)
                            .select(
                              code == _systemLanguage ? null : Locale(code),
                            );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.themeSectionTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.currentTheme(theme.brightness.name),
                    key: const Key('currentTheme'),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: l10n.themeSectionTitle,
                    container: true,
                    child: SegmentedButton<ThemeMode>(
                      key: const Key('themeSelector'),
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l10n.themeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l10n.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l10n.themeDark),
                        ),
                      ],
                      selected: {selectedThemeMode},
                      onSelectionChanged: (selection) {
                        ref
                            .read(themeModeProvider.notifier)
                            .select(selection.single);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Value of the language selector that means "same as the system".
const String _systemLanguage = 'system';
