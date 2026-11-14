// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The fonts bundled with the app and the file with the licence of each
/// (SIL Open Font License 1.1). The files sit next to the fonts in
/// assets/fonts/ and are listed in LICENSE-DATA.md.
const Map<String, String> bundledFontLicenses = {
  'Inter': 'assets/fonts/Inter-OFL.txt',
  'Manrope': 'assets/fonts/Manrope-OFL.txt',
};

/// Adds the licences of the bundled fonts to the licences page of the app.
/// Called once, before the app starts.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: font, value: asset)
        in bundledFontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString(asset));
    }
  });
}
