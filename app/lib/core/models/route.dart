// SPDX-License-Identifier: GPL-3.0-or-later

import 'ids.dart';
import 'place.dart';

/// What a route should favour (PRD 8.3, RouteProfile).
enum RoutePreference {
  /// The quickest route.
  fastest,

  /// A route with many bends.
  curvy,

  /// A scenic route.
  scenic,
}

/// What kind of scenery a scenic route looks for (PRD 8.3, F3.4).
enum ScenicType {
  /// Along the sea.
  sea,

  /// Along a lake.
  lake,

  /// In the mountains.
  mountain,

  /// Any scenery.
  any,
}

/// Preferences used to calculate a route (PRD 8.3). Embedded in trips,
/// segments and legs.
// TODO(M4 F1.5): translate the profile into routing requests. The "avoid"
// options are preferences, not prohibitions (PRD 16.3, prototype 3).
class RouteProfile {
  /// Creates a route profile.
  const RouteProfile({
    this.preference = RoutePreference.fastest,
    this.scenicType = ScenicType.any,
    this.avoidHighways = false,
    this.avoidTolls = false,
    this.avoidUnpaved = false,
    this.avoidFerries = false,
  });

  /// What the route should favour.
  final RoutePreference preference;

  /// Scenery looked for when [preference] is scenic.
  final ScenicType scenicType;

  /// Prefer roads that are not motorways.
  final bool avoidHighways;

  /// Prefer roads without tolls.
  final bool avoidTolls;

  /// Prefer paved roads.
  final bool avoidUnpaved;

  /// Prefer routes without ferries.
  final bool avoidFerries;
}

/// A calculated route, embedded in a leg (PRD 8.3).
// TODO(M4 F1.5): calculation, "to be recalculated" state and editing.
class Route {
  /// Creates a route.
  const Route({
    required this.fromStopId,
    required this.toStopId,
    required this.geometry,
    required this.provider,
    required this.profileUsed,
    required this.computedAt,
    this.waypoints = const [],
    this.editedByUser = false,
  });

  /// Stop the route starts from.
  final EntityId fromStopId;

  /// Stop the route ends at.
  final EntityId toStopId;

  /// Encoded polyline of the route.
  final String geometry;

  /// Waypoints added by dragging the route.
  final List<Coordinates> waypoints;

  /// Identifier of the service that calculated it, for example
  /// valhalla-fossgis.
  final String provider;

  /// Profile the route was calculated with.
  final RouteProfile profileUsed;

  /// Instant of calculation, in UTC.
  final DateTime computedAt;

  /// True if the user edited the route: it is then never recalculated
  /// automatically (F1.5).
  final bool editedByUser;
}
