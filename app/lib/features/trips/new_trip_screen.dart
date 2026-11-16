// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/trip.dart';
import '../../core/theme/window_size.dart';
import '../../core/time/timezones.dart';
import '../../l10n/generated/app_localizations.dart';
import 'timezone_picker_screen.dart';
import 'trip_dates_editor.dart';
import 'trip_list.dart';
import 'trip_plan.dart';
import 'trip_screen.dart';

/// New trip (S02): three steps, then the trip exists (F1.1).
///
/// 1. itinerary or roadtrip; 2. name, destinations, dates or only a number of
/// days; 3. where the trip starts and ends, and its time zone.
// TODO(M5 F1.9): the outbound and return flight or train, in step 3.
// TODO(M4 F1.1): destinations picked from the place search instead of typed
// names (decided on 16/11/2026).
class NewTripScreen extends ConsumerStatefulWidget {
  /// Creates the "new trip" steps.
  const NewTripScreen({super.key});

  @override
  ConsumerState<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends ConsumerState<NewTripScreen> {
  static const int _steps = 3;

  int _step = 0;
  bool _saving = false;
  // Problems are shown only after the user tried to go on.
  bool _triedToLeaveDetails = false;

  SegmentType _type = SegmentType.itinerary;
  VehicleKind _vehicle = VehicleKind.car;
  final _name = TextEditingController();
  final _destinations = TextEditingController();
  TripDates _dates = const TripDates();
  final _departure = TextEditingController();
  final _return = TextEditingController();
  bool _returnToSamePlace = true;
  String? _chosenTimezone;

  @override
  void dispose() {
    _name.dispose();
    _destinations.dispose();
    _departure.dispose();
    _return.dispose();
    super.dispose();
  }

  bool get _detailsValid =>
      _name.text.trim().isNotEmpty && !_dates.isIncomplete;

  void _next() {
    if (_step == 1) {
      setState(() => _triedToLeaveDetails = true);
      if (!_detailsValid) return;
    }
    setState(() => _step++);
  }

  Future<void> _pickTimezone(String current) async {
    final picked = await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => TimezonePickerScreen(selected: current),
      ),
    );
    if (picked != null) setState(() => _chosenTimezone = picked);
  }

  Future<void> _create(String deviceTimezone) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final draft = TripDraft(
      type: _type,
      vehicleKind: _type == SegmentType.roadtrip ? _vehicle : null,
      name: _name.text,
      destinations: _destinations.text.split(','),
      startDate: _dates.startDate,
      dayCount: _dates.length,
      departure: _departure.text,
      returnPlace: _returnToSamePlace ? _departure.text : _return.text,
      timezone: _chosenTimezone ?? deviceTimezone,
      timezoneSource: _chosenTimezone == null
          ? TimezoneSource.device
          : TimezoneSource.user,
      currency: _deviceCurrency(),
    );
    setState(() => _saving = true);
    try {
      final repository = await ref.read(tripRepositoryProvider.future);
      final tripId = await repository.createTrip(draft);
      ref.invalidate(tripSummariesProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tripCreated(draft.name.trim()))),
      );
      // The new trip opens on its first day (PRD 7.3, S02).
      unawaited(
        navigator.pushReplacement(
          MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: tripId)),
        ),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.tripCreateError)));
    }
  }

  /// Currency of the country the device is set to; the euro if unknown.
  // TODO(M6 F1.15): the default currency of the settings.
  static String _deviceCurrency() {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale
          .toString();
      return NumberFormat.simpleCurrency(locale: locale).currencyName ?? 'EUR';
    } on Exception {
      return 'EUR';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final margin = WindowSize.of(context).margin;
    final deviceTimezone =
        ref.watch(deviceTimezoneProvider).value ?? fallbackTimezone;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenNewTrip),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _steps,
            semanticsLabel: l10n.newTripStep(_step + 1, _steps),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(margin, 24, margin, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.newTripStep(_step + 1, _steps),
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        ...switch (_step) {
                          0 => _kindStep(l10n, theme),
                          1 => _detailsStep(l10n, theme),
                          _ => _placesStep(l10n, theme, deviceTimezone),
                        },
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: margin, vertical: 12),
              // Side by side when there is room, one above the other on a
              // narrow screen with large text.
              child: OverflowBar(
                alignment: _step > 0
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                overflowSpacing: 8,
                children: [
                  if (_step > 0)
                    TextButton(
                      key: const Key('newTripBack'),
                      onPressed: _saving ? null : () => setState(() => _step--),
                      child: Text(l10n.actionBack),
                    ),
                  if (_step < _steps - 1)
                    FilledButton(
                      key: const Key('newTripNext'),
                      onPressed: _next,
                      child: Text(l10n.actionNext),
                    )
                  else
                    FilledButton(
                      key: const Key('newTripCreate'),
                      onPressed: _saving ? null : () => _create(deviceTimezone),
                      child: Text(l10n.tripCreate),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _kindStep(AppLocalizations l10n, ThemeData theme) => [
    _heading(l10n.newTripKindQuestion, theme),
    const SizedBox(height: 16),
    _KindCard(
      key: const Key('kindItinerary'),
      icon: Icons.location_city_rounded,
      title: l10n.tripKindItinerary,
      hint: l10n.tripKindItineraryHint,
      selected: _type == SegmentType.itinerary,
      onTap: () => setState(() => _type = SegmentType.itinerary),
    ),
    const SizedBox(height: 12),
    _KindCard(
      key: const Key('kindRoadtrip'),
      icon: Icons.route_rounded,
      title: l10n.tripKindRoadtrip,
      hint: l10n.tripKindRoadtripHint,
      selected: _type == SegmentType.roadtrip,
      onTap: () => setState(() => _type = SegmentType.roadtrip),
    ),
    if (_type == SegmentType.roadtrip) ...[
      const SizedBox(height: 24),
      Text(l10n.vehicleQuestion, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      SegmentedButton<VehicleKind>(
        key: const Key('vehicleSelector'),
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: VehicleKind.car,
            icon: const Icon(Icons.directions_car_rounded),
            label: Text(l10n.vehicleCar),
          ),
          ButtonSegment(
            value: VehicleKind.motorbike,
            icon: const Icon(Icons.two_wheeler_rounded),
            label: Text(l10n.vehicleMotorbike),
          ),
        ],
        selected: {_vehicle},
        onSelectionChanged: (value) => setState(() => _vehicle = value.single),
      ),
    ],
    const SizedBox(height: 16),
    Text(l10n.tripKindChangeLater, style: theme.textTheme.bodySmall),
  ];

  List<Widget> _detailsStep(AppLocalizations l10n, ThemeData theme) {
    return [
      TextField(
        key: const Key('tripName'),
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: l10n.tripName,
          border: const OutlineInputBorder(),
          errorText: _triedToLeaveDetails && _name.text.trim().isEmpty
              ? l10n.tripNameMissing
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      TextField(
        key: const Key('tripDestinations'),
        controller: _destinations,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.tripDestinations,
          hintText: l10n.tripDestinationsHint,
          helperText: l10n.tripOptionalHint,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 24),
      TripDatesEditor(
        value: _dates,
        showProblems: _triedToLeaveDetails,
        onChanged: (dates) => setState(() => _dates = dates),
      ),
    ];
  }

  List<Widget> _placesStep(
    AppLocalizations l10n,
    ThemeData theme,
    String deviceTimezone,
  ) {
    final timezone = _chosenTimezone ?? deviceTimezone;
    return [
      TextField(
        key: const Key('tripDeparture'),
        controller: _departure,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.tripDeparture,
          helperText: l10n.tripOptionalHint,
          border: const OutlineInputBorder(),
        ),
      ),
      CheckboxListTile(
        key: const Key('returnSamePlace'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(l10n.tripReturnSame),
        value: _returnToSamePlace,
        onChanged: (value) => setState(() => _returnToSamePlace = value!),
      ),
      if (!_returnToSamePlace) ...[
        TextField(
          key: const Key('tripReturn'),
          controller: _return,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.tripReturn,
            helperText: l10n.tripOptionalHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
      ],
      const Divider(),
      ListTile(
        key: const Key('tripTimezone'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.schedule_rounded),
        title: Text('${l10n.timezoneLabel}: ${timezone.replaceAll('_', ' ')}'),
        // Honest about where the zone comes from (PRD T4).
        subtitle: Text(
          _chosenTimezone == null
              ? l10n.timezoneFromDevice
              : l10n.timezoneChosen,
        ),
        trailing: TextButton(
          key: const Key('changeTimezone'),
          onPressed: () => _pickTimezone(timezone),
          child: Text(l10n.timezoneChange),
        ),
      ),
    ];
  }

  static Widget _heading(String text, ThemeData theme) => Semantics(
    header: true,
    child: Text(text, style: theme.textTheme.titleLarge),
  );
}

/// One of the two kinds of trip, as a large selectable row.
class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon, size: 32),
          title: Text(title),
          subtitle: Text(hint),
          trailing: selected ? const Icon(Icons.check_circle_rounded) : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
