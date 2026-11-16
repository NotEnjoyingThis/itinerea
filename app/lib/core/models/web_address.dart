// SPDX-License-Identifier: GPL-3.0-or-later

/// Reads a web address written by a person or found in OpenStreetMap:
/// "www.uffizi.it" becomes https://www.uffizi.it.
///
/// Returns null for anything that is not an http or https address with a
/// host name, and for addresses with a user name in them: a link must never
/// open something other than a web page, nor hide where it goes (PRD 13).
Uri? parseWebAddress(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.contains(RegExp(r'\s'))) return null;
  final uri = Uri.tryParse(
    trimmed.contains('://') ? trimmed : 'https://$trimmed',
  );
  if (uri == null ||
      !uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      !uri.host.contains('.')) {
    return null;
  }
  return uri.scheme == 'http' || uri.scheme == 'https' ? uri : null;
}
