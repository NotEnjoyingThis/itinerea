// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S02 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M3 F1.1): the three-step creation of a trip.
class NewTripScreen extends StatelessWidget {
  /// Creates the placeholder of screen S02.
  const NewTripScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S02',
    title: AppLocalizations.of(context).screenNewTrip,
    target: const ScaffoldTarget.milestone('M3'),
  );
}
