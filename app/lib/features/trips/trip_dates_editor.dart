// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/time.dart';
import '../../core/time/timezones.dart';
import '../../l10n/generated/app_localizations.dart';
import 'trip_plan.dart';

/// When a trip happens: its first and last day, or only how many days it
/// lasts while the dates are not decided (F1.1).
class TripDates {
  /// Creates the dates of a trip.
  const TripDates({
    this.hasDates = true,
    this.start,
    this.end,
    this.dayCount = 3,
  });

  /// The dates of a trip that already exists.
  factory TripDates.of({required LocalDate? start, required int dayCount}) =>
      TripDates(
        hasDates: start != null,
        start: start,
        end: start?.addDays(dayCount - 1),
        dayCount: dayCount,
      );

  /// True if the user wants to give dates; false for a number of days only.
  final bool hasDates;

  /// First day, when chosen.
  final LocalDate? start;

  /// Last day, when chosen.
  final LocalDate? end;

  /// Number of days, used when [hasDates] is false.
  final int dayCount;

  /// True if dates are wanted but not both chosen yet.
  bool get isIncomplete => hasDates && (start == null || end == null);

  /// First day of the trip, or null for a trip without dates.
  LocalDate? get startDate => hasDates ? start : null;

  /// Length of the trip in days. Only meaningful when not [isIncomplete].
  int get length => hasDates && start != null && end != null
      ? TripDays.countBetween(start!, end!)
      : dayCount;

  TripDates _with({
    bool? hasDates,
    LocalDate? start,
    LocalDate? end,
    int? dayCount,
  }) => TripDates(
    hasDates: hasDates ?? this.hasDates,
    start: start ?? this.start,
    end: end ?? this.end,
    dayCount: dayCount ?? this.dayCount,
  );
}

/// Lets the user choose the dates of a trip, or only its number of days.
/// Used when a trip is created and when its dates are changed.
class TripDatesEditor extends ConsumerWidget {
  /// Creates the editor.
  const TripDatesEditor({
    required this.value,
    required this.onChanged,
    this.showProblems = false,
    super.key,
  });

  /// Current choice.
  final TripDates value;

  /// Called with the new choice.
  final ValueChanged<TripDates> onChanged;

  /// True to show what is missing: only after the user tried to go on.
  final bool showProblems;

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref, {
    required bool start,
  }) async {
    final today = ref.read(todayProvider)();
    final current = start ? value.start : value.end;
    final first = start ? today.addDays(-365) : (value.start ?? today);
    final picked = await showDatePicker(
      context: context,
      initialDate: (current ?? value.start ?? today).toDateTime(),
      firstDate: first.toDateTime(),
      lastDate: (start ? today.addDays(3650) : first.addDays(364)).toDateTime(),
    );
    if (picked == null) return;
    final date = LocalDate.of(picked);
    if (!start) return onChanged(value._with(end: date));
    // The end never comes before the start, nor more than a year after it.
    final end = value.end;
    final keepEnd =
        end != null &&
        end.compareTo(date) >= 0 &&
        date.daysUntil(end) < TripDraft.maxDays;
    onChanged(value._with(start: date, end: keepEnd ? end : date));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    String label(LocalDate? date) => date == null
        ? l10n.tripDateChoose
        : DateFormat.yMMMEd(locale).format(date.toDateTime());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chips, not a segmented button: they wrap on a narrow screen with
        // large text.
        Wrap(
          key: const Key('datesSelector'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (hasDates, text) in [
              (true, l10n.tripDatesKnown),
              (false, l10n.tripDatesUnknown),
            ])
              ChoiceChip(
                label: Text(text),
                selected: value.hasDates == hasDates,
                showCheckmark: false,
                onSelected: (_) => onChanged(value._with(hasDates: hasDates)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (value.hasDates) ...[
          ListTile(
            key: const Key('tripStartDate'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded),
            title: Text(l10n.tripStartDate),
            subtitle: Text(label(value.start)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pick(context, ref, start: true),
          ),
          ListTile(
            key: const Key('tripEndDate'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_rounded),
            title: Text(l10n.tripEndDate),
            subtitle: Text(label(value.end)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pick(context, ref, start: false),
          ),
          if (!value.isIncomplete)
            Text(
              l10n.tripDayCount(value.length),
              key: const Key('tripLength'),
              style: theme.textTheme.bodySmall,
            )
          else if (showProblems)
            Text(
              l10n.tripDatesMissing,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ] else ...[
          Text(l10n.tripDayCountLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                key: const Key('fewerDays'),
                tooltip: l10n.tripFewerDays,
                onPressed: value.dayCount > 1
                    ? () => onChanged(value._with(dayCount: value.dayCount - 1))
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  l10n.tripDayCount(value.dayCount),
                  key: const Key('tripLength'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton.outlined(
                key: const Key('moreDays'),
                tooltip: l10n.tripMoreDays,
                onPressed: value.dayCount < TripDraft.maxDays
                    ? () => onChanged(value._with(dayCount: value.dayCount + 1))
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.tripDatesLater, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
