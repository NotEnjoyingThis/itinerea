// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S01 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M3 F1.1): the home with the current, upcoming and past trips.
class TripsHomeScreen extends StatelessWidget {
  /// Creates the placeholder of screen S01.
  const TripsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S01',
    title: AppLocalizations.of(context).screenTripsHome,
    target: const ScaffoldTarget.milestone('M3'),
  );
}
