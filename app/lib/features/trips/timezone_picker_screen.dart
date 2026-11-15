// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/time/timezones.dart';
import '../../l10n/generated/app_localizations.dart';

/// Lets the user choose a time zone by hand, searching by city or region.
/// Closes with the name of the zone chosen, or with nothing.
class TimezonePickerScreen extends ConsumerStatefulWidget {
  /// Creates the list, with [selected] marked.
  const TimezonePickerScreen({required this.selected, super.key});

  /// Zone in use now.
  final String selected;

  @override
  ConsumerState<TimezonePickerScreen> createState() =>
      _TimezonePickerScreenState();
}

class _TimezonePickerScreenState extends ConsumerState<TimezonePickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // "new york" finds America/New_York.
    final words = _query.toLowerCase().trim().split(RegExp(r'[\s_/]+'));
    final zones = [
      for (final zone in ref.watch(timezoneNamesProvider))
        if (words.every(zone.toLowerCase().contains)) zone,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.timezoneLabel)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const Key('timezoneSearch'),
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.timezoneSearch,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: zones.isEmpty
                  ? Center(child: Text(l10n.timezoneNone))
                  : ListView.builder(
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        return ListTile(
                          key: Key('timezone-$zone'),
                          title: Text(zone.replaceAll('_', ' ')),
                          selected: zone == widget.selected,
                          trailing: zone == widget.selected
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.of(context).pop(zone),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
