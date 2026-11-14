// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

/// Colours of the approved style that Material has no slot for
/// (docs/DESIGN.md, section 2).
class ItinereaColors extends ThemeExtension<ItinereaColors> {
  /// Creates the extra colours of one theme.
  const ItinereaColors({
    required this.route,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.offline,
    required this.done,
  });

  /// Active route on the map.
  final Color route;

  /// Warnings on a plain surface: tight times, closures, delays.
  final Color warning;

  /// Background of a warning band.
  final Color warningContainer;

  /// Text on a warning band.
  final Color onWarningContainer;

  /// Data shown from a saved copy: "Offline – updated on…".
  final Color offline;

  /// Something done: a visited stop, a settled expense.
  final Color done;

  /// Extra colours of the light theme.
  static const ItinereaColors light = ItinereaColors(
    route: Color(0xFFC2255C),
    warning: Color(0xFF9A4F00),
    warningContainer: Color(0xFFFFE9CC),
    onWarningContainer: Color(0xFF6B3600),
    offline: Color(0xFF3F5B74),
    done: Color(0xFF23703F),
  );

  /// Extra colours of the dark theme.
  static const ItinereaColors dark = ItinereaColors(
    route: Color(0xFFFF7AA8),
    warning: Color(0xFFFFB95C),
    warningContainer: Color(0xFF4A2E00),
    onWarningContainer: Color(0xFFFFDDB0),
    offline: Color(0xFF9DBAD3),
    done: Color(0xFF86D6A2),
  );

  /// The extra colours of the theme in use.
  static ItinereaColors of(BuildContext context) =>
      Theme.of(context).extension<ItinereaColors>()!;

  @override
  ItinereaColors copyWith({
    Color? route,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? offline,
    Color? done,
  }) => ItinereaColors(
    route: route ?? this.route,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    offline: offline ?? this.offline,
    done: done ?? this.done,
  );

  @override
  ItinereaColors lerp(ItinereaColors? other, double t) => other == null
      ? this
      : ItinereaColors(
          route: Color.lerp(route, other.route, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          warningContainer: Color.lerp(
            warningContainer,
            other.warningContainer,
            t,
          )!,
          onWarningContainer: Color.lerp(
            onWarningContainer,
            other.onWarningContainer,
            t,
          )!,
          offline: Color.lerp(offline, other.offline, t)!,
          done: Color.lerp(done, other.done, t)!,
        );
}

/// The style approved on 2026-11-14 (docs/DESIGN.md): one teal accent on
/// neutral surfaces, thin borders instead of shadows, Inter for text and
/// numbers, Manrope for titles.
abstract final class AppTheme {
  /// Font of text, numbers and labels. Bundled with the app.
  static const String textFont = 'Inter';

  /// Font of titles. Bundled with the app.
  static const String titleFont = 'Manrope';

  /// Side margin on phones.
  static const double marginCompact = 16;

  /// Side margin on tablets and desktops.
  static const double marginWide = 24;

  /// Smallest height of a row that can be tapped.
  static const double minRowHeight = 56;

  /// Corner radius of chips and fields.
  static const double radiusSmall = 8;

  /// Corner radius of panels, cards and buttons.
  static const double radiusMedium = 12;

  /// Style of times and amounts: digits of equal width, so that columns of
  /// numbers line up.
  static TextStyle numbers(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation.weight(600)],
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Theme used when the app is in light mode.
  static ThemeData get light => _build(
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0B6E63),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD5EEE9),
      onPrimaryContainer: Color(0xFF0A4F47),
      secondary: Color(0xFF0B6E63),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFD5EEE9),
      onSecondaryContainer: Color(0xFF0A4F47),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF14201D),
      onSurfaceVariant: Color(0xFF55645F),
      surfaceContainerHighest: Color(0xFFEEF2F0),
      surfaceContainerHigh: Color(0xFFEEF2F0),
      surfaceContainer: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFFFFFFF),
      outline: Color(0xFF7F8F8A),
      outlineVariant: Color(0xFFDCE3E0),
    ),
    background: const Color(0xFFF6F8F7),
    extra: ItinereaColors.light,
  );

  /// Theme used when the app is in dark mode.
  static ThemeData get dark => _build(
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF6FD6C6),
      onPrimary: Color(0xFF00382F),
      primaryContainer: Color(0xFF12403A),
      onPrimaryContainer: Color(0xFFB5ECE2),
      secondary: Color(0xFF6FD6C6),
      onSecondary: Color(0xFF00382F),
      secondaryContainer: Color(0xFF12403A),
      onSecondaryContainer: Color(0xFFB5ECE2),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: Color(0xFF182120),
      onSurface: Color(0xFFE6EEEB),
      onSurfaceVariant: Color(0xFF9FB0AA),
      surfaceContainerHighest: Color(0xFF212C2A),
      surfaceContainerHigh: Color(0xFF212C2A),
      surfaceContainer: Color(0xFF182120),
      surfaceContainerLow: Color(0xFF182120),
      outline: Color(0xFF70807B),
      outlineVariant: Color(0xFF2B3735),
    ),
    background: const Color(0xFF0F1513),
    extra: ItinereaColors.dark,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required ItinereaColors extra,
  }) {
    final text = _textTheme(scheme);
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: textFont,
      textTheme: text,
      extensions: [extra],
      // Borders instead of shadows: fewer layers, faster on mid-range phones.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: rounded,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: rounded,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: rounded,
          textStyle: text.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(textStyle: text.labelLarge),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        side: BorderSide(color: scheme.outline),
        labelStyle: text.labelMedium,
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: minRowHeight,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: scheme.onSurfaceVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const CircleBorder(),
      ),
    );
  }

  /// The type scale of docs/DESIGN.md, section 3.
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle style(
      String family,
      double size,
      double lineHeight,
      int weight, {
      Color? color,
    }) => TextStyle(
      fontFamily: family,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: FontWeight.values[weight ~/ 100 - 1],
      // The fonts are variable: the weight is an axis of the file.
      fontVariations: [FontVariation.weight(weight.toDouble())],
      color: color ?? scheme.onSurface,
      letterSpacing: 0,
    );

    final muted = scheme.onSurfaceVariant;
    return TextTheme(
      // Trip title.
      headlineSmall: style(titleFont, 24, 30, 700),
      // Day heading, screen titles.
      titleLarge: style(titleFont, 20, 26, 700),
      // Panel title.
      titleMedium: style(titleFont, 17, 24, 600),
      // Stop name.
      titleSmall: style(textFont, 16, 22, 600),
      // Text.
      bodyLarge: style(textFont, 15, 22, 400),
      bodyMedium: style(textFont, 15, 22, 400),
      // Secondary text: durations, notes.
      bodySmall: style(textFont, 13, 18, 400, color: muted),
      // Buttons.
      labelLarge: style(textFont, 15, 22, 600),
      // Labels: chips, "Estimate".
      labelMedium: style(textFont, 12, 16, 500),
      labelSmall: style(textFont, 12, 16, 500, color: muted),
    );
  }
}
