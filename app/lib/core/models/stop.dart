// SPDX-License-Identifier: GPL-3.0-or-later

import 'ids.dart';
import 'money.dart';
import 'place.dart';
import 'route.dart';
import 'synced_entity.dart';
import 'time.dart';

/// One of the alternative plans of a position in a day (PRD 8.3, F1.6).
enum Plan {
  /// The first plan; a position without alternatives only has this one.
  a,

  /// The second plan.
  b,

  /// The third plan.
  c,

  /// The fourth plan.
  d,
}

/// Kind of a stop (PRD 8.3).
enum StopKind {
  /// A place to visit.
  place,

  /// Free time without a place.
  free,

  /// A fuel stop.
  refuel,

  /// A charging stop.
  charge,

  /// A rest stop.
  rest,
}

/// State of a stop (PRD 8.3).
enum StopStatus {
  /// Not visited yet.
  planned,

  /// Visited.
  visited,

  /// Skipped.
  skipped,
}

/// How a leg is travelled (PRD 8.3).
enum LegMode {
  /// On foot.
  walk,

  /// By car.
  car,

  /// By motorbike.
  motorbike,

  /// By bicycle.
  bike,

  /// By bus.
  bus,

  /// By train.
  train,

  /// By underground.
  metro,

  /// By tram.
  tram,

  /// By ferry.
  ferry,

  /// By plane.
  plane,

  /// By taxi.
  taxi,

  /// Any other way.
  other,
}

/// A position in a day, separate from the stop that fills it so that a
/// position can have alternative plans (PRD 8.3).
// TODO(M3 F1.2): ordering with fractional keys. TODO(M3 F1.6): plans.
class StopSlot extends SyncedEntity {
  /// Creates a position.
  const StopSlot({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.dayId,
    required this.orderKey,
    super.deletedAt,
    this.activePlan = Plan.a,
  });

  /// Day the position belongs to.
  final EntityId dayId;

  /// Fractional index that orders the positions of a day.
  final String orderKey;

  /// Plan currently in use.
  final Plan activePlan;
}

/// A stop: what fills a position under one plan (PRD 8.3).
// TODO(M3 F1.2): editing. TODO(M3 F1.3): calculated start times.
class Stop extends SyncedEntity {
  /// Creates a stop.
  const Stop({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.slotId,
    required this.kind,
    required this.name,
    required this.durationMin,
    super.deletedAt,
    this.plan = Plan.a,
    this.place,
    this.startTime,
    this.timeFixed = false,
    this.estimatedCost,
    this.links = const [],
    this.status = StopStatus.planned,
    this.visitedAt,
    this.verifiedVisitId,
    this.bookingId,
    this.noteId,
  });

  /// Position the stop belongs to.
  final EntityId slotId;

  /// Plan the stop belongs to.
  final Plan plan;

  /// Kind of stop.
  final StopKind kind;

  /// Copy of the data of the place, taken when the stop was added.
  final PlaceSnapshot? place;

  /// Name of the stop.
  final String name;

  /// Start time in the time zone of the day; calculated unless [timeFixed].
  final LocalTime? startTime;

  /// True if the time is tied to a booking or fixed by hand.
  final bool timeFixed;

  /// Duration in minutes.
  final int durationMin;

  /// Estimated cost; an estimate only, it does not enter the budget (F1.6).
  final Money? estimatedCost;

  /// Links saved with the stop.
  final List<Uri> links;

  /// State of the stop.
  final StopStatus status;

  /// Instant of the visit, in UTC.
  final DateTime? visitedAt;

  /// Visit confirmed by GPS (PRD 8.4).
  final EntityId? verifiedVisitId;

  /// Booking tied to the stop.
  final EntityId? bookingId;

  /// Note attached to the stop.
  final EntityId? noteId;
}

/// One part of a public transport solution (PRD 8.3, phase 2).
class TransitPart {
  /// Creates one part of a solution.
  const TransitPart({
    required this.mode,
    required this.fromStopName,
    required this.toStopName,
    required this.departure,
    required this.arrival,
    this.line,
  });

  /// Means of transport of this part.
  final LegMode mode;

  /// Line name or number.
  final String? line;

  /// Name of the stop where this part starts.
  final String fromStopName;

  /// Name of the stop where this part ends.
  final String toStopName;

  /// Departure, local time with its zone.
  final ZonedLocalDateTime departure;

  /// Arrival, local time with its zone.
  final ZonedLocalDateTime arrival;
}

/// A saved public transport solution, embedded in a leg (PRD 8.3, phase 2).
// TODO(Fase 2 F2.4): search, saving and the "saved on" label.
class TransitSolution {
  /// Creates a solution.
  const TransitSolution({
    required this.parts,
    required this.durationMin,
    required this.provider,
    required this.savedAt,
  });

  /// Parts of the solution, in order.
  final List<TransitPart> parts;

  /// Total duration in minutes.
  final int durationMin;

  /// Identifier of the service that gave the solution.
  final String provider;

  /// Instant the solution was saved, in UTC.
  final DateTime savedAt;
}

/// The link between two neighbouring positions of a day (PRD 8.3).
// TODO(M4 F1.4): create, reuse and tombstone leg slots when stops move.
class LegSlot extends SyncedEntity {
  /// Creates a leg slot.
  const LegSlot({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.dayId,
    required this.fromSlotId,
    required this.toSlotId,
    super.deletedAt,
    this.activePlan = Plan.a,
  });

  /// Day the leg belongs to.
  final EntityId dayId;

  /// Position the leg starts from.
  final EntityId fromSlotId;

  /// Position the leg ends at.
  final EntityId toSlotId;

  /// Plan currently in use.
  final Plan activePlan;
}

/// A leg: how one travels between two stops under one plan (PRD 8.3).
// TODO(M4 F1.4): modes and manual durations. TODO(M4 F1.5): routes.
class Leg extends SyncedEntity {
  /// Creates a leg.
  const Leg({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.legSlotId,
    required this.mode,
    super.deletedAt,
    this.plan = Plan.a,
    this.routeProfile,
    this.route,
    this.transitSolution,
    this.durationMin,
    this.distanceM,
    this.manual = false,
    this.fuelCostEstimate,
    this.tollEstimate,
    this.bookingId,
  });

  /// Leg slot the leg belongs to.
  final EntityId legSlotId;

  /// Plan the leg belongs to.
  final Plan plan;

  /// How the leg is travelled.
  final LegMode mode;

  /// Route profile that replaces the one of the segment, if set.
  final RouteProfile? routeProfile;

  /// Calculated route, for road and walking legs only.
  final Route? route;

  /// Saved public transport solution (phase 2).
  final TransitSolution? transitSolution;

  /// Duration in minutes, calculated or entered by hand.
  final int? durationMin;

  /// Distance in metres, calculated or entered by hand.
  final int? distanceM;

  /// True if the duration was entered by hand.
  final bool manual;

  /// Estimated fuel cost (phase 2).
  final Money? fuelCostEstimate;

  /// Estimated tolls (phase 3).
  final Money? tollEstimate;

  /// Booking tied to the leg, for example a train ticket.
  final EntityId? bookingId;
}
