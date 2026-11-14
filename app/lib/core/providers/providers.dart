// SPDX-License-Identifier: GPL-3.0-or-later

// One interface per kind of external service (PRD 4.6, 5.2). Interfaces
// only: no implementation exists yet.

import '../models/booking.dart';
import '../models/cache.dart';
import '../models/place.dart';
import '../models/route.dart';
import '../models/stop.dart';
import '../models/time.dart';
import 'service_provider.dart';

/// Layers of places that can be shown on the map (PRD F1.7, F2.7).
enum PoiLayer {
  /// Public toilets.
  toilets,

  /// Fuel stations.
  fuel,

  /// Charging stations.
  charging,

  /// Campsites and camper areas.
  camping,

  /// Hotels.
  hotels,

  /// Attractions.
  attractions,
}

/// Online base map (default: OpenFreeMap).
// TODO(M4 F1.7): vector map in raster mode (PRD 16.3, prototype 1).
abstract interface class MapTileProvider implements ServiceProvider {
  /// Address of the style for the light or the dark theme.
  Uri styleUrl({required bool dark});

  /// Attribution that must be shown on the map (PRD 5.5).
  String get attribution;
}

/// Route calculation (default: Valhalla run by FOSSGIS).
// TODO(M4 F1.5): one request at a time, at most one per second per device
// (PRD 5.6); check the result against every "avoid" option.
abstract interface class RoutingProvider implements ServiceProvider {
  /// Calculates a route between two stops.
  Future<Route> route({
    required PlaceSnapshot from,
    required PlaceSnapshot to,
    required LegMode mode,
    required RouteProfile profile,
    List<Coordinates> via = const [],
  });
}

/// Elevation along a route (default: the height endpoint of Valhalla).
// TODO(Fase 3 F3.4): elevation for scenic mountain routes.
abstract interface class ElevationProvider implements ServiceProvider {
  /// Returns the height in metres of each of the given points.
  Future<List<int>> heights(List<Coordinates> points);
}

/// Search of places and addresses (default: Photon).
// TODO(M3 F1.2): search with a 300 ms wait after the last key (PRD 5.4).
abstract interface class PlaceSearchProvider implements ServiceProvider {
  /// Searches places matching the text typed by the user.
  Future<List<PlaceSnapshot>> search(String query, {Coordinates? near});
}

/// Details of a place (OpenStreetMap, Wikidata).
// TODO(M3 F1.2): opening hours, contacts and website of a stop.
abstract interface class PlaceDetailsProvider implements ServiceProvider {
  /// Returns the details of a place.
  Future<PlaceCache> details(PlaceSnapshot place);
}

/// Places for the layers of the map (default: Overpass API).
// TODO(M4 F1.7): map layers. TODO(Fase 2 F2.8): offline places.
abstract interface class PoiProvider implements ServiceProvider {
  /// Returns the places of one layer inside an area.
  Future<List<PlaceSnapshot>> places(BoundingBox area, PoiLayer layer);
}

/// Public transport (default: Transitous).
// TODO(Fase 2 F2.4): public transport solutions.
abstract interface class TransitProvider implements ServiceProvider {
  /// Returns the solutions between two places at a given time.
  Future<List<TransitSolution>> solutions({
    required PlaceSnapshot from,
    required PlaceSnapshot to,
    required ZonedLocalDateTime departure,
  });
}

/// Weather (default: MET Norway).
// TODO(M5 F1.11): forecast of the main place of each day.
abstract interface class WeatherProvider implements ServiceProvider {
  /// Returns the forecast for a place.
  Future<WeatherCache> forecast(Coordinates place);
}

/// Exchange rates (default: Frankfurter).
// TODO(M5 F1.10): rate of the day of the expense.
abstract interface class FxRateProvider implements ServiceProvider {
  /// Returns the rate between two currencies on a date.
  Future<FxRate> rate({
    required String from,
    required String to,
    required LocalDate date,
  });
}

/// Fuel prices (official national sources, called directly by the app).
// TODO(Fase 2 F2.6): fuel prices and stops.
abstract interface class FuelPriceProvider implements ServiceProvider {
  /// Returns the prices of the stations inside an area.
  Future<List<FuelPrice>> prices(BoundingBox area);
}

/// Charging stations (OpenStreetMap, Open Charge Map).
// TODO(Fase 2 F2.6): charging stops.
abstract interface class ChargingProvider implements ServiceProvider {
  /// Returns the charging stations inside an area.
  Future<List<PlaceSnapshot>> stations(BoundingBox area);
}

/// Static data packs published with GitHub Releases (PRD 4.6).
// TODO(Fase 2 F2.5): download and update of data packs.
abstract interface class DataPackProvider implements ServiceProvider {
  /// Returns the latest published version of a pack.
  Future<DataPack> latest(String name);
}

/// Reads bookings from files, on the device (PRD F2.3). Not an external
/// service: nothing leaves the device.
///
/// Imported files are untrusted: size limits, no execution (PRD 13).
// TODO(Fase 2 F2.3): schema.org data, boarding pass barcodes, PDF rules.
abstract interface class BookingReader {
  /// Reads the bookings found in a file.
  Future<List<Booking>> read({
    required List<int> bytes,
    required String mimeType,
  });
}
