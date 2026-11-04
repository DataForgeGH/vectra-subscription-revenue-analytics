---
title: "16 - Artifact Inventory"
tags:
  - vectra
  - note/inventory
  - note/evidence
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Artifact Inventory

> [!warning] Inventory snapshot, not a publication manifest
> The hashes and sizes below describe the source files at the time this documentation was written. They are evidence of the inspected snapshot, not proof that the files are unchanged today. Recompute the hashes before quoting them. The PBIX and SQL were **not modified** during this documentation pass.

## Inventory scope

| Scope | Included | Excluded |
|---|---|---|
| Source artifacts | PBIX, SQL, audited handover, README, INSIGHTS | Vault welcome note, environment folders |
| Documentation | The 17 notes in `VECTRA/` | Temporary inspection scripts |
| PBIX internals | Report definition, model metadata, embedded assets, TMDL scripts | Rendered full-page screenshots (none exist) |
| Execution evidence | None supplied | MySQL logs, query outputs, DDL exports |

The folders `.copilot/`, `.obsidian/`, `.opencode/`, and `copilot/` are environment or tooling directories, not project artifacts. `Welcome.md` is the vault default note and is not part of the Vectra evidence set.

## Source artifacts

All paths are relative to the workspace root: `C:\Users\joshu\Downloads\VECTRA ANALYTICS\Knowledge Base`.

| Artifact | Type / role | Size | Lines | Last write (local) | SHA-256 |
|---|---|---:|---:|---|---|
| [`vectra_analytics.pbix`](../vectra_analytics.pbix) | Power BI report and imported model; authoritative for active report/model facts | 1,665,591 bytes | binary | 2026-11-02 23:30:28 | `B0ED709E9B399C638251BA8799B85D9E933E2D6DB52E90E130B2D15D441829A8` |
| [`vectra_subscription_analytics.sql.sql`](../vectra_subscription_analytics.sql.sql) | MySQL development script; `SQL-RECORDED`, not an execution log | 19,713 bytes | 692 | 2026-11-03 00:46:00 | `1E0E358DE2F339CA383BA90CBCB3E4520422894F6262268FF5B09AA127748DC3` |
| [`VECTRA_PROJECT_MASTER_HANDOVER_AUDITED.md`](../VECTRA_PROJECT_MASTER_HANDOVER_AUDITED.md) | Audited historical handover; evidence labels and stale model descriptions | 47,145 bytes | 900 | 2026-11-03 00:55:02 | `4BD33D3D6E01D9D7FEFB95C3ACF5517DCEA420EAEED1B73B35396BCDDF132984` |
| [`README.md`](../README.md) | Public-facing project description; largely consistent but not authoritative | 26,896 bytes | 352 | 2026-11-03 02:40:05 | `592D913B6BEC671ADB71CBA15926134A03D1494BC8CA7A120B1C627DD6FB39F7` |
| [`INSIGHTS.md`](../INSIGHTS.md) | Source narrative for the Page 4 strategic copy | 3,253 bytes | 59 | 2026-11-02 16:16:23 | `75CA2ECF9177A12B4188963534C8522FEA2AFE5EB684005F25C444FE16B4DA81` |

> [!note] The SQL file has a double extension
> The actual filename is `vectra_subscription_analytics.sql.sql`. The handover refers to `jj.sql`; that is a historical label, not the current filename. See [[13 - Validation and Evidence Register#E. Source conflicts]].

## PBIX internal inventory

The PBIX is a ZIP-based Power BI file. The following contents were read directly from the archive and decoded model/report metadata.

### Model

| Component | Count / value | Evidence |
|---|---:|---|
| Analytical tables | 2: `vectra_analytics fact_subscriptions`, `vectra_analytics dim_customers` | `PBIX-INSPECTED` |
| Fact rows | 10,000 | `MODEL-COMPUTED` |
| Distinct fact customers | 1,200 | `MODEL-COMPUTED` |
| Dimension rows | 1,200 | `MODEL-COMPUTED` |
| Active relationships | 1: fact `customer_id` many-to-one dimension `customer_id` | `PBIX-INSPECTED` |
| Active DAX measures | 12, all in `_Measures` | `PBIX-INSPECTED` |
| Standalone date table | 0 | `PBIX-INSPECTED` |
| YoY measure | 0 | `PBIX-INSPECTED` |

### Report

| Component | Count / value | Evidence |
|---|---:|---|
| Pages | 4: Overview, Customer, Products, Insights | `PBIX-INSPECTED` |
| Visual containers | 54 | `PBIX-INSPECTED` |
| Default page | Insights (`activePageName`) | `PBIX-INSPECTED` |
| Page filters | None found | `PBIX-INSPECTED` |
| Report-level filters | None found | `PBIX-INSPECTED` |
| Custom visual interactions | None found | `PBIX-INSPECTED` |
| Navigation defects | 4 stale page IDs | `PBIX-INSPECTED` |

| Page | Page ID | Canvas | Visual containers |
|---|---|---:|---:|
| Overview | `8d2103f8952ac99c6787` | 2560 × 1440 | 18 |
| Customer | `9e5dfbc10b351be005c4` | 2560 × 1440 | 14 |
| Products | `f34efc8ac59d78edbe06` | 2560 × 1440 | 14 |
| Insights | `1e8c549fde4252552d78` | 3840 × 2160 | 8 |

### Embedded images

Four registered images are embedded in the report. They support the page banner titles; they are **not** full report screenshots.

| File | Size | Use |
|---|---:|---|
| `download_(3)3475390192229687.jfif` | 54,837 bytes | Registered banner asset |
| `Screenshot_2026-11-01_2243109148790048421646.png` | 386,504 bytes | Registered banner asset |
| `Screenshot_2026-11-01_2256513190146059581651.png` | 395,577 bytes | Registered banner asset |
| `Screenshot_2026-11-02_1601341936730931847388.png` | 349,952 bytes | Registered banner asset |

The filenames are retained exactly as stored. They are internal assets, not a screenshot gallery and not evidence of a rendered visual review.

### Embedded TMDL scripts

| Script | Sizes | Status |
|---|---:|---|
| `Script%201.tmdl` / `Script%201.txt` | 29,922 / 14,961 bytes | Stale authoring artifact |
| `Script%202.tmdl` / `Script%202.txt` | 30,716 / 15,358 bytes | Stale authoring artifact |

These scripts do **not** describe the active model. The active model has 12 measures in `_Measures`; the embedded scripts contain different measure inventories and an `Enterprise Customers` measure that is not active. They are useful as historical evidence, not as model documentation. See [[06 - Data Model and Grain#Embedded TMDL scripts are stale]].

### Other archive sections

| Section | Purpose |
|---|---|
| `Report/` | Report definition, pages, visuals, static resources |
| `TMDLScripts/` | Stale embedded TMDL authoring scripts |
| `DataModel` | Binary imported model |
| `DiagramLayout` | Model diagram layout metadata |
| `Metadata` | Package metadata |
| `SecurityBindings` | Security bindings |
| `Settings` | Report settings |
| `Version` | File format version |

## Source-to-artifact chain

The evidence chain is incomplete, and the gaps matter:

```text
Unknown raw source
        │
        ▼
SQL script (recorded cleaning, no execution log)
        │
        ▼
MySQL tables (not included)
        │
        ▼
Power BI import snapshot (PBIX, local MySQL M query)
        │
        ▼
Report definition and visuals (inspected)
        │
        ▼
This documentation (evidence-qualified)
```

| Link | Status | Consequence |
|---|---|---|
| Raw source → SQL | **Missing** | Source-value coverage and input quality cannot be verified |
| SQL → MySQL | **Unverified** | Statements are recorded, but execution and final DDL are not proven |
| MySQL → PBIX import | **Unverified** | The imported snapshot cannot be reconciled to a live database |
| PBIX model → report definition | **Inspected** | Report bindings and model metadata are directly readable |
| Report definition → rendered visuals | **Not inspected interactively** | Layout and rendering claims are limited |
| Documentation → source hashes | **Verified at snapshot** | Hashes can be recomputed to detect changes |

## Documentation deliverable

The `VECTRA/` folder contains 17 notes.

| Note | Role |
|---|---|
| [[00 - Home]] | Navigation, scope, evidence legend, reading paths |
| [[01 - Project Overview]] | Project summary, business context, artifact status |
| [[02 - Business Problem and Scope]] | Problem framing, stakeholders, questions, scope boundaries |
| [[03 - Dataset and Data Dictionary]] | Field dictionary, counts, distributions, data-quality snapshot |
| [[04 - SQL Development Timeline]] | Phase-by-phase record of the 692-line script |
| [[05 - Data Cleaning Decisions]] | Decision-by-decision audit of cleaning choices |
| [[06 - Data Model and Grain]] | Tables, relationships, grain, customer dimension, date model |
| [[07 - Power Query Transformations]] | M-layer cleaning and model-side transformations |
| [[08 - DAX and KPI Dictionary]] | All 12 measures, semantics, filter context, label caveats |
| [[09 - Power BI Dashboard Walkthrough]] | Page-by-page report-definition review |
| [[10 - Business Findings]] | Descriptive findings and claim verdicts |
| [[11 - Strategic Recommendations]] | Evidence-gated remediation roadmap |
| [[12 - Challenges and Decisions]] | Decision record and alternatives |
| [[13 - Validation and Evidence Register]] | Claim-level evidence and source conflicts |
| [[14 - Known Limitations]] | Limitations by category and audience |
| [[15 - Future Improvements]] | Prioritised backlog and acceptance criteria |
| [[16 - Artifact Inventory]] | This inventory |

## Not included

| Missing artifact | Why it matters | Status |
|---|---|---|
| Raw CSV/extract or SQL dump | Cannot reproduce the cleaning or verify source coverage | Not supplied |
| MySQL DDL / `SHOW CREATE TABLE` | Cannot prove keys, types, or constraints | Not supplied |
| SQL execution log and query outputs | Cannot prove the script ran or what it returned | Not supplied |
| Finance/billing baseline | Cannot reconcile revenue | Not supplied |
| Full-page rendered screenshots | Cannot verify visual layout and rendering | Not supplied |
| Power BI Desktop interactive review | Cannot test slicers, tooltips, cross-filters visually | Not performed |
| Usage/telemetry data | Cannot validate the 20% session threshold | Not supplied |
| Customer/contract/renewal data | Cannot build a customer churn or retention cohort | Not supplied |
| Refresh logs / gateway configuration | Cannot assess production operations | Not supplied |
| Git commits and remote | Cannot demonstrate publication or version history | Not present |
| `.pbip` / `.pbit` source project | Cannot review report source outside the binary PBIX | Not supplied |

## Temporary inspection workspace

The following location was used for read-only inspection. It is **outside the vault**, is not a deliverable, and may be cleared by the operating system.

`C:\Users\joshu\AppData\Local\Temp\vectra_pbix_inspect\`

| Item | Purpose |
|---|---|
| `unzipped\` | Extracted PBIX archive: report JSON, static resources, TMDL scripts |
| `pbix.py` | Basic PBIX model inspection |
| `analyze.py` | Table, relationship, and measure inventory |
| `deep2.py`, `deep.py` | Field and distribution checks |
| `summary.py` | Model summary and recomputed counts |
| `measures.py` | Active measure extraction |
| `anomalies.py` | Date and status anomaly checks |
| `details.js`, `fields.js`, `find.js`, `inspect.js`, `insightstext.js` | Report/page/visual metadata inspection |
| `report.zip` | Read-only working copy of the PBIX archive |

The temporary scripts are evidence of how the checks were performed. They are not required to read this vault, and they are not a substitute for a reproducible project test suite.

## Reproducing the inspection

### To verify the source snapshot

1. Recompute SHA-256 for the five source artifacts.
2. Compare against the table above.
3. If a hash differs, treat the documentation as a snapshot of an earlier version.

### To inspect the PBIX model

1. Open `vectra_analytics.pbix` in Power BI Desktop.
2. Review the model view for tables, relationships, and the 12 measures.
3. Use DAX Studio or a read-only model extractor to recompute the counts.
4. Compare against [[13 - Validation and Evidence Register#F. Verification checks performed]].

### To test the SQL

A clean MySQL instance is required. The workspace does not include the source database.

1. Create a clean `vectra_analytics` database.
2. Load the raw extract (not supplied).
3. Run the SQL script and capture all output.
4. Export `SHOW CREATE TABLE` for both analytical tables.
5. Compare row counts and totals to the PBIX.
6. Attach the execution log and outputs to the repository.

### To review the report visually

1. Open the PBIX in Power BI Desktop.
2. Check every page at 100%, 125%, and 150% scaling.
3. Test every slicer, cross-filter, drill, and navigation button.
4. Capture full-page screenshots.
5. Record the reviewer and date.

## Change control

| Rule | Reason |
|---|---|
| Do not edit the source PBIX or SQL when documenting | Preserves the evidence snapshot |
| Recompute hashes after any source change | Detects silent drift |
| Add a new documentation version rather than overwriting claims | Preserves the audit trail |
| Do not add screenshots unless they are real | Prevents fabricated evidence |
| Keep temporary inspection files outside the vault | Avoids clutter and accidental publication |

## Artifact status summary

| Dimension | Status |
|---|---|
| PBIX report/model inspection | Complete at definition/model level |
| Model value recomputation | Complete for the inspected snapshot |
| SQL statement audit | Complete as a script |
| SQL execution validation | Not performed |
| Financial reconciliation | Not possible with supplied evidence |
| Visual rendering review | Not performed |
| Churn hypothesis validation | Not performed |
| Production readiness | Not demonstrated |
| Git publication | Not present |
| Documentation coverage | 17 notes |

The project is documentable and auditable, but it is not a validated production asset. The inventory is deliberately explicit about that boundary.

## Related notes

- [[00 - Home]]
- [[13 - Validation and Evidence Register]]
- [[14 - Known Limitations]]
- [[15 - Future Improvements]]
