# Data pack: tolls and vignettes

**Status: not started. Planned for phase 3 (F3.3 Tolls).** No table and no script yet.

| | |
|---|---|
| Content | Toll tariffs by country and vehicle class; vignettes by country |
| Source | Tables maintained by the community in this repository, plus toll roads from OpenStreetMap (PRD 5.2) |
| Licence | To be decided before the first pack (open point in `docs/DECISIONS.md`) |
| Used by | `Leg.tollEstimate` and `TollRecord` in `app/lib/core/models/` |

Two things are already known from the M1 prototypes (PRD 16.3):

- Valhalla marks vignette motorways as toll roads and does not tell them apart from toll gates, so vignettes need their own data per country.
- Toll amounts in the app are estimates and are labelled as such; an amount the user actually paid replaces the estimate (PRD F3.3).

Do not open pull requests with tariff tables yet: the format and the licence are not defined.
