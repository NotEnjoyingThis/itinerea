# Contributing to Itinerea

Thank you for your interest in Itinerea. The project is developed in the open and every kind of help is welcome: code, translations, data and artwork.

Please read the [Code of Conduct](CODE_OF_CONDUCT.md) first. The reference document for the product is [`docs/PRD.md`](docs/PRD.md) (in Italian).

## Ground rules

These principles are not negotiable (PRD 1.4 and 1.5). Contributions that break them cannot be merged:

- **No central server, no Itinerea accounts, no telemetry**, analytics, automatic crash reporting, ads, in-app purchases or affiliate links.
- **No proprietary SDKs** (Firebase, Google Play Services, ad SDKs…): the app must stay eligible for F-Droid.
- **Local-first:** every feature works offline with saved data, or degrades in a clear way.
- **Honest data:** estimates and stale data are always labelled as such.

## Developer Certificate of Origin (DCO)

Itinerea does not use a contributor licence agreement. Instead, every commit must be signed off to certify that you wrote it or otherwise have the right to submit it under the project licence, as stated in the [Developer Certificate of Origin 1.1](https://developercertificate.org/).

Add the sign-off with the `-s` flag:

```sh
git commit -s -m "feat(F1.2): reorder stops by dragging"
```

This appends a line like `Signed-off-by: Your Name <you@example.com>` to the commit message. Use a name and an address you are happy to make public (a GitHub `noreply` address is fine).

## Code

1. **Open an issue first** for anything larger than a small fix, so the approach can be agreed before you write code. The project follows the milestones in PRD section 15, in order: features of later phases are not accepted early.
2. **Branch** from `main`, one branch per feature or task, e.g. `feat/F1.2-stops`.
3. **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/) and carry the feature code from the PRD when there is one: `feat(F1.3): automatic schedule recalculation`.
4. **Before opening a pull request**, from the `app/` folder:

   ```sh
   flutter pub get
   dart run tool/generate.dart
   dart format .
   flutter analyze
   dart run tool/check_spdx.dart
   flutter test
   ```

   `dart run tool/generate.dart` creates the files that are not committed: translations, the drift database code (`*.g.dart`) and the helpers of the migration tests. Run it again after changing an ARB file or a database table.

   `flutter analyze` must report no errors, warnings or infos. Do not disable or delete a failing test to make CI pass: report the problem instead.
5. **Pull requests** explain what changed and why, and tick the checklist in the template. CI builds the app for Android, Windows, macOS, Linux and (unsigned) iOS.

### Conventions

- Names, comments and commit messages are in **English**. Documents in `docs/` are in Italian.
- Every new source file starts with `// SPDX-License-Identifier: GPL-3.0-or-later`.
- Structure: `app/lib/core/` (models, database, sync, providers, utilities) and `app/lib/features/<feature>/`. No domain logic inside widgets.
- Use the glossary names from PRD section 3 (`Trip`, `Day`, `Stop`, `Leg`, `Booking`…).
- Money is always a `Money` value (integer minor units + ISO 4217 code), never a `double`.
- No user-visible string in the code: every text goes in the ARB files (see below).
- Pure logic needs unit tests; every bug fix comes with a test that reproduces the bug.
- No keys, tokens or other secrets in the repository.

### Database changes

The app has two SQLite databases, written with [drift](https://drift.simonbinder.eu/): one for trips and personal data, one for the cache. Each version of a schema has a snapshot committed in `app/drift_schemas/`, and the tests check the real schema against it.

When you change a table of `app/lib/core/database/`:

1. raise `currentSchemaVersion` of that database and add the migration step;
2. write the new snapshot, from the `app/` folder:

   ```sh
   dart run drift_dev schema dump lib/core/database/data_database.dart drift_schemas/data/
   ```

   (use `cache_database.dart` and `drift_schemas/cache/` for the cache);
3. run `dart run tool/generate.dart` and add a test of the migration to `test/core/database/migration_test.dart`, starting from the previous version with real rows.

Never edit a snapshot of a version that was already released.

### Dependencies

Before proposing a new package, check and report in the pull request: a licence compatible with GPL-3.0 (MIT, BSD, Apache-2.0, LGPL, MPL-2.0 are fine; proprietary licences are not), support for Android, Windows, macOS and Linux, active maintenance (a release in the last 12 months) and no dependency on proprietary services.

## Translations

The app ships in Italian and English. Texts live in `app/lib/l10n/app_en.arb` (the template, with a description for every string) and `app/lib/l10n/app_it.arb`.

- Every string has a `description` for translators.
- Plurals and genders use the ICU format.
- Never build a sentence by joining pieces: one full sentence, one string, with placeholders.

For now, translation changes are ordinary pull requests on the ARB files. A [Hosted Weblate](https://hosted.weblate.org/) project will be linked to the repository later; new languages will be accepted from then on.

## Data contributions (planned)

These areas are part of later phases and are **not open yet**. The instructions will be completed here when each one starts:

- **Toll tables** (phase 3, F3.3): motorway toll and vignette prices per country, kept as files in the repository. Use the "Toll rate" issue template to report a price.
- **Booking parsing rules** (phase 2, F2.3): per-company rules to read confirmations from e-mails and PDFs. Never attach a real booking with personal data: use the "Booking not recognized" issue template and anonymise the sample.
- **Badge lists** (phase 4, F4.1): lists of places per city, region and country, generated from Wikidata and reviewed by hand.

Data keeps the licence of its source, listed in [LICENSE-DATA.md](LICENSE-DATA.md).

## Artwork (planned)

Original graphics and icons (badges, profile backgrounds, map styles) are licensed under **CC BY-SA 4.0**. Contributions will open with phase 4.

## Security

Do not open a public issue for a vulnerability: follow [SECURITY.md](SECURITY.md).

## Licence of contributions

By contributing you agree that your contribution is licensed under the **GPL-3.0-or-later** (code) or the licence stated for the relevant data or artwork.
