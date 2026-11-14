// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S09 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M5 F1.10): the panel that records an expense.
class NewExpenseScreen extends StatelessWidget {
  /// Creates the placeholder of screen S09.
  const NewExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S09',
    title: AppLocalizations.of(context).screenNewExpense,
    target: const ScaffoldTarget.milestone('M5'),
  );
}
