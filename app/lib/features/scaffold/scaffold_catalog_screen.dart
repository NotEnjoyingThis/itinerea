// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import 'scaffold_entries.dart';

/// Whether the developer list of placeholder screens can be opened.
///
/// True only in debug builds: the placeholders of phases 2-4 must never be
/// reachable in published versions (PRD 15.1). Tests override it.
final scaffoldCatalogEnabledProvider = Provider<bool>((ref) => kDebugMode);

/// Developer list of every placeholder screen. Debug builds only.
// TODO(M3 F1.1): the real navigation replaces this list for phase 1 screens;
// the screens of phases 2-4 stay here until their phase starts.
class ScaffoldCatalogScreen extends StatelessWidget {
  /// Creates the developer list.
  const ScaffoldCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scaffoldCatalogTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.scaffoldCatalogIntro),
            ),
            for (final entry in scaffoldEntries)
              ListTile(
                key: Key('scaffold-${entry.code}'),
                leading: Text(entry.code),
                title: Text(entry.title(l10n)),
                subtitle: Text(entry.target.notice(l10n)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: entry.builder)),
              ),
          ],
        ),
      ),
    );
  }
}
