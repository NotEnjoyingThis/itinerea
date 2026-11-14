// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S05 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M4 F1.4): the panel with the means, route options and alternatives of a leg.
class LegDetailsScreen extends StatelessWidget {
  /// Creates the placeholder of screen S05.
  const LegDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S05',
    title: AppLocalizations.of(context).screenLegDetails,
    target: const ScaffoldTarget.milestone('M4'),
  );
}
