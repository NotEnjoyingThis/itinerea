// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/place.dart';
import '../../core/net/http_transport.dart';
import '../../core/providers/service_providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// What the user chose in the sheet that adds a stop.
class NewStop {
  /// A stop with only a name: a free stop (F1.2).
  const NewStop.free(this.name) : place = null;

  /// A stop at a place found by the search, named after it.
  NewStop.at(PlaceSnapshot this.place) : name = place.name;

  /// Name of the stop.
  final String name;

  /// Place of the stop; null for a free stop.
  final PlaceSnapshot? place;
}

/// An icon for a kind of place, from its OpenStreetMap tag (for example
/// tourism:museum). Places of an unknown kind get a pin.
IconData placeIcon(String? category) {
  final (key, value) = switch (category?.split(':')) {
    [final key, final value] => (key, value),
    _ => ('', ''),
  };
  return switch ((key, value)) {
    ('tourism', 'museum' || 'gallery') => Icons.museum_outlined,
    ('tourism', 'hotel' || 'hostel' || 'guest_house' || 'motel') =>
      Icons.hotel_outlined,
    ('tourism', 'camp_site' || 'caravan_site') => Icons.cabin_outlined,
    ('tourism', 'viewpoint') => Icons.landscape_outlined,
    ('tourism', _) => Icons.attractions_outlined,
    ('amenity', 'restaurant' || 'fast_food' || 'food_court') =>
      Icons.restaurant_outlined,
    ('amenity', 'cafe' || 'bar' || 'pub' || 'ice_cream') =>
      Icons.local_cafe_outlined,
    ('amenity', 'place_of_worship') => Icons.church_outlined,
    ('amenity', 'parking') => Icons.local_parking_outlined,
    ('amenity', 'fuel' || 'charging_station') =>
      Icons.local_gas_station_outlined,
    ('historic', _) => Icons.account_balance_outlined,
    ('railway' || 'public_transport', _) => Icons.train_outlined,
    ('aeroway', _) => Icons.flight_outlined,
    ('natural' || 'leisure', _) => Icons.park_outlined,
    ('shop', _) => Icons.storefront_outlined,
    ('place', 'city' || 'town' || 'village' || 'hamlet' || 'suburb') =>
      Icons.location_city_outlined,
    ('highway' || 'building' || 'place', _) => Icons.signpost_outlined,
    _ => Icons.place_outlined,
  };
}

/// The sheet that adds a stop (F1.2, flow FL1). While the user types, the
/// places found appear below the field and one tap adds the place; the text
/// alone adds a free stop, also offline.
///
/// The search starts 300 ms after the last key and only from a few letters
/// (PRD 5.4): the public services run by volunteers ask for fair use.
class AddStopSheet extends ConsumerStatefulWidget {
  /// Creates the sheet; [near] steers the search towards the day.
  const AddStopSheet({this.near, super.key});

  /// Where the day takes place, to find nearby places first.
  final Coordinates? near;

  @override
  ConsumerState<AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends ConsumerState<AddStopSheet> {
  static const Duration _typingPause = Duration(milliseconds: 300);

  final _text = TextEditingController();
  Timer? _pause;
  // Grows with every search: an answer to an older one is dropped.
  int _search = 0;
  bool _searching = false;
  String? _searched;
  List<PlaceSuggestion> _places = const [];
  ServiceFailureKind? _failure;
  bool _tried = false;

  @override
  void dispose() {
    _pause?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _pause?.cancel();
    final query = text.trim();
    if (query.length < ref.read(placeSearchProvider).minimumQueryLength) {
      // Too short to search: what is shown no longer matches.
      _search++;
      setState(() {
        _searching = false;
        _searched = null;
        _places = const [];
        _failure = null;
      });
      return;
    }
    if (_tried) setState(() {});
    if (query != _searched) _pause = Timer(_typingPause, () => _find(query));
  }

  Future<void> _find(String query) async {
    final search = ++_search;
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _searching = true;
      _failure = null;
    });
    List<PlaceSuggestion> places = const [];
    ServiceFailureKind? failure;
    try {
      places = await ref
          .read(placeSearchProvider)
          .search(query, language: language, near: widget.near);
    } on ServiceFailure catch (error) {
      failure = error.kind;
    }
    if (!mounted || search != _search) return;
    setState(() {
      _searching = false;
      _searched = query;
      _places = places;
      _failure = failure;
    });
  }

  void _addNameOnly() {
    final name = _text.text.trim();
    if (name.isEmpty) return setState(() => _tried = true);
    Navigator.of(context).pop(NewStop.free(name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final query = _text.text.trim();
    final message = switch (_failure) {
      ServiceFailureKind.noConnection => l10n.placeSearchOffline,
      ServiceFailureKind.busy => l10n.placeSearchBusy,
      ServiceFailureKind.badResponse => l10n.placeSearchFailed,
      null when _searched != null && _places.isEmpty =>
        l10n.placeSearchNoResults,
      null => null,
    };
    return Padding(
      // Stay above the keyboard.
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.stopAdd, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            key: const Key('newStopName'),
            controller: _text,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            // The keyboard searches at once; adding is always a tap, so that
            // a place is never lost for a free stop by mistake.
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: l10n.stopSearchLabel,
              hintText: l10n.stopNameHint,
              helperText: l10n.stopSearchHelp,
              helperMaxLines: 3,
              errorText: _tried && query.isEmpty ? l10n.stopNameMissing : null,
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(),
            ),
            onChanged: _onChanged,
            onSubmitted: (text) {
              _pause?.cancel();
              final query = text.trim();
              if (query.length >=
                  ref.read(placeSearchProvider).minimumQueryLength) {
                unawaited(_find(query));
              }
            },
          ),
          SizedBox(
            height: 4,
            child: _searching
                ? const LinearProgressIndicator(key: Key('placeSearching'))
                : null,
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                if (message != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              message,
                              key: const Key('placeSearchMessage'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (_failure != null && _searched != null)
                            TextButton(
                              key: const Key('placeSearchRetry'),
                              onPressed: () => _find(_searched!),
                              child: Text(l10n.retry),
                            ),
                        ],
                      ),
                    ),
                  ),
                for (final (index, suggestion) in _places.indexed)
                  ListTile(
                    key: Key('placeSuggestion-$index'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(placeIcon(suggestion.category)),
                    title: Text(
                      suggestion.place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: switch (suggestion.place.address) {
                      final String address => Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      null => null,
                    },
                    onTap: () =>
                        Navigator.of(context).pop(NewStop.at(suggestion.place)),
                  ),
                if (_places.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.osmAttribution,
                      key: const Key('placeSearchAttribution'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: const Key('newStopAdd'),
            onPressed: _addNameOnly,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(l10n.stopAddNameOnly),
          ),
        ],
      ),
    );
  }
}
