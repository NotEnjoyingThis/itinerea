// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';

/// Placeholder of screen S08 (PRD 7.3). Scaffolding only: it has no
/// features and says so.
// TODO(M5 F1.10): the budget summary and the list of expenses.
class BudgetScreen extends StatelessWidget {
  /// Creates the placeholder of screen S08.
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldPlaceholder(
    code: 'S08',
    title: AppLocalizations.of(context).screenBudget,
    target: const ScaffoldTarget.milestone('M5'),
  );
}
