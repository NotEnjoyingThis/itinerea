// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S13 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(Fase 2 F2.1): the sync space of the trip, invitations and roles.
class ParticipantsScreen extends StatelessWidget {
  /// Creates the placeholder of screen S13.
  const ParticipantsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S13',
    title: AppLocalizations.of(context).screenParticipants,
    target: const ScaffoldTarget.phase(2),
  );
}
