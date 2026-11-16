// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/ids.dart';
import '../../core/providers/service_providers.dart';
import '../trips/trip_providers.dart';

/// Gets the opening hours and contacts of the place [osmId], from the cache
/// or from the service, and puts them into the stop at [slotId] (F1.2).
/// With [refresh] the user asked to download them again.
///
/// Takes the container rather than a widget: the answer may arrive after
/// the screen that asked is gone. Returns true if the stop changed. Throws
/// a ServiceFailure when the service cannot answer.
Future<bool> fillPlaceDetails(
  ProviderContainer container, {
  required EntityId slotId,
  required String osmId,
  required String language,
  bool refresh = false,
}) async {
  final lookup = await container.read(placeDetailsLookupProvider.future);
  final (:details, :previous) = await lookup.load(
    osmId,
    language: language,
    refresh: refresh,
  );
  final stops = await container.read(stopRepositoryProvider.future);
  final changed = await stops.applyPlaceDetails(
    slotId,
    osmId: osmId,
    details: details,
    previous: previous,
  );
  container.invalidate(cachedPlaceDetailsProvider(osmId));
  // Every day: the stop may have moved to another one in the meantime.
  if (changed) container.invalidate(dayStopsProvider);
  return changed;
}
