// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S11 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M5 F1.8): the full-screen view of a ticket.
class TicketScreen extends StatelessWidget {
  /// Creates the placeholder of screen S11.
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S11',
    title: AppLocalizations.of(context).screenTicket,
    target: const ScaffoldTarget.milestone('M5'),
  );
}
