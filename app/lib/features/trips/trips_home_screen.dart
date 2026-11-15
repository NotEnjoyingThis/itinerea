// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/time.dart';
import '../../core/theme/window_size.dart';
import '../../core/time/timezones.dart';
import '../../l10n/generated/app_localizations.dart';
import '../day/day_screen.dart';
import '../scaffold/scaffold_catalog_screen.dart';
import '../settings/settings_screen.dart';
import 'new_trip_screen.dart';
import 'trip_list.dart';

/// Home of the app (S01): the trip happening today first, then the upcoming
/// ones, those without dates and the past ones; or an invitation to create
/// the first trip. There is no login and no account (PRD 7.1, 7.6).
// TODO(M3 F1.2): the "today" card of the trip in progress (PRD 7.4).
class TripsHomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const TripsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(tripSummariesProvider);
    final margin = WindowSize.of(context).margin;

    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenTripsHome),
        actions: [
          // Debug builds only: the list of placeholder screens (PRD 15.1).
          if (ref.watch(scaffoldCatalogEnabledProvider))
            IconButton(
              key: const Key('openScaffoldCatalog'),
              icon: const Icon(Icons.construction_rounded),
              tooltip: l10n.scaffoldCatalogOpen,
              onPressed: () => open(const ScaffoldCatalogScreen()),
            ),
          IconButton(
            key: const Key('openSettings'),
            icon: const Icon(Icons.settings_rounded),
            tooltip: l10n.screenSettings,
            onPressed: () => open(const SettingsScreen()),
          ),
          SizedBox(width: margin - 8),
        ],
      ),
      body: SafeArea(
        child: switch (trips) {
          AsyncData(:final value) when value.isEmpty => _Message(
            icon: Icons.luggage_rounded,
            title: l10n.tripsEmptyTitle,
            body: l10n.tripsEmptyBody,
            actionLabel: l10n.screenNewTrip,
            actionKey: const Key('createFirstTrip'),
            onAction: () => open(const NewTripScreen()),
          ),
          AsyncData(:final value) => _TripList(
            trips: value,
            today: ref.watch(todayProvider)(),
            margin: margin,
            // TODO(M3 F1.2): open the trip on its day list.
            onOpen: (_) => open(const DayScreen()),
          ),
          AsyncError() => _Message(
            icon: Icons.error_outline_rounded,
            title: l10n.dataOpenError,
            actionLabel: l10n.retry,
            actionKey: const Key('retryOpenData'),
            onAction: () => ref.invalidate(tripSummariesProvider),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
      floatingActionButton: switch (trips) {
        AsyncData(:final value) when value.isNotEmpty => FloatingActionButton(
          key: const Key('newTrip'),
          tooltip: l10n.screenNewTrip,
          onPressed: () => open(const NewTripScreen()),
          child: const Icon(Icons.add_rounded),
        ),
        _ => null,
      },
    );
  }
}

/// The trips, grouped by where they stand today.
class _TripList extends StatelessWidget {
  const _TripList({
    required this.trips,
    required this.today,
    required this.margin,
    required this.onOpen,
  });

  final List<TripSummary> trips;
  final LocalDate today;
  final double margin;
  final ValueChanged<TripSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    List<TripSummary> inPhase(TripPhase? phase) => [
      for (final trip in trips)
        if (trip.phaseOn(today) == phase) trip,
    ];
    // Upcoming trips: the nearest first. Past trips: the latest first.
    final upcoming = inPhase(TripPhase.upcoming)
      ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
    final past = inPhase(TripPhase.past)
      ..sort((a, b) => b.startDate!.compareTo(a.startDate!));
    final groups = [
      (l10n.tripsCurrent, inPhase(TripPhase.current)),
      (l10n.tripsUpcoming, upcoming),
      (l10n.tripsUndated, inPhase(null)),
      (l10n.tripsPast, past),
    ];

    String when(TripSummary trip) => switch ((trip.startDate, trip.endDate)) {
      (final start?, final end?) => l10n.tripDateRange(
        dates.format(start.toDateTime()),
        dates.format(end.toDateTime()),
      ),
      _ => l10n.tripDatesToDecide(trip.dayCount),
    };

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      children: [
        for (final (title, group) in groups)
          if (group.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(margin, 16, margin, 4),
              child: Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.labelSmall),
              ),
            ),
            for (final trip in group)
              ListTile(
                key: Key('trip-${trip.id.value}'),
                contentPadding: EdgeInsets.symmetric(horizontal: margin),
                title: Text(trip.name),
                subtitle: Text(
                  [
                    when(trip),
                    if (trip.destinations.isNotEmpty)
                      trip.destinations.join(', '),
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpen(trip),
              ),
          ],
      ],
    );
  }
}

/// An icon, a sentence that says what is missing and one action: the shape
/// of every empty or failed state (PRD 7.7).
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.actionKey,
    required this.onAction,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              if (body case final body?) ...[
                const SizedBox(height: 8),
                Text(body, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: actionKey,
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
