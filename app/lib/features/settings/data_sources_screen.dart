// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S21 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M6 F1.15): the mandatory attributions of PRD 5.5.
class DataSourcesScreen extends StatelessWidget {
  /// Creates the placeholder of screen S21.
  const DataSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S21',
    title: AppLocalizations.of(context).screenDataSources,
    target: const ScaffoldTarget.milestone('M6'),
  );
}
