// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';

/// The three layouts of the app (docs/DESIGN.md, section 7; PRD T8).
enum WindowSize {
  /// Phones: one column.
  compact,

  /// Tablets and narrow windows: list and map side by side.
  medium,

  /// Desktops: days, day and map side by side.
  expanded;

  /// Widths from which the medium and the expanded layouts apply.
  static const double mediumFrom = 600;

  /// Width from which the expanded layout applies.
  static const double expandedFrom = 1024;

  /// The layout for a window [width] logical pixels wide.
  static WindowSize forWidth(double width) => width >= expandedFrom
      ? WindowSize.expanded
      : (width >= mediumFrom ? WindowSize.medium : WindowSize.compact);

  /// The layout for the window that contains [context].
  static WindowSize of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  /// Side margin of the content in this layout.
  double get margin =>
      this == WindowSize.compact ? AppTheme.marginCompact : AppTheme.marginWide;
}
