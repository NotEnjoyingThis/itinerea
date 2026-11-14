// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S06 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M4 F1.7): the map with stops, routes and layers.
class MapScreen extends StatelessWidget {
  /// Creates the placeholder of screen S06.
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S06',
    title: AppLocalizations.of(context).screenMap,
    target: const ScaffoldTarget.milestone('M4'),
  );
}
