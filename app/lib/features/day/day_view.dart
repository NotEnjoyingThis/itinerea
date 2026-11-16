// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/ids.dart';
import '../../core/models/stop.dart';
import '../../core/models/trip.dart';
import '../../core/net/http_transport.dart';
import '../../core/theme/app_theme.dart';
import '../../core/time/timezones.dart';
import '../../l10n/generated/app_localizations.dart';
import '../trips/timezone_picker_screen.dart';
import '../trips/trip_list.dart';
import '../trips/trip_plan.dart';
import '../trips/trip_providers.dart';
import '../trips/trip_repository.dart';
import 'add_stop_sheet.dart';
import 'place_details_actions.dart';
import 'stop_detail_panel.dart';
import 'stop_repository.dart';

/// Name of a day: "Day 3" or "Day 3 · Fri, Mar 14".
String dayTitle(BuildContext context, DaySummary day) {
  final l10n = AppLocalizations.of(context);
  final date = day.date;
  if (date == null) return l10n.dayNumber(day.index);
  final locale = Localizations.localeOf(context).toString();
  return l10n.dayNumberWithDate(
    day.index,
    DateFormat.MMMEd(locale).format(date.toDateTime()),
  );
}

/// The day (S03): its heading and its stops in order. Everything in a trip
/// starts from here and comes back here (PRD 7.1).
// TODO(M3 F1.3): times and warnings. TODO(M4 F1.4): legs between stops.
// TODO(M5 F1.11): weather in the heading.
class DayView extends ConsumerStatefulWidget {
  /// Creates the view of [day].
  const DayView({
    required this.tripId,
    required this.day,
    required this.days,
    required this.segments,
    required this.selectedSlot,
    required this.onOpenStop,
    super.key,
  });

  /// Trip the day belongs to.
  final EntityId tripId;

  /// Day shown.
  final DaySummary day;

  /// Every day of the trip, to move a stop to another one.
  final List<DaySummary> days;

  /// Segments of the trip, to know whether this is a roadtrip day.
  final List<SegmentInfo> segments;

  /// Position whose details are open, highlighted in the list.
  final EntityId? selectedSlot;

  /// Called when a stop is tapped.
  final ValueChanged<DayStop> onOpenStop;

  @override
  ConsumerState<DayView> createState() => DayViewState();
}

/// State of [DayView]: also offers the actions on a stop to the detail
/// panel, which lives outside the list.
class DayViewState extends ConsumerState<DayView> {
  // Order shown while a reorder is being saved, so that the row does not
  // jump back for a moment.
  List<DayStop>? _reordered;

  EntityId get _dayId => widget.day.id;

  Future<StopRepository> get _stops => ref.read(stopRepositoryProvider.future);

  @override
  void didUpdateWidget(DayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another day is shown: an order kept for the previous one means nothing.
    if (oldWidget.day.id != widget.day.id) _reordered = null;
  }

  Future<void> _run(Future<void> Function() change) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await change();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.changeError)));
    }
  }

  /// Opens the "add stop" sheet (flow FL1).
  Future<void> addStop() async {
    // The search prefers places near the last located stop of the day.
    final near = [
      for (final stop
          in ref.read(dayStopsProvider(_dayId)).value ?? const <DayStop>[])
        ?stop.place?.coordinates,
    ].lastOrNull;
    final choice = await showModalBottomSheet<NewStop>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddStopSheet(near: near),
    );
    if (choice == null || !mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final language = Localizations.localeOf(context).languageCode;
    await _run(() async {
      final slotId = await (await _stops).addStop(
        tripId: widget.tripId,
        dayId: _dayId,
        name: choice.name,
        place: choice.place,
      );
      ref.invalidate(dayStopsProvider(_dayId));
      if (choice.place?.osmId case final String osmId) {
        // Opening hours and contacts arrive a moment later. The stop is
        // complete without them, so a failure says nothing here: the
        // details of the stop offer to try again (F1.2).
        unawaited(
          fillPlaceDetails(
            container,
            slotId: slotId,
            osmId: osmId,
            language: language,
          ).catchError((Object _) => false, test: (e) => e is ServiceFailure),
        );
      }
    });
  }

  Future<void> _reorder(List<DayStop> stops, int from, int to) async {
    final index = to;
    if (index == from) return;
    final moved = stops[from];
    setState(
      () => _reordered = [...stops]
        ..removeAt(from)
        ..insert(index, moved),
    );
    await _run(
      () async => (await _stops).moveStop(
        moved.slotId,
        toDayId: _dayId,
        toIndex: index,
      ),
    );
    // Wait for the saved order before dropping the temporary one.
    ref.invalidate(dayStopsProvider(_dayId));
    await ref.read(dayStopsProvider(_dayId).future);
    if (mounted) setState(() => _reordered = null);
  }

  /// Asks which day to move [stop] to, then moves it to the end of that day
  /// (flow FL9).
  Future<void> moveToAnotherDay(DayStop stop) async {
    final target = await showModalBottomSheet<DaySummary>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                AppLocalizations.of(context).stopMoveToDay,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final day in widget.days)
              if (day.id != _dayId)
                ListTile(
                  key: Key('moveToDay-${day.index}'),
                  leading: const Icon(Icons.event_rounded),
                  title: Text(dayTitle(context, day)),
                  onTap: () => Navigator.of(context).pop(day),
                ),
          ],
        ),
      ),
    );
    if (target == null) return;
    await _run(() async {
      // A position past the end means "at the end".
      await (await _stops).moveStop(
        stop.slotId,
        toDayId: target.id,
        toIndex: 1 << 20,
      );
      ref
        ..invalidate(dayStopsProvider(_dayId))
        ..invalidate(dayStopsProvider(target.id));
    });
  }

  /// Deletes [stop] and offers to bring it back (PRD 9.5).
  Future<void> deleteStop(DayStop stop) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final dayId = _dayId;
    await _run(() async {
      await (await _stops).deleteStop(stop.slotId);
      ref.invalidate(dayStopsProvider(dayId));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.stopDeleted(stop.name)),
            action: SnackBarAction(
              label: l10n.actionRestore,
              onPressed: () async {
                final container = ProviderScope.containerOf(
                  messenger.context,
                  listen: false,
                );
                final stops = await container.read(
                  stopRepositoryProvider.future,
                );
                await stops.restoreStop(stop.slotId);
                container.invalidate(dayStopsProvider(dayId));
              },
            ),
          ),
        );
    });
  }

  Future<void> _stopMenu(DayStop stop) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<VoidCallback>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                stop.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (widget.days.length > 1)
              ListTile(
                key: const Key('menuMoveStop'),
                leading: const Icon(Icons.drive_file_move_outline),
                title: Text(l10n.stopMoveToDay),
                onTap: () =>
                    Navigator.of(context).pop(() => moveToAnotherDay(stop)),
              ),
            ListTile(
              key: const Key('menuDeleteStop'),
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n.actionDelete),
              onTap: () => Navigator.of(context).pop(() => deleteStop(stop)),
            ),
          ],
        ),
      ),
    );
    action?.call();
  }

  Future<void> _changeKind(SegmentType type) async {
    final l10n = AppLocalizations.of(context);
    VehicleKind? vehicle;
    if (type == SegmentType.roadtrip) {
      vehicle = await showModalBottomSheet<VehicleKind>(
        context: context,
        useSafeArea: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  l10n.vehicleQuestion,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                key: const Key('roadtripByCar'),
                leading: const Icon(Icons.directions_car_rounded),
                title: Text(l10n.vehicleCar),
                onTap: () => Navigator.of(context).pop(VehicleKind.car),
              ),
              ListTile(
                key: const Key('roadtripByMotorbike'),
                leading: const Icon(Icons.two_wheeler_rounded),
                title: Text(l10n.vehicleMotorbike),
                onTap: () => Navigator.of(context).pop(VehicleKind.motorbike),
              ),
            ],
          ),
        ),
      );
      if (vehicle == null) return;
    }
    await _run(() async {
      final trips = await ref.read(tripRepositoryProvider.future);
      await trips.changeTypeFromDay(
        widget.tripId,
        dayIndex: widget.day.index,
        type: type,
        vehicleKind: vehicle,
      );
      ref.invalidate(tripSegmentsProvider(widget.tripId));
    });
  }

  Future<void> _changeTimezone() async {
    final picked = await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => TimezonePickerScreen(selected: widget.day.timezone),
      ),
    );
    if (picked == null) return;
    await _run(() async {
      final trips = await ref.read(tripRepositoryProvider.future);
      await trips.setDayTimezone(_dayId, picked);
      ref.invalidate(tripDaysProvider(widget.tripId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stops = ref.watch(dayStopsProvider(_dayId));
    final segment = Segments.ofDay(widget.segments, widget.day.index);
    final isRoadtrip = segment.type == SegmentType.roadtrip;
    final deviceTimezone = ref.watch(deviceTimezoneProvider).value;
    final shown = _reordered ?? stops.value ?? const <DayStop>[];

    // Heading of the day. The rows under the title hold what is known about
    // the day: the kind of trip, the time zone and, from M5, the weather and
    // the lodging of the night ("to be decided" when there is none, never a
    // warning). It scrolls with the stops: on a small phone with large text
    // a fixed heading would take half of the screen.
    final heading = Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    dayTitle(context, widget.day),
                    key: const Key('dayTitle'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (isRoadtrip ||
                    (deviceTimezone != null &&
                        widget.day.timezone != deviceTimezone)) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (isRoadtrip)
                        _Fact(
                          key: const Key('dayRoadtrip'),
                          icon: segment.vehicleKind == VehicleKind.motorbike
                              ? Icons.two_wheeler_rounded
                              : Icons.directions_car_rounded,
                          text: segment.vehicleKind == VehicleKind.motorbike
                              ? l10n.dayRoadtripMotorbike
                              : l10n.dayRoadtripCar,
                        ),
                      if (deviceTimezone != null &&
                          widget.day.timezone != deviceTimezone)
                        _Fact(
                          key: const Key('dayTimezoneNote'),
                          icon: Icons.schedule_rounded,
                          text: l10n.dayTimezoneNote(
                            widget.day.timezone.replaceAll('_', ' '),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<VoidCallback>(
            key: const Key('dayMenu'),
            tooltip: l10n.dayMenu,
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                key: const Key('dayChangeKind'),
                value: () => _changeKind(
                  isRoadtrip ? SegmentType.itinerary : SegmentType.roadtrip,
                ),
                child: Text(
                  isRoadtrip
                      ? l10n.dayFromHereItinerary
                      : l10n.dayFromHereRoadtrip,
                ),
              ),
              PopupMenuItem(
                key: const Key('dayChangeTimezone'),
                value: _changeTimezone,
                child: Text(l10n.dayTimezone),
              ),
            ],
          ),
        ],
      ),
    );

    // What fills the rest of the screen when there is no list to show.
    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: false, child: child);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [heading, const Divider()],
          ),
        ),
        switch (stops) {
          AsyncError() => fill(Center(child: Text(l10n.dataOpenError))),
          AsyncLoading() when shown.isEmpty => fill(
            const Center(child: CircularProgressIndicator()),
          ),
          _ when shown.isEmpty => fill(_EmptyDay(onAdd: addStop)),
          _ => SliverPadding(
            // Room for the "+" button under the last stop.
            padding: const EdgeInsets.only(top: 4, bottom: 88),
            sliver: SliverReorderableList(
              itemCount: shown.length,
              // The target index already takes the removed row into account.
              onReorderItem: (from, to) => _reorder(shown, from, to),
              proxyDecorator: _lifted,
              itemBuilder: (context, index) {
                final stop = shown[index];
                return _StopRow(
                  key: ValueKey(stop.slotId.value),
                  stop: stop,
                  index: index,
                  selected: stop.slotId == widget.selectedSlot,
                  onTap: () => widget.onOpenStop(stop),
                  onLongPress: () => _stopMenu(stop),
                );
              },
            ),
          ),
        },
      ],
    );
  }

  /// A row being dragged floats above the others: the one place where a
  /// shadow is used in a list (docs/DESIGN.md, section 4).
  static Widget _lifted(Widget child, int index, Animation<double> animation) =>
      AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Material(
          elevation: 6 * Curves.easeInOut.transform(animation.value),
          child: child,
        ),
        child: child,
      );
}

/// One fact about the day in its heading: an icon and a few words.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

/// A day without stops: what is missing and how to add it (PRD 7.7).
class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // The day scrolls as a whole: no scroll view of its own here.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(l10n.stopsEmptyTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.stopsEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('addFirstStop'),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.stopAdd),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stop in the day: one row, not a card (docs/DESIGN.md).
class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final DayStop stop;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = ItinereaColors.of(context);
    final done = stop.status != StopStatus.planned;
    return Material(
      color: selected
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
      child: ListTile(
        key: Key('stop-${stop.slotId.value}'),
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        leading: switch (stop.status) {
          StopStatus.visited => Icon(
            Icons.check_circle_rounded,
            color: colors.done,
            semanticLabel: l10n.stopStatusVisited,
          ),
          StopStatus.skipped => Icon(
            Icons.remove_circle_outline_rounded,
            semanticLabel: l10n.stopStatusSkipped,
          ),
          StopStatus.planned => const Icon(Icons.circle_outlined),
        },
        title: Text(
          stop.name,
          style: done
              ? theme.textTheme.titleSmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: Text(formatDuration(l10n, stop.durationMin)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stop.planCount > 1)
              Semantics(
                label: l10n.stopAlternatives(stop.planCount - 1),
                child: Chip(
                  avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text('+${stop.planCount - 1}'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ReorderableDragStartListener(
              index: index,
              child: Tooltip(
                message: l10n.stopDragHandle,
                child: SizedBox(
                  key: Key('drag-${stop.slotId.value}'),
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    semanticLabel: l10n.stopDragHandle,
                  ),
                ),
              ),
            ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
