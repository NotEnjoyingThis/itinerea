// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S18 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(Fase 4 F4.2): badges, statistics, points and shop.
class ProfileScreen extends StatelessWidget {
  /// Creates the placeholder of screen S18.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S18',
    title: AppLocalizations.of(context).screenProfile,
    target: const ScaffoldTarget.phase(4),
  );
}
