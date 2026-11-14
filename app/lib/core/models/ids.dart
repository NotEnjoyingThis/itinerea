// SPDX-License-Identifier: GPL-3.0-or-later

/// Identifier of an entity (PRD 8.1): a UUID v7 created on the device.
// TODO(M2): generate UUID v7 values and validate the format.
extension type const EntityId(String value) {}

/// A hybrid logical clock value, as written in sync operations (PRD 8.6).
// TODO(M2): parse, compare and advance HLC values.
extension type const Hlc(String value) {}
