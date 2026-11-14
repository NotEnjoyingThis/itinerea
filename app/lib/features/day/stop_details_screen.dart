// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S04 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M3 F1.2): the panel with the details and the plans of a stop.
class StopDetailsScreen extends StatelessWidget {
  /// Creates the placeholder of screen S04.
  const StopDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S04',
    title: AppLocalizations.of(context).screenStopDetails,
    target: const ScaffoldTarget.milestone('M3'),
  );
}
