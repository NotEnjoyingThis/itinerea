// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/ids.dart';
import '../../core/theme/window_size.dart';
import '../../l10n/generated/app_localizations.dart';
import 'trip_dates_editor.dart';
import 'trip_list.dart';
import 'trip_plan.dart';
import 'trip_providers.dart';

/// Changes the dates of a trip, or its number of days (F1.1).
///
/// Days are added and removed at the end. If days with stops would be
/// removed, the app asks first whether to move the stops or delete them.
class EditDatesScreen extends ConsumerStatefulWidget {
  /// Creates the screen for the trip [tripId].
  const EditDatesScreen({required this.tripId, super.key});

  /// Trip whose dates change.
  final EntityId tripId;

  @override
  ConsumerState<EditDatesScreen> createState() => _EditDatesScreenState();
}

class _EditDatesScreenState extends ConsumerState<EditDatesScreen> {
  TripDates? _dates;
  bool _tried = false;
  bool _saving = false;

  Future<void> _save(TripDates dates) async {
    setState(() => _tried = true);
    if (dates.isIncomplete) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final trips = await ref.read(tripRepositoryProvider.future);
      final plan = await trips.planDateChange(
        widget.tripId,
        startDate: dates.startDate,
        dayCount: dates.length,
      );
      RemovedStopsChoice? choice;
      if (plan.needsDecision) {
        if (!mounted) return;
        choice = await showDialog<RemovedStopsChoice>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.datesChangeStopsTitle),
            content: Text(l10n.datesChangeStopsBody(plan.stopsInRemovedDays)),
            actionsOverflowAlignment: OverflowBarAlignment.end,
            actions: [
              TextButton(
                key: const Key('datesCancel'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionCancel),
              ),
              TextButton(
                key: const Key('datesDeleteStops'),
                onPressed: () =>
                    Navigator.of(context).pop(RemovedStopsChoice.delete),
                child: Text(l10n.datesChangeDelete),
              ),
              FilledButton(
                key: const Key('datesMoveStops'),
                onPressed: () =>
                    Navigator.of(context).pop(RemovedStopsChoice.moveToLastDay),
                child: Text(l10n.datesChangeMove),
              ),
            ],
          ),
        );
        // Closed without choosing: nothing changes.
        if (choice == null) {
          if (mounted) setState(() => _saving = false);
          return;
        }
      }
      await trips.changeDates(
        widget.tripId,
        startDate: dates.startDate,
        dayCount: dates.length,
        removedStops: choice,
      );
      if (!mounted) return;
      refreshTrip(ref, widget.tripId);
      navigator.pop();
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.changeError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trip = ref.watch(tripProvider(widget.tripId)).value;
    final margin = WindowSize.of(context).margin;
    final dates =
        _dates ??
        (trip == null
            ? null
            : TripDates.of(start: trip.startDate, dayCount: trip.dayCount));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripEditDates)),
      body: SafeArea(
        child: dates == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(margin),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: TripDatesEditor(
                            value: dates,
                            showProblems: _tried,
                            onChanged: (value) =>
                                setState(() => _dates = value),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: margin,
                      vertical: 12,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        key: const Key('datesSave'),
                        onPressed: _saving ? null : () => _save(dates),
                        child: Text(l10n.actionSave),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
