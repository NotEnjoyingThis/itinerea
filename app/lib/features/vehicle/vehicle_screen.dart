// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S14 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(Fase 2 F2.5): the choice of the vehicle, its range and the stop planning.
class VehicleScreen extends StatelessWidget {
  /// Creates the placeholder of screen S14.
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S14',
    title: AppLocalizations.of(context).screenVehicle,
    target: const ScaffoldTarget.phase(2),
  );
}
