// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/scaffold_placeholder.dart';
import '../../l10n/generated/app_localizations.dart';
import '../assistant/assistant_screen.dart';
import '../bookings/bookings_screen.dart';
import '../bookings/new_booking_screen.dart';
import '../bookings/ticket_screen.dart';
import '../budget/budget_screen.dart';
import '../budget/new_expense_screen.dart';
import '../day/day_screen.dart';
import '../day/stop_details_screen.dart';
import '../explore/explore_screen.dart';
import '../map/map_screen.dart';
import '../notifications/notifications_screen.dart';
import '../offline/offline_maps_screen.dart';
import '../participants/participants_screen.dart';
import '../profile/profile_screen.dart';
import '../routes/edit_route_screen.dart';
import '../routes/leg_details_screen.dart';
import '../settings/data_sources_screen.dart';
import '../trips/new_trip_screen.dart';
import '../vehicle/vehicle_screen.dart';

/// One placeholder screen of the scaffolding.
class ScaffoldEntry {
  /// Creates an entry.
  const ScaffoldEntry({
    required this.code,
    required this.title,
    required this.target,
    required this.builder,
  });

  /// Code of the screen in PRD 7.3.
  final String code;

  /// Translated name of the screen.
  final String Function(AppLocalizations l10n) title;

  /// Milestone or phase in which the screen becomes real.
  final ScaffoldTarget target;

  /// Builds the placeholder screen.
  final WidgetBuilder builder;
}

/// The screens of PRD 7.3 that are still placeholders, in order. A screen
/// leaves this list when its real version exists: S01 (home) and S20
/// (settings, in a minimal form) left it with milestone M3.
final List<ScaffoldEntry> scaffoldEntries = [
  ScaffoldEntry(
    code: 'S02',
    title: (l10n) => l10n.screenNewTrip,
    target: const ScaffoldTarget.milestone('M3'),
    builder: (_) => const NewTripScreen(),
  ),
  ScaffoldEntry(
    code: 'S03',
    title: (l10n) => l10n.screenDay,
    target: const ScaffoldTarget.milestone('M3'),
    builder: (_) => const DayScreen(),
  ),
  ScaffoldEntry(
    code: 'S04',
    title: (l10n) => l10n.screenStopDetails,
    target: const ScaffoldTarget.milestone('M3'),
    builder: (_) => const StopDetailsScreen(),
  ),
  ScaffoldEntry(
    code: 'S05',
    title: (l10n) => l10n.screenLegDetails,
    target: const ScaffoldTarget.milestone('M4'),
    builder: (_) => const LegDetailsScreen(),
  ),
  ScaffoldEntry(
    code: 'S06',
    title: (l10n) => l10n.screenMap,
    target: const ScaffoldTarget.milestone('M4'),
    builder: (_) => const MapScreen(),
  ),
  ScaffoldEntry(
    code: 'S07',
    title: (l10n) => l10n.screenEditRoute,
    target: const ScaffoldTarget.milestone('M4'),
    builder: (_) => const EditRouteScreen(),
  ),
  ScaffoldEntry(
    code: 'S08',
    title: (l10n) => l10n.screenBudget,
    target: const ScaffoldTarget.milestone('M5'),
    builder: (_) => const BudgetScreen(),
  ),
  ScaffoldEntry(
    code: 'S09',
    title: (l10n) => l10n.screenNewExpense,
    target: const ScaffoldTarget.milestone('M5'),
    builder: (_) => const NewExpenseScreen(),
  ),
  ScaffoldEntry(
    code: 'S10',
    title: (l10n) => l10n.screenBookings,
    target: const ScaffoldTarget.milestone('M5'),
    builder: (_) => const BookingsScreen(),
  ),
  ScaffoldEntry(
    code: 'S11',
    title: (l10n) => l10n.screenTicket,
    target: const ScaffoldTarget.milestone('M5'),
    builder: (_) => const TicketScreen(),
  ),
  ScaffoldEntry(
    code: 'S12',
    title: (l10n) => l10n.screenNewBooking,
    target: const ScaffoldTarget.milestone('M5'),
    builder: (_) => const NewBookingScreen(),
  ),
  ScaffoldEntry(
    code: 'S13',
    title: (l10n) => l10n.screenParticipants,
    target: const ScaffoldTarget.phase(2),
    builder: (_) => const ParticipantsScreen(),
  ),
  ScaffoldEntry(
    code: 'S14',
    title: (l10n) => l10n.screenVehicle,
    target: const ScaffoldTarget.phase(2),
    builder: (_) => const VehicleScreen(),
  ),
  ScaffoldEntry(
    code: 'S15',
    title: (l10n) => l10n.screenOfflineMaps,
    target: const ScaffoldTarget.phase(2),
    builder: (_) => const OfflineMapsScreen(),
  ),
  ScaffoldEntry(
    code: 'S16',
    title: (l10n) => l10n.screenNotifications,
    target: const ScaffoldTarget.phase(2),
    builder: (_) => const NotificationsScreen(),
  ),
  ScaffoldEntry(
    code: 'S17',
    title: (l10n) => l10n.screenAssistant,
    target: const ScaffoldTarget.phase(3),
    builder: (_) => const AssistantScreen(),
  ),
  ScaffoldEntry(
    code: 'S18',
    title: (l10n) => l10n.screenProfile,
    target: const ScaffoldTarget.phase(4),
    builder: (_) => const ProfileScreen(),
  ),
  ScaffoldEntry(
    code: 'S19',
    title: (l10n) => l10n.screenExplore,
    target: const ScaffoldTarget.phase(4),
    builder: (_) => const ExploreScreen(),
  ),
  ScaffoldEntry(
    code: 'S21',
    title: (l10n) => l10n.screenDataSources,
    target: const ScaffoldTarget.milestone('M6'),
    builder: (_) => const DataSourcesScreen(),
  ),
];
