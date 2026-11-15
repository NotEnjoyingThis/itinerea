// SPDX-License-Identifier: GPL-3.0-or-later

// Pure rules of F1.1: what a new trip needs, how its days follow from dates
// or from a number of days, and how a trip is split into segments.

import '../../core/models/ids.dart';
import '../../core/models/time.dart';
import '../../core/models/trip.dart';

/// What is wrong with the data of a new trip.
enum TripDraftProblem {
  /// The trip has no name.
  missingName,

  /// The trip has less than one day.
  noDays,

  /// The trip has more days than the app plans for.
  tooManyDays,

  /// A roadtrip without a kind of vehicle.
  missingVehicle,
}

/// The data collected by the "New trip" steps, before the trip exists.
class TripDraft {
  /// Creates the data of a new trip.
  const TripDraft({
    required this.type,
    required this.name,
    required this.dayCount,
    required this.timezone,
    required this.currency,
    this.vehicleKind,
    this.destinations = const [],
    this.startDate,
    this.departure,
    this.returnPlace,
    this.timezoneSource = TimezoneSource.device,
  });

  /// Longest trip the app plans for, in days.
  static const int maxDays = 365;

  /// Itinerary or roadtrip.
  final SegmentType type;

  /// Car or motorbike, for a roadtrip.
  final VehicleKind? vehicleKind;

  /// Name of the trip.
  final String name;

  /// Names of the destinations, as typed.
  final List<String> destinations;

  /// First day, or null if the dates are not decided yet.
  final LocalDate? startDate;

  /// Number of days.
  final int dayCount;

  /// Name of the place the trip starts from, as typed.
  final String? departure;

  /// Name of the place the trip returns to, as typed.
  final String? returnPlace;

  /// IANA time zone of the days of the trip.
  final String timezone;

  /// Where [timezone] comes from.
  final TimezoneSource timezoneSource;

  /// ISO 4217 code of the main currency.
  final String currency;

  /// Last day, or null if the dates are not decided yet.
  LocalDate? get endDate => startDate?.addDays(dayCount - 1);

  /// Everything that prevents the trip from being created; empty if nothing.
  List<TripDraftProblem> get problems => [
    if (name.trim().isEmpty) TripDraftProblem.missingName,
    if (dayCount < 1) TripDraftProblem.noDays,
    if (dayCount > maxDays) TripDraftProblem.tooManyDays,
    if (type == SegmentType.roadtrip && vehicleKind == null)
      TripDraftProblem.missingVehicle,
  ];
}

/// What the rules need to know about an existing day.
class DayInfo {
  /// Creates the description of a day.
  const DayInfo({
    required this.id,
    required this.index,
    this.date,
    this.stopCount = 0,
  });

  /// Identifier of the day.
  final EntityId id;

  /// Position in the trip, from 1.
  final int index;

  /// Date, or null while the trip has no dates.
  final LocalDate? date;

  /// Number of stops in the day.
  final int stopCount;
}

/// What happens to the days of a trip when its dates or its length change.
class DayChangePlan {
  /// Creates a plan.
  const DayChangePlan({
    required this.redated,
    required this.added,
    required this.removed,
  });

  /// Days that stay and get a different date.
  final List<({EntityId id, LocalDate? date})> redated;

  /// Days to add at the end.
  final List<({int index, LocalDate? date})> added;

  /// Days to remove from the end.
  final List<DayInfo> removed;

  /// Stops that live in days about to be removed. If there are any, the app
  /// asks whether to move or delete them before doing anything (F1.1).
  int get stopsInRemovedDays =>
      removed.fold(0, (sum, day) => sum + day.stopCount);

  /// True if the user must decide what happens to stops.
  bool get needsDecision => stopsInRemovedDays > 0;

  /// True if the plan changes nothing.
  bool get isEmpty => redated.isEmpty && added.isEmpty && removed.isEmpty;
}

/// What to do with the stops of days that are removed.
enum RemovedStopsChoice {
  /// Move them to the last day that stays.
  moveToLastDay,

  /// Delete them with their day.
  delete,
}

/// How the days of a trip follow from its dates (F1.1).
abstract final class TripDays {
  /// Number of days from [start] to [end], both included.
  static int countBetween(LocalDate start, LocalDate end) =>
      start.daysUntil(end) + 1;

  /// Date of day number [index] (from 1) of a trip that starts on [start];
  /// null for a trip without dates.
  static LocalDate? dateOf(LocalDate? start, int index) =>
      start?.addDays(index - 1);

  /// Works out what changes when a trip gets the start date [newStart] (or
  /// loses its dates, if null) and [newCount] days.
  ///
  /// Days are added and removed at the end, so the stops of the days that
  /// stay never move: day 1 stays day 1. Giving dates to a trip that had
  /// only a number of days gives each day its date and touches no stop.
  static DayChangePlan planChange({
    required List<DayInfo> existing,
    required LocalDate? newStart,
    required int newCount,
  }) {
    if (newCount < 1 || newCount > TripDraft.maxDays) {
      throw ArgumentError.value(newCount, 'newCount', 'Not a number of days');
    }
    final days = [...existing]..sort((a, b) => a.index.compareTo(b.index));
    return DayChangePlan(
      redated: [
        for (final day in days)
          if (day.index <= newCount && day.date != dateOf(newStart, day.index))
            (id: day.id, date: dateOf(newStart, day.index)),
      ],
      added: [
        for (var index = days.length + 1; index <= newCount; index++)
          (index: index, date: dateOf(newStart, index)),
      ],
      removed: [
        for (final day in days)
          if (day.index > newCount) day,
      ],
    );
  }
}

/// What the rules need to know about a segment.
class SegmentInfo {
  /// Creates the description of a segment.
  const SegmentInfo({
    required this.id,
    required this.type,
    required this.startDayIndex,
    this.vehicleKind,
  });

  /// Identifier of the segment.
  final EntityId id;

  /// Itinerary or roadtrip.
  final SegmentType type;

  /// First day of the segment; it lasts until the next one starts.
  final int startDayIndex;

  /// Car or motorbike, for a roadtrip.
  final VehicleKind? vehicleKind;

  bool _sameKindAs(SegmentType otherType, VehicleKind? otherVehicle) =>
      type == otherType &&
      (type == SegmentType.itinerary || vehicleKind == otherVehicle);
}

/// What changes in the segments of a trip.
class SegmentChange {
  /// Creates a change.
  const SegmentChange({this.create, this.update, this.delete = const []});

  /// Segment to create: its first day, kind and vehicle.
  final ({int startDayIndex, SegmentType type, VehicleKind? vehicleKind})?
  create;

  /// Segment whose kind changes.
  final ({EntityId id, SegmentType type, VehicleKind? vehicleKind})? update;

  /// Segments that are no longer needed.
  final List<EntityId> delete;

  /// True if nothing changes.
  bool get isEmpty => create == null && update == null && delete.isEmpty;
}

/// How a trip is split into segments of one kind (PRD 3, F1.1).
abstract final class Segments {
  /// The segment day number [dayIndex] belongs to: the last one that starts
  /// on or before that day.
  static SegmentInfo ofDay(List<SegmentInfo> segments, int dayIndex) {
    final sorted = _sorted(segments);
    return sorted.lastWhere(
      (segment) => segment.startDayIndex <= dayIndex,
      orElse: () => sorted.first,
    );
  }

  /// True if day number [dayIndex] is in a roadtrip segment: only there do
  /// the roadtrip functions (vehicle, fuel, stops) appear (F1.1).
  static bool isRoadtripDay(List<SegmentInfo> segments, int dayIndex) =>
      ofDay(segments, dayIndex).type == SegmentType.roadtrip;

  /// Works out the change for "from day [dayIndex] on: [type]" (flow FL8).
  ///
  /// The new kind lasts until the next segment starts. Setting a day back to
  /// the kind of the days before it undoes the split: no empty or duplicate
  /// segment is ever left behind.
  static SegmentChange changeFromDay({
    required List<SegmentInfo> segments,
    required int dayIndex,
    required SegmentType type,
    VehicleKind? vehicleKind,
  }) {
    final vehicle = type == SegmentType.roadtrip ? vehicleKind : null;
    final sorted = _sorted(segments);
    final position = sorted.lastIndexWhere((s) => s.startDayIndex <= dayIndex);
    final current = sorted[position < 0 ? 0 : position];
    final previous = position > 0 ? sorted[position - 1] : null;
    final next = position + 1 < sorted.length ? sorted[position + 1] : null;
    final startsHere = current.startDayIndex == dayIndex;

    if (current._sameKindAs(type, vehicle)) return const SegmentChange();

    // The following segment becomes redundant if it has the new kind.
    final redundantNext = [
      if (next != null && next._sameKindAs(type, vehicle)) next.id,
    ];
    if (!startsHere) {
      return SegmentChange(
        create: (startDayIndex: dayIndex, type: type, vehicleKind: vehicle),
        delete: redundantNext,
      );
    }
    if (previous != null && previous._sameKindAs(type, vehicle)) {
      // Back to the kind of the days before: the split is undone.
      return SegmentChange(delete: [current.id, ...redundantNext]);
    }
    return SegmentChange(
      update: (id: current.id, type: type, vehicleKind: vehicle),
      delete: redundantNext,
    );
  }

  static List<SegmentInfo> _sorted(List<SegmentInfo> segments) {
    if (segments.isEmpty) {
      throw ArgumentError.value(segments, 'segments', 'A trip has a segment');
    }
    return [...segments]
      ..sort((a, b) => a.startDayIndex.compareTo(b.startDayIndex));
  }
}
