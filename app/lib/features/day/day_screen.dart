// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S03 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M3 F1.2): the day with its stops, legs, warnings and the quick-add button.
class DayScreen extends StatelessWidget {
  /// Creates the placeholder of screen S03.
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S03',
    title: AppLocalizations.of(context).screenDay,
    target: const ScaffoldTarget.milestone('M3'),
  );
}
