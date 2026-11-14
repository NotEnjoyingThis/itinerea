// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/window_size.dart';
import '../../l10n/generated/app_localizations.dart';

/// Settings (S20), in a minimal form: language, theme and the licences.
///
/// Nothing is stored yet, and the screen says so: language and theme go back
/// to the system settings when the app is closed.
// TODO(M6 F1.15): units, currency, day start, default stop duration, local
// profile, sync spaces, backups, providers; and store every choice.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedLocale = ref.watch(localeProvider);
    final selectedThemeMode = ref.watch(themeModeProvider);
    final margin = WindowSize.of(context).margin;

    Widget heading(String text) => Semantics(
      header: true,
      child: Text(text, style: theme.textTheme.titleMedium),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenSettings)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: margin, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading(l10n.languageSectionTitle),
                  const SizedBox(height: 4),
                  Text(
                    l10n.currentLanguage(
                      Localizations.localeOf(context).languageCode,
                    ),
                    key: const Key('currentLanguage'),
                    style: theme.textTheme.bodySmall,
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
                  heading(l10n.themeSectionTitle),
                  const SizedBox(height: 4),
                  Text(
                    l10n.currentTheme(theme.brightness.name),
                    key: const Key('currentTheme'),
                    style: theme.textTheme.bodySmall,
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
                  const SizedBox(height: 16),
                  // Honest about what is not done yet (PRD T4).
                  Text(
                    l10n.settingsNotSavedNotice,
                    key: const Key('settingsNotSavedNotice'),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  ListTile(
                    key: const Key('openLicenses'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.settingsLicenses),
                    subtitle: Text(l10n.settingsLicensesSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l10n.appTitle,
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
