// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/ids.dart';
import '../../core/theme/window_size.dart';
import '../../l10n/generated/app_localizations.dart';
import '../day/day_view.dart';
import '../day/stop_detail_panel.dart';
import '../day/stop_repository.dart';
import 'edit_dates_screen.dart';
import 'timezone_picker_screen.dart';
import 'trip_list.dart';
import 'trip_providers.dart';
import 'trip_repository.dart';

/// A trip: its days and, for the day selected, its stops (PRD 7.2).
///
/// On a phone: the days as a row of chips above the day. On wider screens:
/// the days in a column on the left, the day beside it and, when a stop is
/// open, its details on the right (docs/DESIGN.md, section 7).
// TODO(M4 F1.7): the map beside the day, and the tabs of the trip (map,
// budget, bookings) as they come to exist.
class TripScreen extends ConsumerStatefulWidget {
  /// Creates the screen of the trip [tripId].
  const TripScreen({required this.tripId, super.key});

  /// Trip shown.
  final EntityId tripId;

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  /// Width of the column of the days, on desktops.
  static const double _railWidth = 220;

  /// Width of the column of the day, on tablets and desktops.
  static const double _dayColumnWidth = 400;

  final _dayView = GlobalKey<DayViewState>();
  int _dayIndex = 1;
  // Stop whose details are open beside the day, on wide screens.
  EntityId? _openSlot;

  EntityId get _tripId => widget.tripId;

  void _selectDay(int index) => setState(() {
    _dayIndex = index;
    _openSlot = null;
  });

  Future<void> _openStop(DayStop stop, DaySummary day, String currency) async {
    if (WindowSize.of(context) != WindowSize.compact) {
      return setState(() => _openSlot = stop.slotId);
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        // Stay above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
          child: StopDetailPanel(
            tripId: _tripId,
            dayId: day.id,
            slotId: stop.slotId,
            currency: currency,
            onClose: () => Navigator.of(sheetContext).pop(),
            onMove: (stop) {
              Navigator.of(sheetContext).pop();
              unawaited(_dayView.currentState?.moveToAnotherDay(stop));
            },
            onDelete: (stop) {
              Navigator.of(sheetContext).pop();
              unawaited(_dayView.currentState?.deleteStop(stop));
            },
          ),
        ),
      ),
    );
  }

  Future<void> _changeTripTimezone(TripSummary trip) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => TimezonePickerScreen(selected: trip.timezone ?? 'UTC'),
      ),
    );
    if (picked == null) return;
    try {
      final trips = await ref.read(tripRepositoryProvider.future);
      await trips.setTripTimezone(_tripId, picked);
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.changeError)));
    }
    if (mounted) refreshTrip(ref, _tripId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final trip = ref.watch(tripProvider(_tripId));
    final days = ref.watch(tripDaysProvider(_tripId)).value;
    final segments = ref.watch(tripSegmentsProvider(_tripId)).value;
    final size = WindowSize.of(context);

    if (trip case AsyncData(value: null)) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.tripNotFound)),
      );
    }
    final summary = trip.value;
    if (summary == null ||
        days == null ||
        days.isEmpty ||
        segments == null ||
        segments.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: trip.hasError
              ? Text(l10n.dataOpenError)
              : const CircularProgressIndicator(),
        ),
      );
    }
    // The selected day may be gone after the trip got shorter.
    final day = days[(_dayIndex.clamp(1, days.length)) - 1];
    final currency = summary.currency;

    final dayView = DayView(
      key: _dayView,
      tripId: _tripId,
      day: day,
      days: days,
      segments: segments,
      selectedSlot: size == WindowSize.compact ? null : _openSlot,
      onOpenStop: (stop) => _openStop(stop, day, currency),
    );
    final daySelector = _DayChips(
      days: days,
      selected: day.index,
      onSelected: _selectDay,
    );
    // Details of a stop beside the day, on wide screens. They take the
    // whole height, where the map will be from M4 (docs/DESIGN.md, 6).
    final details = _openSlot == null
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 440,
              height: double.infinity,
              child: Material(
                color: theme.colorScheme.surface,
                shape: Border(
                  right: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: StopDetailPanel(
                  tripId: _tripId,
                  dayId: day.id,
                  slotId: _openSlot!,
                  currency: currency,
                  onClose: () => setState(() => _openSlot = null),
                  onMove: (stop) =>
                      _dayView.currentState?.moveToAnotherDay(stop),
                  onDelete: (stop) {
                    setState(() => _openSlot = null);
                    unawaited(_dayView.currentState?.deleteStop(stop));
                  },
                ),
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.name),
        actions: [
          PopupMenuButton<VoidCallback>(
            key: const Key('tripMenu'),
            tooltip: l10n.tripMenu,
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                key: const Key('tripEditDates'),
                value: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditDatesScreen(tripId: _tripId),
                  ),
                ),
                child: Text(l10n.tripEditDates),
              ),
              PopupMenuItem(
                key: const Key('tripChangeTimezone'),
                value: () => _changeTripTimezone(summary),
                child: Text(l10n.tripTimezoneOfTrip),
              ),
            ],
          ),
          SizedBox(width: size.margin - 8),
        ],
      ),
      body: SafeArea(
        child: switch (size) {
          // Phone: the days as chips above the day.
          WindowSize.compact => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              daySelector,
              const Divider(),
              Expanded(child: dayView),
            ],
          ),
          // Tablet or narrow window: the day with its chips, and beside it
          // the details of a stop (docs/DESIGN.md, section 7).
          WindowSize.medium => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _dayColumnWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    daySelector,
                    const Divider(),
                    Expanded(child: dayView),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: details),
            ],
          ),
          // Desktop: days, day and details side by side.
          WindowSize.expanded => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _railWidth,
                child: _DayRail(
                  days: days,
                  selected: day.index,
                  onSelected: _selectDay,
                ),
              ),
              const VerticalDivider(width: 1),
              SizedBox(width: _dayColumnWidth, child: dayView),
              const VerticalDivider(width: 1),
              Expanded(child: details),
            ],
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addStop'),
        tooltip: l10n.stopAdd,
        onPressed: () => _dayView.currentState?.addStop(),
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: switch (size) {
        WindowSize.compact => FloatingActionButtonLocation.endFloat,
        // At the bottom of the day column, not at the far right.
        WindowSize.medium => const _DayColumnFab(
          dayColumnRight: _dayColumnWidth,
        ),
        WindowSize.expanded => const _DayColumnFab(
          dayColumnRight: _railWidth + 1 + _dayColumnWidth,
        ),
      },
    );
  }
}

/// On wide screens the "+" sits at the bottom of the day column, not at the
/// far right of the window.
class _DayColumnFab extends FloatingActionButtonLocation {
  const _DayColumnFab({required this.dayColumnRight});

  /// Distance of the right edge of the day column from the left of the
  /// window.
  final double dayColumnRight;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final fab = geometry.floatingActionButtonSize;
    final right = dayColumnRight.clamp(0, geometry.scaffoldSize.width);
    return Offset(
      right - fab.width - 16,
      geometry.contentBottom - fab.height - 16,
    );
  }
}

/// The days of the trip as a row of chips, on phones.
class _DayChips extends StatelessWidget {
  const _DayChips({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<DaySummary> days;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            for (final day in days)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  key: Key('day-${day.index}'),
                  label: Text(l10n.dayNumber(day.index)),
                  selected: day.index == selected,
                  showCheckmark: false,
                  onSelected: (_) => onSelected(day.index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The days of the trip as a column, on wide screens.
class _DayRail extends StatelessWidget {
  const _DayRail({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<DaySummary> days;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.tripDays, style: theme.textTheme.labelSmall),
          ),
          for (final day in days)
            ListTile(
              key: Key('day-${day.index}'),
              dense: true,
              selected: day.index == selected,
              selectedTileColor: theme.colorScheme.primaryContainer,
              selectedColor: theme.colorScheme.onPrimaryContainer,
              title: Text(dayTitle(context, day)),
              onTap: () => onSelected(day.index),
            ),
        ],
      ),
    );
  }
}
