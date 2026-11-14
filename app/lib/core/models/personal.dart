// SPDX-License-Identifier: GPL-3.0-or-later

// Personal data (PRD 8.4): synchronised only in the personal space of the
// user, never shared with the other participants of a trip.

import 'ids.dart';
import 'money.dart';
import 'place.dart';
import 'synced_entity.dart';
import 'time.dart';
import 'trip.dart';

/// Theme chosen by the user (PRD T5).
enum ThemePreference {
  /// Follow the system.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// Units used for distances and volumes (PRD F1.15).
enum UnitSystem {
  /// Kilometres and litres.
  metric,

  /// Miles and gallons.
  imperial,
}

/// Energy source of a vehicle (PRD 8.4).
enum FuelType {
  /// Petrol.
  petrol,

  /// Diesel.
  diesel,

  /// Liquefied petroleum gas.
  lpg,

  /// Compressed natural gas.
  cng,

  /// Battery electric.
  electric,

  /// Hybrid that does not plug in.
  hybrid,

  /// Plug-in hybrid.
  plugInHybrid,
}

/// Why points were added or spent (PRD 8.4, 11.4).
enum PointsReason {
  /// A verified visit.
  visit,

  /// A badge level reached.
  badge,

  /// A purchase in the shop.
  shopPurchase,
}

/// The local profile of the user (PRD 4.4, 8.4). There is no Itinerea account.
// TODO(M6 F1.15): settings screen and persistence.
class Profile extends SyncedEntity {
  /// Creates a profile.
  const Profile({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.displayName,
    required this.defaultCurrency,
    super.deletedAt,
    this.languageCode,
    this.theme = ThemePreference.system,
    this.units = UnitSystem.metric,
    this.dayStartTime = const LocalTime(9, 0),
    this.defaultStopDurationMin = 60,
  });

  /// Name shown to other participants.
  final String displayName;

  /// Language code, or null to follow the system.
  final String? languageCode;

  /// Theme of the app.
  final ThemePreference theme;

  /// Units of measure.
  final UnitSystem units;

  /// ISO 4217 code of the currency proposed for new trips.
  final String defaultCurrency;

  /// Time a day starts at unless the day says otherwise.
  final LocalTime dayStartTime;

  /// Duration given to new stops, in minutes.
  final int defaultStopDurationMin;
}

/// A vehicle of the user (PRD 8.4).
// TODO(Fase 2 F2.5): vehicle database, manual entry and range.
class Vehicle extends SyncedEntity {
  /// Creates a vehicle.
  const Vehicle({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.kind,
    required this.make,
    required this.model,
    required this.fuelType,
    required this.source,
    super.deletedAt,
    this.version,
    this.consumptionPer100Km,
    this.capacity,
    this.rangeKm,
    this.safetyMarginKm,
    this.tollClass,
  });

  /// Car or motorbike.
  final VehicleKind kind;

  /// Make.
  final String make;

  /// Model.
  final String model;

  /// Version or trim.
  final String? version;

  /// Energy source.
  final FuelType fuelType;

  /// Consumption per 100 km in thousandths of a litre or of a kWh.
  final int? consumptionPer100Km;

  /// Tank or battery size in thousandths of a litre or of a kWh.
  final int? capacity;

  /// Range in kilometres.
  final int? rangeKm;

  /// Where the data comes from: an identifier of the vehicle data pack, or
  /// manual.
  final String source;

  /// Distance kept in reserve when planning stops, in kilometres.
  final int? safetyMarginKm;

  /// Vehicle class used for tolls.
  final String? tollClass;
}

/// A toll the user paid, kept to improve estimates (PRD 8.4, F3.3).
// TODO(Fase 3 F3.3): recording and use in estimates.
class TollRecord extends SyncedEntity {
  /// Creates a toll record.
  const TollRecord({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.entryGate,
    required this.exitGate,
    required this.vehicleClass,
    required this.amount,
    required this.date,
    super.deletedAt,
  });

  /// Toll gate where the vehicle entered.
  final String entryGate;

  /// Toll gate where the vehicle left.
  final String exitGate;

  /// Class of the vehicle.
  final String vehicleClass;

  /// Amount paid.
  final Money amount;

  /// Date of the payment.
  final LocalDate date;
}

/// A visit confirmed by the position of the device (PRD 8.4, 11.2).
// TODO(Fase 4 F4.1): verification rules. Coordinates are rounded where the
// precision is not needed (PRD 13).
class VerifiedVisit extends SyncedEntity {
  /// Creates a verified visit.
  const VerifiedVisit({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.wikidataId,
    required this.visitedAt,
    required this.coordinates,
    required this.accuracyM,
    super.deletedAt,
    this.tripId,
  });

  /// Wikidata identifier of the place.
  final String wikidataId;

  /// Instant of the visit, in UTC.
  final DateTime visitedAt;

  /// Position measured by the device.
  final Coordinates coordinates;

  /// Accuracy of the position, in metres.
  final int accuracyM;

  /// Trip the visit happened in, if any.
  final EntityId? tripId;
}

/// Progress towards a badge (PRD 8.4, 11.3).
// TODO(Fase 4 F4.1): levels and thresholds.
class BadgeProgress extends SyncedEntity {
  /// Creates the progress of a badge.
  const BadgeProgress({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.badgeId,
    super.deletedAt,
    this.visitedPlaceIds = const [],
    this.level = 0,
  });

  /// Badge, as named in the badge data pack.
  final String badgeId;

  /// Places of the badge list already visited.
  final List<String> visitedPlaceIds;

  /// Level reached.
  final int level;
}

/// One movement of travel points (PRD 8.4, 11.4). The balance is calculated
/// from the movements.
// TODO(Fase 4 F4.2): points, shop and profile.
class PointsEntry extends SyncedEntity {
  /// Creates a movement of points.
  const PointsEntry({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.amount,
    required this.reason,
    required this.at,
    super.deletedAt,
  });

  /// Points added (positive) or spent (negative).
  final int amount;

  /// Why the points moved.
  final PointsReason reason;

  /// Instant of the movement, in UTC.
  final DateTime at;
}

/// A cosmetic item bought in the shop (PRD 8.4, 11.5).
// TODO(Fase 4 F4.2): shop.
class OwnedItem extends SyncedEntity {
  /// Creates an owned item.
  const OwnedItem({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.itemId,
    super.deletedAt,
    this.active = false,
  });

  /// Item, as named in the shop data pack.
  final String itemId;

  /// True if the item is in use.
  final bool active;
}

/// The user's own rating of a place (PRD 8.4, F4.4).
// TODO(Fase 4 F4.4): ratings.
class PlaceRating extends SyncedEntity {
  /// Creates a rating.
  const PlaceRating({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.placeId,
    required this.rating,
    super.deletedAt,
    this.note,
  });

  /// Identifier of the place.
  final String placeId;

  /// Rating from 1 to 5.
  final int rating;

  /// Personal note.
  final String? note;
}

/// Notification settings for one kind of notification (PRD 8.4, 10).
// TODO(Fase 2 F2.9): configurable notifications.
class NotificationSettings extends SyncedEntity {
  /// Creates the settings of [type].
  const NotificationSettings({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.type,
    super.deletedAt,
    this.enabled = true,
    this.leadTimeMin,
    this.quietFrom,
    this.quietTo,
    this.maxPerDay,
  });

  /// Kind of notification (PRD 10.2).
  final String type;

  /// True if this kind of notification is on.
  final bool enabled;

  /// How long before the event the notification is shown, in minutes.
  final int? leadTimeMin;

  /// Start of the quiet hours.
  final LocalTime? quietFrom;

  /// End of the quiet hours.
  final LocalTime? quietTo;

  /// Maximum number of notifications per day.
  final int? maxPerDay;
}

/// The provider chosen for one external service (PRD 4.6, 8.4).
///
/// Personal keys are never stored here: they go to the secure storage of the
/// system.
// TODO(M6 F1.15): provider settings.
class ProviderSettings extends SyncedEntity {
  /// Creates the settings of [service].
  const ProviderSettings({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.service,
    required this.providerId,
    super.deletedAt,
    this.customUrl,
    this.hasPersonalKey = false,
  });

  /// Service the settings are for, for example routing.
  final String service;

  /// Provider chosen for the service.
  final String providerId;

  /// Address of the user's own server, if set.
  final Uri? customUrl;

  /// True if a personal key is stored in the secure storage.
  final bool hasPersonalKey;
}

/// An itinerary imported from a file (PRD 8.4, F4.3).
// TODO(Fase 4 F4.3): import and sharing of itinerary files.
class ImportedItinerary extends SyncedEntity {
  /// Creates an imported itinerary.
  const ImportedItinerary({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.title,
    required this.importedAt,
    super.deletedAt,
  });

  /// Title of the itinerary.
  final String title;

  /// Instant of the import, in UTC.
  final DateTime importedAt;
}
