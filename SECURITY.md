# Security Policy

## Reporting a vulnerability

**Please do not report security problems in public issues, discussions or pull requests.**

Use GitHub's private vulnerability reporting instead:

1. Open the [Security tab](https://github.com/NotEnjoyingThis/itinerea/security) of the repository.
2. Click **Report a vulnerability**.
3. Describe the problem, how to reproduce it, the affected platform and version (or commit), and the impact you expect.

The report is visible only to you and to the maintainers. You will get an answer there, and the fix and its disclosure will be coordinated with you in the same place.

Please do not include real personal data (bookings, tickets, tokens) in a report: use made-up samples.

## Supported versions

Itinerea is in development and has no released version yet. Until the first release, fixes land on the `main` branch only. After that, the latest released version will be supported.

## Scope

In scope: the app in `app/`, the self-hosted sync server in `sync-server/`, the scripts in `data-packs/` and the workflows in `.github/`.

Out of scope: third-party services the app can talk to (map, routing, search, weather, cloud storage providers…). Report problems in those services to their own maintainers.
