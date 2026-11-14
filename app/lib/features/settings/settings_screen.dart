// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S20 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M6 F1.15): language, theme, units, sync spaces, backups and providers.
class SettingsScreen extends StatelessWidget {
  /// Creates the placeholder of screen S20.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S20',
    title: AppLocalizations.of(context).screenSettings,
    target: const ScaffoldTarget.milestone('M6'),
  );
}
