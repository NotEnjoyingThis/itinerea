// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

/// When a placeholder screen becomes a real one: a milestone of phase 1 or a
/// later phase of the project (PRD 15).
class ScaffoldTarget {
  /// A milestone of phase 1, for example M3.
  const ScaffoldTarget.milestone(String this.milestone) : phase = null;

  /// A later phase of the project: 2, 3 or 4.
  const ScaffoldTarget.phase(int this.phase) : milestone = null;

  /// Milestone of phase 1, or null for a later phase.
  final String? milestone;

  /// Phase 2, 3 or 4, or null for a milestone of phase 1.
  final int? phase;

  /// True if the screen belongs to phase 2, 3 or 4: such screens may only be
  /// reached in debug builds (PRD 15.1).
  bool get isLaterPhase => phase != null;

  /// The notice shown to the user, for example "Phase 2 – not available yet".
  String notice(AppLocalizations l10n) => switch (this) {
    ScaffoldTarget(:final int phase) => l10n.scaffoldNoticePhase(phase),
    ScaffoldTarget(:final String milestone) => l10n.scaffoldNoticeMilestone(
      milestone,
    ),
    _ => '',
  };
}

/// Body of every placeholder screen of the scaffolding (PRD 15.1): it says
/// clearly that the screen is not available yet. It is never a finished
/// feature.
class ScaffoldPlaceholder extends StatelessWidget {
  /// Creates the placeholder of the screen [code] named [title].
  const ScaffoldPlaceholder({
    required this.code,
    required this.title,
    required this.target,
    super.key,
  });

  /// Code of the screen in PRD 7.3, for example S03.
  final String code;

  /// Translated name of the screen.
  final String title;

  /// Milestone or phase in which the screen becomes real.
  final ScaffoldTarget target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    target.notice(l10n),
                    key: const Key('scaffoldNotice'),
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.scaffoldExplanation, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text(
                    l10n.scaffoldScreenCode(code),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
