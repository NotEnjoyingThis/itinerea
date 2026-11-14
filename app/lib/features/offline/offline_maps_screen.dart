// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S15 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(Fase 2 F2.8): the map and place packs of a trip.
class OfflineMapsScreen extends StatelessWidget {
  /// Creates the placeholder of screen S15.
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S15',
    title: AppLocalizations.of(context).screenOfflineMaps,
    target: const ScaffoldTarget.phase(2),
  );
}
