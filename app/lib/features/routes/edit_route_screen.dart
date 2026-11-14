// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S07 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M4 F1.5): the route with draggable points on the map.
class EditRouteScreen extends StatelessWidget {
  /// Creates the placeholder of screen S07.
  const EditRouteScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S07',
    title: AppLocalizations.of(context).screenEditRoute,
    target: const ScaffoldTarget.milestone('M4'),
  );
}
