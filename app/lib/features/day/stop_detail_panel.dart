// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/ids.dart';
import '../../core/models/money.dart';
import '../../core/models/money_text.dart';
import '../../core/models/place.dart';
import '../../core/models/stop.dart';
import '../../core/models/web_address.dart';
import '../../core/net/http_transport.dart';
import '../../core/providers/service_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../trips/trip_providers.dart';
import 'place_details_actions.dart';
import 'stop_repository.dart';

/// A duration in words: "45 min", "2 h", "1 h 30 min".
String formatDuration(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l10n.durationMinutes(rest);
  if (rest == 0) return l10n.durationHours(hours);
  return l10n.durationHoursMinutes(hours, rest);
}

/// Details of a stop (S04): name, duration, status, opening hours and
/// contacts of its place, estimated cost, note and links, each saved as soon
/// as it changes; and the actions on the stop.
///
/// Shown as a panel from the bottom on phones and beside the day on wide
/// screens (PRD 7.1).
// TODO(M3 F1.3): start time and the lock that fixes it.
// TODO(M3 F1.6): plans A-D.
// TODO(M5 F1.8): attachments.
class StopDetailPanel extends ConsumerWidget {
  /// Creates the details of the stop at [slotId] of [dayId].
  const StopDetailPanel({
    required this.tripId,
    required this.dayId,
    required this.slotId,
    required this.currency,
    required this.onClose,
    required this.onMove,
    required this.onDelete,
    super.key,
  });

  /// Trip the stop belongs to.
  final EntityId tripId;

  /// Day the stop is in.
  final EntityId dayId;

  /// Position of the stop.
  final EntityId slotId;

  /// ISO 4217 code of the currency of the trip, for the estimated cost.
  final String currency;

  /// Closes the panel.
  final VoidCallback onClose;

  /// Asks to move the stop to another day.
  final ValueChanged<DayStop> onMove;

  /// Asks to delete the stop.
  final ValueChanged<DayStop> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stop = ref
        .watch(dayStopsProvider(dayId))
        .value
        ?.where((candidate) => candidate.slotId == slotId)
        .firstOrNull;
    // The stop was deleted or moved to another day: nothing to show.
    if (stop == null) return const SizedBox.shrink();

    // Taken now, not when the change is saved: a field also saves when it
    // loses the focus, which happens while the panel is being closed, and
    // by then this widget may be gone.
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);

    Future<void> change(
      Future<void> Function(StopRepository stops) action,
    ) async {
      try {
        await action(await container.read(stopRepositoryProvider.future));
      } on Exception {
        messenger.showSnackBar(SnackBar(content: Text(l10n.changeError)));
      }
      container.invalidate(dayStopsProvider(dayId));
    }

    final digits =
        NumberFormat.simpleCurrency(name: currency).decimalDigits ?? 2;

    return SingleChildScrollView(
      key: Key('stopDetail-${slotId.value}'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(stop.name, style: theme.textTheme.titleMedium),
                ),
              ),
              IconButton(
                key: const Key('closeStopDetail'),
                tooltip: l10n.actionClose,
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (stop.place?.address case final String address)
            Text(
              address,
              key: const Key('stopAddress'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          _CommitField(
            key: const Key('stopName'),
            label: l10n.stopNameLabel,
            value: stop.name,
            capitalization: TextCapitalization.sentences,
            validate: (text) =>
                text.trim().isEmpty ? l10n.stopNameMissing : null,
            onCommit: (text) =>
                change((stops) => stops.rename(stop.stopId, text)),
          ),
          const SizedBox(height: 20),
          Text(l10n.stopDuration, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton.outlined(
                key: const Key('stopShorter'),
                tooltip: l10n.stopShorter,
                onPressed: stop.durationMin >= 15
                    ? () => change(
                        (stops) => stops.setDuration(
                          stop.stopId,
                          stop.durationMin - 15,
                        ),
                      )
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  formatDuration(l10n, stop.durationMin),
                  key: const Key('stopDurationValue'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton.outlined(
                key: const Key('stopLonger'),
                tooltip: l10n.stopLonger,
                onPressed:
                    stop.durationMin + 15 <= StopRepository.maxDurationMin
                    ? () => change(
                        (stops) => stops.setDuration(
                          stop.stopId,
                          stop.durationMin + 15,
                        ),
                      )
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.stopStatus, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (status, label) in [
                (StopStatus.planned, l10n.stopStatusPlanned),
                (StopStatus.visited, l10n.stopStatusVisited),
                (StopStatus.skipped, l10n.stopStatusSkipped),
              ])
                ChoiceChip(
                  key: Key('stopStatus-${status.name}'),
                  label: Text(label),
                  selected: stop.status == status,
                  showCheckmark: false,
                  onSelected: (_) =>
                      change((stops) => stops.setStatus(stop.stopId, status)),
                ),
            ],
          ),
          if (stop.place case final PlaceSnapshot place) ...[
            const SizedBox(height: 20),
            _PlaceInfo(stop: stop, place: place, change: change),
          ],
          const SizedBox(height: 20),
          _CommitField(
            key: const Key('stopCost'),
            label: l10n.stopCost,
            suffix: currency,
            // Honest about what the number is (PRD T4, F1.6).
            helper: l10n.stopCostEstimateNote,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            formatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
            value: switch (stop.estimatedCost) {
              final Money cost => MoneyText.format(
                cost.amountMinor,
                decimalDigits: digits,
                separator: NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toString(),
                ).symbols.DECIMAL_SEP,
              ),
              null => '',
            },
            validate: (text) =>
                text.trim().isEmpty ||
                    MoneyText.parse(text, decimalDigits: digits) != null
                ? null
                : l10n.stopCostInvalid,
            onCommit: (text) => change(
              (stops) => stops.setEstimatedCost(
                stop.stopId,
                switch (MoneyText.parse(text, decimalDigits: digits)) {
                  final int amount => Money(
                    amountMinor: amount,
                    currency: currency,
                  ),
                  null => null,
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _CommitField(
            key: const Key('stopNote'),
            label: l10n.stopNote,
            value: stop.note,
            lines: 3,
            capitalization: TextCapitalization.sentences,
            onCommit: (text) => change(
              (stops) => stops.setNote(
                tripId: tripId,
                stopId: stop.stopId,
                text: text,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.stopLinks, style: theme.textTheme.labelSmall),
          for (final link in stop.links)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.link_rounded),
              title: SelectableText(link.toString()),
              trailing: IconButton(
                tooltip: l10n.stopLinkRemove,
                onPressed: () => change(
                  (stops) => stops.setLinks(stop.stopId, [
                    for (final other in stop.links)
                      if (other != link) other,
                  ]),
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          const SizedBox(height: 4),
          _CommitField(
            key: const Key('stopLinkAdd'),
            label: l10n.stopLinkAdd,
            value: '',
            clearOnCommit: true,
            keyboard: TextInputType.url,
            validate: (text) =>
                text.trim().isEmpty || parseWebAddress(text) != null
                ? null
                : l10n.stopLinkInvalid,
            onCommit: (text) async {
              final link = parseWebAddress(text);
              if (link == null || stop.links.contains(link)) return;
              await change(
                (stops) => stops.setLinks(stop.stopId, [...stop.links, link]),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.start,
            children: [
              TextButton.icon(
                key: const Key('stopMove'),
                onPressed: () => onMove(stop),
                icon: const Icon(Icons.drive_file_move_outline),
                label: Text(l10n.stopMoveToDay),
              ),
              TextButton.icon(
                key: const Key('stopDelete'),
                onPressed: () => onDelete(stop),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.actionDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opening hours, phone and website of the place of a stop (F1.2), with
/// where they come from and when they were downloaded (PRD T4). The user
/// can change them; a new download keeps what the user wrote.
class _PlaceInfo extends ConsumerStatefulWidget {
  const _PlaceInfo({
    required this.stop,
    required this.place,
    required this.change,
  });

  final DayStop stop;
  final PlaceSnapshot place;
  final Future<void> Function(
    Future<void> Function(StopRepository stops) action,
  )
  change;

  @override
  ConsumerState<_PlaceInfo> createState() => _PlaceInfoState();
}

class _PlaceInfoState extends ConsumerState<_PlaceInfo> {
  bool _loading = false;
  ServiceFailureKind? _failure;

  Future<void> _refresh(String osmId) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _loading = true;
      _failure = null;
    });
    ServiceFailureKind? failure;
    try {
      await fillPlaceDetails(
        container,
        slotId: widget.stop.slotId,
        osmId: osmId,
        language: language,
        refresh: true,
      );
    } on ServiceFailure catch (error) {
      failure = error.kind;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stop = widget.stop;
    final place = widget.place;
    final osmId = place.osmId;
    final lookup = ref.watch(placeDetailsLookupProvider).value;
    final known = osmId == null
        ? null
        : ref.watch(cachedPlaceDetailsProvider(osmId)).value;
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    String? source;
    if (known != null && lookup != null) {
      final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
          .format(known.fetchedAt.toLocal());
      source = lookup.isOld(known)
          ? l10n.placeDetailsUpdatedOld(date)
          : l10n.placeDetailsUpdated(date);
    }
    final message = switch (_failure) {
      ServiceFailureKind.noConnection => l10n.placeDetailsOffline,
      ServiceFailureKind.busy => l10n.placeDetailsBusy,
      ServiceFailureKind.badResponse => l10n.placeDetailsFailed,
      null => null,
    };
    final limit = [
      LengthLimitingTextInputFormatter(StopRepository.maxPlaceTextLength),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.placeInfoTitle, style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        _CommitField(
          key: const Key('stopOpeningHours'),
          label: l10n.placeOpeningHours,
          // The text as it is: reading it comes with the warnings (F1.3).
          helper: l10n.placeOpeningHoursHelp,
          value: place.openingHours ?? '',
          lines: 2,
          formatters: limit,
          onCommit: (text) => widget.change(
            (stops) => stops.setOpeningHours(stop.stopId, text),
          ),
        ),
        const SizedBox(height: 12),
        _CommitField(
          key: const Key('stopPhone'),
          label: l10n.placePhone,
          value: place.phone ?? '',
          keyboard: TextInputType.phone,
          formatters: limit,
          onCommit: (text) =>
              widget.change((stops) => stops.setPhone(stop.stopId, text)),
        ),
        const SizedBox(height: 12),
        _CommitField(
          key: const Key('stopWebsite'),
          label: l10n.placeWebsite,
          value: place.website ?? '',
          keyboard: TextInputType.url,
          formatters: limit,
          validate: (text) =>
              text.trim().isEmpty || parseWebAddress(text) != null
              ? null
              : l10n.stopLinkInvalid,
          onCommit: (text) =>
              widget.change((stops) => stops.setWebsite(stop.stopId, text)),
        ),
        if (osmId != null) ...[
          const SizedBox(height: 8),
          if (source != null)
            Text(source, key: const Key('placeDetailsSource'), style: quiet),
          if (message != null)
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                key: const Key('placeDetailsMessage'),
                style: quiet,
              ),
            ),
          // Downloaded less than a day ago: asking again is not offered, the
          // date above says why (PRD 5.6, repeated queries).
          if (_loading || (lookup?.canRefresh(known) ?? false))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('placeDetailsRefresh'),
                onPressed: _loading ? null : () => _refresh(osmId),
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(l10n.placeDetailsRefresh),
              ),
            )
          else
            const SizedBox(height: 8),
          Text(
            l10n.osmAttribution,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// A text field that saves when the user is done with it: on "done" on the
/// keyboard or when the field loses the focus, and only if the text changed
/// and is valid.
class _CommitField extends StatefulWidget {
  const _CommitField({
    required this.label,
    required this.value,
    required this.onCommit,
    this.validate,
    this.helper,
    this.suffix,
    this.lines = 1,
    this.keyboard,
    this.formatters,
    this.capitalization = TextCapitalization.none,
    this.clearOnCommit = false,
    super.key,
  });

  final String label;
  final String value;
  final Future<void> Function(String text) onCommit;
  final String? Function(String text)? validate;
  final String? helper;
  final String? suffix;
  final int lines;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization capitalization;
  final bool clearOnCommit;

  @override
  State<_CommitField> createState() => _CommitFieldState();
}

class _CommitFieldState extends State<_CommitField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChange);
  String? _error;
  // Text being saved: "done" on the keyboard and the loss of focus that
  // follows it must not save it twice.
  String? _saving;

  @override
  void didUpdateWidget(_CommitField old) {
    super.didUpdateWidget(old);
    // A change that arrived from elsewhere (another device, an undo) shows
    // up, unless the user is typing here.
    if (widget.value == old.value) return;
    // The text being saved has arrived: nothing is pending any more.
    if (widget.value == _saving) _saving = null;
    if (!_focus.hasFocus) {
      _controller.text = widget.value;
      _saving = null;
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) unawaited(_commit());
  }

  Future<void> _commit() async {
    final text = _controller.text;
    final error = widget.validate?.call(text);
    if (mounted) setState(() => _error = error);
    if (error != null || text == widget.value || text == _saving) return;
    _saving = text;
    if (widget.clearOnCommit) _controller.clear();
    await widget.onCommit(text);
    // A field that empties itself (a new link) may save the same text again.
    if (widget.clearOnCommit) _saving = null;
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focus,
    minLines: widget.lines,
    maxLines: widget.lines == 1 ? 1 : 8,
    keyboardType: widget.keyboard,
    inputFormatters: widget.formatters,
    textCapitalization: widget.capitalization,
    textInputAction: widget.lines == 1
        ? TextInputAction.done
        : TextInputAction.newline,
    decoration: InputDecoration(
      labelText: widget.label,
      helperText: widget.helper,
      helperMaxLines: 2,
      suffixText: widget.suffix,
      errorText: _error,
      border: const OutlineInputBorder(),
    ),
    onSubmitted: (_) => _commit(),
  );
}
