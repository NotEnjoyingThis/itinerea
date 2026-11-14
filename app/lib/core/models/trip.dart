// SPDX-License-Identifier: GPL-3.0-or-later

import 'ids.dart';
import 'money.dart';
import 'place.dart';
import 'route.dart';
import 'synced_entity.dart';
import 'time.dart';

/// How the budget of a trip is set (PRD 8.3).
enum BudgetMode {
  /// One amount for the whole trip.
  total,

  /// One amount per day.
  perDay,

  /// No budget.
  none,
}

/// Role of a participant in a trip (PRD 4.4, 8.3).
enum ParticipantRole {
  /// Owns the trip and its sync space.
  owner,

  /// Can change the trip.
  editor,

  /// Can only look at the trip.
  viewer,
}

/// Kind of a segment of a trip (PRD 3, 8.3).
enum SegmentType {
  /// Days spent visiting places.
  itinerary,

  /// Days spent travelling by car or motorbike.
  roadtrip,
}

/// Kind of vehicle used in a roadtrip segment (PRD 8.3).
enum VehicleKind {
  /// A car.
  car,

  /// A motorbike.
  motorbike,
}

/// How fuel or charging stops are planned in a segment (PRD 8.3, F2.6).
enum StopPlanning {
  /// The app proposes the stops.
  auto,

  /// The user adds the stops.
  manual,
}

/// Where a time zone comes from (PRD 8.3).
///
/// A zone taken from the device is only a guess and may later be replaced by
/// the zone of the place; a zone chosen by the user is never changed.
enum TimezoneSource {
  /// The zone of the device the trip or the day was created on.
  device,

  /// Chosen by hand.
  user,

  /// Worked out from the main place.
  // TODO(M5 F1.9): zone from the coordinates of the place, for flights.
  place,
}

/// Reference from a trip to the place where it is synchronised (PRD 8.3).
// TODO(M6 F1.13): the real reference to a SyncSpace.
class SyncSpaceRef {
  /// Creates a reference to the space [kind] at [path].
  const SyncSpaceRef({required this.kind, required this.path});

  /// Kind of space, for example webdav or localFolder.
  final String kind;

  /// Location of the trip inside the space.
  final String path;
}

/// A trip (PRD 8.3).
// TODO(M3 F1.1): creation, validation and generation of the days.
class Trip extends SyncedEntity {
  /// Creates a trip.
  const Trip({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.name,
    required this.dayCount,
    required this.departurePlace,
    required this.returnPlace,
    required this.currency,
    required this.defaultRouteProfile,
    required this.ownerParticipantId,
    required this.timezone,
    super.deletedAt,
    this.startDate,
    this.endDate,
    this.destinations = const [],
    this.budgetMode = BudgetMode.none,
    this.budgetTotal,
    this.syncSpace,
    this.encrypted = false,
    this.timezoneSource = TimezoneSource.device,
  });

  /// Name of the trip.
  final String name;

  /// First day, if the trip has dates.
  final LocalDate? startDate;

  /// Last day, if the trip has dates.
  final LocalDate? endDate;

  /// Number of days.
  final int dayCount;

  /// Destinations given when the trip was created (F1.1).
  final List<PlaceSnapshot> destinations;

  /// Place the trip starts from.
  final PlaceSnapshot departurePlace;

  /// Place the trip returns to.
  final PlaceSnapshot returnPlace;

  /// ISO 4217 code of the main currency.
  final String currency;

  /// How the budget is set.
  final BudgetMode budgetMode;

  /// Budget of the whole trip, when [budgetMode] is total.
  final Money? budgetTotal;

  /// Route profile used unless a segment or a leg replaces it.
  final RouteProfile defaultRouteProfile;

  /// Where the trip is synchronised, or null if it is only on this device.
  final SyncSpaceRef? syncSpace;

  /// True if the trip uses end-to-end encryption (PRD 4.3).
  final bool encrypted;

  /// IANA time zone the days of the trip start with.
  final String timezone;

  /// Where [timezone] comes from.
  final TimezoneSource timezoneSource;

  /// Participant that owns the trip.
  final EntityId ownerParticipantId;
}

/// A person taking part in a trip (PRD 8.3).
// TODO(Fase 2 F2.1): invitations and roles. In phase 1 the only participant
// is the user, as owner.
class Participant extends SyncedEntity {
  /// Creates a participant.
  const Participant({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.profileId,
    required this.displayName,
    required this.role,
    required this.color,
    super.deletedAt,
    this.providerAccount,
  });

  /// Local profile of the person.
  final EntityId profileId;

  /// Name shown to the other participants.
  final String displayName;

  /// Role in the trip.
  final ParticipantRole role;

  /// Account of the sync service, only used to manage sharing.
  final String? providerAccount;

  /// Colour that tells people apart in the interface, as a 32-bit ARGB value.
  final int color;
}

/// A copy of the data of the vehicle used in a segment (PRD 8.3, phase 2).
// TODO(Fase 2 F2.5): copy the fields of Vehicle when the user picks one.
class VehicleSnapshot {
  /// Creates a vehicle snapshot.
  const VehicleSnapshot({required this.vehicleId, required this.label});

  /// Vehicle the copy was taken from.
  final EntityId vehicleId;

  /// Make, model and version, as shown to the user.
  final String label;
}

/// A run of consecutive days of the same kind (PRD 3, 8.3).
// TODO(M3 F1.1): split a trip into segments (flow FL8).
class Segment extends SyncedEntity {
  /// Creates a segment.
  const Segment({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.tripId,
    required this.type,
    required this.startDayIndex,
    super.deletedAt,
    this.vehicleKind,
    this.vehicleSnapshot,
    this.routeProfile,
    this.stopPlanning = StopPlanning.manual,
  });

  /// Trip the segment belongs to.
  final EntityId tripId;

  /// Kind of segment.
  final SegmentType type;

  /// First day of the segment; it lasts until the next segment starts.
  final int startDayIndex;

  /// Kind of vehicle, for roadtrip segments only.
  final VehicleKind? vehicleKind;

  /// Data of the vehicle used (phase 2).
  final VehicleSnapshot? vehicleSnapshot;

  /// Route profile that replaces the one of the trip, if set.
  final RouteProfile? routeProfile;

  /// How fuel or charging stops are planned.
  final StopPlanning stopPlanning;
}

/// A day of a trip (PRD 8.3).
// TODO(M3 F1.2): day list, start time and main place.
class Day extends SyncedEntity {
  /// Creates a day.
  const Day({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.tripId,
    required this.index,
    required this.timezone,
    super.deletedAt,
    this.date,
    this.mainPlace,
    this.budget,
    this.startTime,
    this.noteId,
    this.timezoneSource = TimezoneSource.device,
  });

  /// Trip the day belongs to.
  final EntityId tripId;

  /// Position in the trip: day 1, day 2…
  final int index;

  /// Date, or null while the trip has no dates.
  final LocalDate? date;

  /// IANA time zone of the day; stop times are in this zone. By default
  /// it is the zone of the trip.
  final String timezone;

  /// Where [timezone] comes from.
  final TimezoneSource timezoneSource;

  /// Main place of the day, used for weather and time zone (F1.11).
  final PlaceSnapshot? mainPlace;

  /// Budget of the day, when the trip budget is per day.
  final Money? budget;

  /// Time the day starts at; if null the setting applies (default 9:00).
  final LocalTime? startTime;

  /// Note attached to the day.
  final EntityId? noteId;
}
