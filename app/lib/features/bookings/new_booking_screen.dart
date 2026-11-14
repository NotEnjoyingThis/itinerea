// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S12 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M5 F1.9): the form of a booking, by kind.
class NewBookingScreen extends StatelessWidget {
  /// Creates the placeholder of screen S12.
  const NewBookingScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S12',
    title: AppLocalizations.of(context).screenNewBooking,
    target: const ScaffoldTarget.milestone('M5'),
  );
}
