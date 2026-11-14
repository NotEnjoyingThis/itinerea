// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S19 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(Fase 4 F4.3): the import and sharing of itineraries.
class ExploreScreen extends StatelessWidget {
  /// Creates the placeholder of screen S19.
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S19',
    title: AppLocalizations.of(context).screenExplore,
    target: const ScaffoldTarget.phase(4),
  );
}
