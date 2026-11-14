// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S10 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M5 F1.9): the list of bookings and tickets by date.
class BookingsScreen extends StatelessWidget {
  /// Creates the placeholder of screen S10.
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S10',
    title: AppLocalizations.of(context).screenBookings,
    target: const ScaffoldTarget.milestone('M5'),
  );
}
