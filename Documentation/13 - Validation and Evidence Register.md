---
title: "13 - Validation and Evidence Register"
tags:
  - vectra
  - note/evidence
  - note/validation
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Validation and Evidence Register

> [!warning] What this register is for
> This is a claim-by-claim record of what the available artifacts establish, what was computed from the imported model, and what remains unverified. It is deliberately conservative. A statement being present in the SQL script, README, or handover does **not** make it an observed result.

## Evidence hierarchy

The documentation uses the following labels, in descending order of directness:

| Label | Meaning | Typical use here |
|---|---|---|
| `PBIX-INSPECTED` | Read directly from the PBIX report definition, model metadata, or embedded scripts | Page names, visual bindings, measure definitions, relationships |
| `MODEL-COMPUTED` | Recomputed read-only from the imported PBIX data | Row counts, sums, distinct counts, date ranges |
| `SQL-RECORDED` | The operation appears in the SQL script | Cleaning statements, table definitions, constraints as written |
| `CONVERSATION-RECORDED` | Recorded during project development or troubleshooting; no attached output | Approximate source observations, design intent |
| `HANDOVER-REPORTED` | Appears in the audited handover or earlier generated description | Historical claims, proposed measures, page copy |
| `INFERRED` | A technically reasonable interpretation, not directly proven | Fact grain, type promotion, intent |
| `UNVERIFIED` | The available material is insufficient to establish the claim | Execution success, financial correctness, collision freedom |
| `RECOMMENDED` | A proposed action, not an implemented change | Remediation roadmap |

`PBIX-INSPECTED` and `MODEL-COMPUTED` are additions to the handover’s label set. They are necessary because the PBIX is a primary artifact and because a value can be computed from the imported data without being a rendered visual value.

## Assessment vocabulary

The register separates the **evidence label** from the **assessment**:

| Assessment | Meaning |
|---|---|
| **Supported** | Directly established by the artifact or computed from the model, with the stated scope |
| **Supported with caveat** | The value is established, but its business interpretation depends on an unresolved definition |
| **Recorded only** | The statement or operation is present; its execution or effect is not proven |
| **Conflict** | Two sources disagree; the PBIX is treated as authoritative for active report/model facts |
| **Contradicted** | The available evidence shows the claim is false as written |
| **Unverified** | The evidence is insufficient to decide |
| **Not present** | The object, measure, table, or artifact does not exist in the inspected file |
| **Unsupported** | No evidence or model output supports the claim |

## A. Artifact and execution claims

| ID | Claim | Assessment | Evidence | Basis / caveat |
|---:|---|---|---|---|
| A1 | A 692-line MySQL development script exists | **Supported** | `SQL-RECORDED` | [`vectra_subscription_analytics.sql.sql`](../vectra_subscription_analytics.sql.sql) has 692 lines |
| A2 | The script executed successfully | **Unverified** | `UNVERIFIED` | No execution log, query output, or DDL export |
| A3 | The script creates 14 backup snapshots | **Supported as recorded** | `SQL-RECORDED` | 14 `CREATE TABLE ... backup` statements are present |
| A4 | The script creates `fact_subscriptions` and `dim_customers` | **Supported as recorded** | `SQL-RECORDED` | `CREATE TABLE ... AS SELECT` statements are present |
| A5 | The MySQL primary/foreign keys exist in the final database | **Unverified** | `UNVERIFIED` | Constraints are written, but no DDL output; the FK is added before the dimension table is created |
| A6 | Duplicate deletion removed the intended rows | **Unverified** | `SQL-RECORDED`; `UNVERIFIED` result | CTE partitions by `transaction_id`, has no `ORDER BY`, and deletes by `transaction_id` |
| A7 | A PBIX report/model exists and contains four pages | **Supported** | `PBIX-INSPECTED` | [`vectra_analytics.pbix`](../vectra_analytics.pbix); four page definitions and four page IDs |
| A8 | The PBIX imports exactly two analytical tables | **Supported** | `PBIX-INSPECTED` | `vectra_analytics fact_subscriptions` and `vectra_analytics dim_customers` |
| A9 | The PBIX has 12 active DAX measures | **Supported** | `PBIX-INSPECTED` | All 12 are in the `_Measures` table |
| A10 | The PBIX contains two embedded TMDL scripts | **Supported** | `PBIX-INSPECTED` | `Script 1` and `Script 2`; they do not match the active model and are treated as stale |
| A11 | The report has rendered screenshots in the repository | **Not present** | `PBIX-INSPECTED`; artifact inventory | No full-page screenshots are supplied; banner images are embedded in the PBIX |
| A12 | The project is published in a Git repository | **Unverified / not established** | `UNVERIFIED` | The workspace root is a Git repository with **no commits and no remotes**; the README’s repository label is not publication evidence |
| A13 | The raw source data is available for re-validation | **Not present** | Artifact check | No CSV, SQL dump, or source extract is in the workspace |
| A14 | The report can be refreshed from this workspace | **Not established** | `PBIX-INSPECTED` | The M queries point to a local MySQL instance; the database is not included |

## B. Data and model facts

### Row counts, keys, and relationships

| ID | Claim | Assessment | Evidence | Basis / caveat |
|---:|---|---|---|---|
| B1 | Fact table has 10,000 rows | **Supported** | `MODEL-COMPUTED` | Imported table count |
| B2 | Fact table has 10,000 unique `transaction_id` values | **Supported** | `MODEL-COMPUTED` | No duplicate transaction IDs in the imported snapshot |
| B3 | Fact table has 1,200 distinct `customer_id` values | **Supported** | `MODEL-COMPUTED` | Distinct count |
| B4 | Customer dimension has 1,200 rows and 1,200 unique IDs | **Supported** | `MODEL-COMPUTED` | No duplicate dimension keys |
| B5 | There are no missing fact keys or orphan dimension rows | **Supported in the imported model** | `MODEL-COMPUTED` | 0 fact customers absent from dimension; 0 dimension customers absent from fact |
| B6 | The relationship is many-to-one, active, single-direction | **Supported** | `PBIX-INSPECTED` | `fact[customer_id]` → `dim[customer_id]` |
| B7 | The SQL foreign key is the same relationship | **Unverified** | `UNVERIFIED` | A Power BI relationship is not a MySQL FK |
| B8 | One row represents one subscription transaction | **Inferred, not established** | `INFERRED` | The eight-column `GROUP BY` supports a transaction-like grain; source semantics are undocumented |
| B9 | Each customer has 8.33 fact rows on average | **Supported** | `MODEL-COMPUTED` | 10,000 ÷ 1,200 |
| B10 | 1,198 of 1,200 customers have more than one signup date | **Supported** | `MODEL-COMPUTED` | Grouped distinct signup dates per customer |
| B11 | 576 customers have rows in all four plan categories | **Supported** | `MODEL-COMPUTED` | Plan is a row-level attribute |
| B12 | 24 customer/signup groups contain more than one row (48 rows) | **Supported** | `MODEL-COMPUTED` | Not duplicates by the full business combination |

### Revenue

| ID | Claim | Assessment | Evidence | Basis / caveat |
|---:|---|---|---|---|
| B13 | All-row MRR is $39,146,742 | **Supported as an all-row sum** | `MODEL-COMPUTED` | Sum of `mrr_amount`; 9,539 non-null rows |
| B14 | The total is current MRR | **Unverified / contradicted as a label** | `MODEL-COMPUTED`; `UNVERIFIED` | Includes Active, Cancelled, Churned, Downgraded, and null-status rows; grain undocumented |
| B15 | There are 461 null MRR rows (4.61%) | **Supported** | `MODEL-COMPUTED` | 9,539 non-null |
| B16 | There are no negative MRR values in the imported model | **Supported** | `MODEL-COMPUTED` | But the SQL sign removal is not financially validated |
| B17 | Mean MRR per non-null row is $4,103.86; median is $2,499 | **Supported** | `MODEL-COMPUTED` | Descriptive statistics |
| B18 | Enterprise revenue is $14,147,984 | **Supported** | `MODEL-COMPUTED` | 36.14% of all-row MRR |
| B19 | Growth revenue is $10,106,914 | **Supported** | `MODEL-COMPUTED` | 25.82% |
| B20 | Starter revenue is $10,163,091 | **Supported** | `MODEL-COMPUTED` | 25.96% |
| B21 | Unassigned plan revenue is $4,728,753 | **Supported** | `MODEL-COMPUTED` | 12.08%; 1,232 rows; 1,169 with MRR |
| B22 | The ten largest customers account for about 2.2% of all-row MRR | **Supported** | `MODEL-COMPUTED` | Top-ten customer sums; top customer ≈ 0.25% |
| B23 | The total is financially reconciled | **Unverified** | `UNVERIFIED` | No billing ledger, finance baseline, or independent total |

### Status and lifecycle

| ID | Claim | Assessment | Evidence | Basis / caveat |
|---:|---|---|---|---|
| B24 | Raw status counts are 3,396 Active, 1,692 Cancelled, 1,565 Churned, 1,674 Downgraded, 1,673 null | **Supported** | `MODEL-COMPUTED` | 10,000 total |
| B25 | `status_cleaned` counts are 5,070 Active, 3,257 Churned, 1,673 Unassigned | **Supported** | `PBIX-INSPECTED`; `MODEL-COMPUTED` | Power Query mapping |
| B26 | 1,135 distinct customers have an Active row | **Supported** | `MODEL-COMPUTED` | Row measure returns 3,396 |
| B27 | 1,067 of those 1,135 also have a Cancelled or Churned row | **Supported** | `MODEL-COMPUTED` | Customers overlap lifecycle states |
| B28 | Only 10 customers have exactly one distinct raw status across all rows | **Supported** | `MODEL-COMPUTED` | Includes null; 32 have one non-null status |
| B29 | 1,131 distinct customers have at least one Cancelled or Churned row | **Supported** | `MODEL-COMPUTED` | 94.25% of 1,200 |
| B30 | The status field describes a current customer state | **Contradicted** | `MODEL-COMPUTED` | It is a row-level lifecycle attribute; customers can hold several states |
| B31 | Cancelled and Churned are interchangeable | **Unverified** | `UNVERIFIED` | No status codebook; Power Query merges them, DAX does not |
| B32 | Null status means inactive | **Unverified** | `UNVERIFIED` | Could be unknown, unrecorded, or not applicable |

### Dates

| ID | Claim | Assessment | Evidence | Basis / caveat |
|---:|---|---|---|---|
| B33 | Signup dates range from 2021-01-01 to 2025-12-06 | **Supported** | `MODEL-COMPUTED` | Five signup years |
| B34 | Cancellation dates range from 2021-02-09 to 2026-11-23 | **Supported** | `MODEL-COMPUTED` | 6,743 nulls |
| B35 | 371 cancellation dates are after the maximum signup date | **Supported** | `MODEL-COMPUTED` | Includes 319 in 2026 and 5 after 2026-11-03 |
| B36 | No cancellation date is before signup | **Supported** | `MODEL-COMPUTED` | Internal ordering check |
| B37 | There is no standalone `dim_date` | **Supported** | `PBIX-INSPECTED` | Automatic date tables only |
| B38 | There is no YoY measure | **Supported** | `PBIX-INSPECTED` | No time-intelligence measure in the active model |
| B39 | The “MRR Growth Trend” is a monthly revenue series | **Contradicted** | `PBIX-INSPECTED` | It groups `Total MRR` by the `signup_date` hierarchy |

### Data quality

| ID | Claim | Assessment | Evidence | Basis / caveat |
|---:|---|---|---|---|
| B40 | Unassigned plan affects 12.08% of all-row MRR | **Supported** | `MODEL-COMPUTED` | $4,728,753; 1,232 rows |
| B41 | UNKNOWN region affects 16.67% of all-row MRR | **Supported** | `MODEL-COMPUTED` | $6,525,129; 206 customers |
| B42 | Unknown channel affects 21.14% of all-row MRR | **Supported** | `MODEL-COMPUTED` | $8,276,576; 246 customers |
| B43 | Null status affects 16.73% of rows and 16.13% of MRR | **Supported** | `MODEL-COMPUTED` | $6,316,094 |
| B44 | 827 CAC rows are null (8.27%) | **Supported** | `MODEL-COMPUTED` | Mean $4,473.58 across 9,173 non-null rows |
| B45 | The quality gaps have a single proven root cause | **Unverified** | `UNVERIFIED` | No source-system investigation |
| B46 | The four “unknown” categories are interchangeable | **Contradicted** | `PBIX-INSPECTED` | Plan, status, region, and channel use different fields and meanings |

## C. Measure and report claims

| ID | Claim | Assessment | Evidence | Basis / caveat |
|---:|---|---|---|---|
| C1 | `Total MRR` is `SUM(mrr_amount)` | **Supported** | `PBIX-INSPECTED` | Active model |
| C2 | `Active Customers` is `COUNTROWS` where raw status is Active | **Supported** | `PBIX-INSPECTED` | Returns 3,396 rows |
| C3 | `Active Customers` is a distinct customer count | **Contradicted** | `PBIX-INSPECTED` | 1,135 distinct customers |
| C4 | `Churned Customers` counts only raw Cancelled rows | **Supported** | `PBIX-INSPECTED` | Returns 1,692; excludes 1,565 Churned |
| C5 | `Churn Rate %` is Cancelled rows ÷ all rows | **Supported** | `PBIX-INSPECTED` | 16.92% unfiltered |
| C6 | `Churn Rate %` is a period or customer churn rate | **Contradicted** | `PBIX-INSPECTED` | No period, no customer denominator |
| C7 | `Annual ARPU` is all-row MRR ÷ 1,200 customers | **Supported** | `PBIX-INSPECTED`; `MODEL-COMPUTED` | $32,622.29 |
| C8 | `Annual ARPU` is annualised | **Contradicted** | `PBIX-INSPECTED` | No monthly/annual period; no ×12 |
| C9 | `Customer Count` is a row count | **Supported** | `PBIX-INSPECTED` | Returns 10,000, not 1,200 |
| C10 | `Average Customer CAC` is an average per row | **Supported** | `PBIX-INSPECTED` | $4,473.58; 9,173 non-null rows |
| C11 | `Active Subscriptions` includes Downgraded rows | **Supported** | `PBIX-INSPECTED`; `MODEL-COMPUTED` | 5,070 = 3,396 Active + 1,674 Downgraded |
| C12 | `Customers Enterprise %` is a revenue share | **Supported** | `PBIX-INSPECTED` | 36.14%; not a customer share |
| C13 | The active model contains 12 measures | **Supported** | `PBIX-INSPECTED` | All in `_Measures` |
| C14 | The handover’s `Active Customers` uses `DISTINCTCOUNT` | **Conflict** | `HANDOVER-REPORTED` vs `PBIX-INSPECTED` | Active model uses `COUNTROWS` |
| C15 | The handover’s `Total Churned MRR` exists | **Not present** | `PBIX-INSPECTED` | No such active measure |
| C16 | The handover’s `Average ARPU` exists | **Not present** | `PBIX-INSPECTED` | Active model has `Annual ARPU` |
| C17 | The handover’s `YoY Revenue Growth %` exists | **Not present** | `PBIX-INSPECTED` | No active YoY measure |
| C18 | The handover’s `Enterprise Customers` exists | **Not present** | `PBIX-INSPECTED` | Active model has `Enterprise Revenue`; the old name survives only in stale TMDL |
| C19 | The report has four pages with the stated banner titles | **Supported** | `PBIX-INSPECTED` | Overview, Customer, Products, Insights |
| C20 | Customer and Products tables are filtered to Churned/Unassigned | **Supported** | `PBIX-INSPECTED` | `status_cleaned IN ("Churned","Unassigned")` |
| C21 | The watchlist contains 4,930 rows across 1,188 customers | **Supported** | `MODEL-COMPUTED` | Under that filter |
| C22 | The Products table shows eight plan/status combinations | **Supported** | `PBIX-INSPECTED`; `MODEL-COMPUTED` | Four plans × two cleaned statuses |
| C23 | The Products table’s `Churn Rate %` is 34.32% overall | **Supported in that filter context** | `MODEL-COMPUTED`; DAX | 1,692 ÷ 4,930; not the unfiltered 16.92% |
| C24 | The Insights page contains two static text boxes and no data visuals | **Supported** | `PBIX-INSPECTED` | Text is not measure-bound |
| C25 | Overview and Customer can navigate to Insights through their own rail buttons | **Contradicted** | `PBIX-INSPECTED` | Their Insights buttons target non-existent page ID `3c3faaddc9bd852e6e31`; page tabs still work |
| C26 | Insights is reachable from Products through its rail button | **Supported** | `PBIX-INSPECTED` | Products button targets `1e8c549fde4252552d78` |
| C27 | The report opens on Overview | **Contradicted** | `PBIX-INSPECTED` | `activePageName` is Insights |
| C28 | The report includes usable rendered page screenshots | **Not present** | Artifact check | No full-page screenshots; only embedded banner images |

## D. Business narrative claims

| ID | Claim | Assessment | Evidence | Basis / caveat |
|---:|---|---|---|---|
| D1 | Enterprise contributes the majority of MRR | **Contradicted** | `MODEL-COMPUTED` | 36.14% is a plurality, not a majority |
| D2 | A small number of Enterprise accounts dominate revenue | **Not supported** | `MODEL-COMPUTED` | Top ten customers ≈ 2.2% of all-row MRR |
| D3 | Cancellations are disproportionately clustered in Growth and Starter | **Not supported as written** | `MODEL-COMPUTED` | Enterprise has the largest count; Growth rate is 18.13% vs 16.44% Enterprise |
| D4 | Growth has the highest Cancelled-only rate | **Supported descriptively** | `MODEL-COMPUTED` | 18.13%, a 1.69-point gap over Enterprise |
| D5 | The difference proves a mid-tier churn problem | **Unsupported** | `MODEL-COMPUTED`; `UNVERIFIED` | No cohort, contract, usage, or causal analysis |
| D6 | Unassigned plan revenue is a separate revenue stream | **Contradicted** | `MODEL-COMPUTED` | It is a category inside the $39.15M total |
| D7 | The 20% session-decline threshold predicts churn | **Unverified** | `UNVERIFIED` | No telemetry, baseline, or validation |
| D8 | The retention initiative will reduce voluntary churn by 15% | **Unsupported** | `UNVERIFIED` | No experiment or model |
| D9 | The governance initiative will produce 100% data integrity | **Unsupported** | `UNVERIFIED` | No acceptance criteria or validation results |
| D10 | The project is production-ready | **Contradicted** | Artifact review | No refresh, deployment, monitoring, reconciliation, or Git history |

## E. Source conflicts

The PBIX is treated as authoritative for the **active report and model**. The handover is treated as a historical description that is sometimes stale. Conflicts are recorded rather than silently harmonised.

| # | Topic | Handover / README / SQL says | PBIX shows | Resolution |
|---:|---|---|---|---|
| E1 | Date table | Handover lists `dim_date` | No standalone `dim_date`; automatic date tables only | PBIX wins; handover claim marked historical/stale |
| E2 | YoY measure | Handover records `YoY Revenue Growth %` using `dim_date` | No YoY measure; no suitable date table | PBIX wins; measure marked not present |
| E3 | Active Customers | Handover: `DISTINCTCOUNT(fact[customer_id])` | `COUNTROWS` filtered to raw `status = "Active"` | PBIX wins; handover definition marked conflicting |
| E4 | Churn Rate % | Handover: `[Active Customers]` filtered to `status_cleaned = "CHURNED"` | Cancelled rows ÷ all rows; no distinct customer denominator | PBIX wins; semantic conflict recorded |
| E5 | Total Churned MRR | Handover records a measure | No active `Total Churned MRR` | PBIX wins; measure absent |
| E6 | Average ARPU | Handover records `Average ARPU` using `[Active Customers]` | Active measure is `Annual ARPU`, using `DISTINCTCOUNT(dim_customers[customer_id])` | PBIX wins; both the name and denominator differ |
| E7 | Enterprise measure | Handover says `Enterprise Customers` is a revenue calculation with a misleading name | Active measure is `Enterprise Revenue`; old name survives in stale TMDL | PBIX wins; old name is a historical artifact |
| E8 | Status values | Handover describes `status_cleaned = "CHURNED"` | Cleaned values are Title Case: `Churned`, `Active`, `Unassigned` | PBIX wins; case-sensitive filters in the handover would not match |
| E9 | TMDL scripts | Embedded scripts define four measures in the fact table / four in `_Measures` | Active model has 12 measures in `_Measures` | Active model wins; embedded TMDL is stale authoring material |
| E10 | Page navigation | Buttons imply all pages are reachable | Four targets use non-existent page IDs; the Insights rail button works only on Products | PBIX wins; defect recorded |
| E11 | File name | Handover calls the SQL file `jj.sql` | Actual file is `vectra_subscription_analytics.sql.sql` | Actual filename wins; handover name treated as a historical label |
| E12 | Git publication | README describes a repository and Git/GitHub workflow | Workspace root has no commits and no remotes | Publication is unverified; do not claim a public repository |
| E13 | Customer conflicts | Project history reports ~1,198 attribute conflicts | Final dimension has 1,200 rows, but the original conflict count and query output are absent | Conversation-recorded; semantic validity unverified |
| E14 | Slash-date interpretation | Project history reports ~2,981 slash dates with a `MM/DD/YYYY` pattern | Imported dates are plausible; no format-level output retained | Conversation-recorded; conversion correctness unverified |

> [!important] Do not average the conflicts
> The PBIX is not “more true” than the SQL for SQL execution, and the SQL is not proof of the PBIX’s values. Each artifact answers a different question. The PBIX is authoritative for what the active report contains; the SQL is evidence of what was written, not what ran.

## F. Verification checks performed

These checks were run against the PBIX and report definition for this documentation:

| Check | Method | Result |
|---|---|---|
| PBIX container readable | Opened as a ZIP archive | Yes |
| Report definition parsed | Read page, visual, and pages metadata JSON | 4 pages, 54 visual containers |
| Model decoded | Read tables and relationships from the PBIX model | 2 analytical tables, 1 active relationship, 12 measures |
| Fact row count | Model table count | 10,000 |
| Unique transaction IDs | Distinct count | 10,000 |
| Customer count | Distinct fact and dimension counts | 1,200 / 1,200 |
| Referential integrity | Anti-join both directions | 0 missing each way |
| Measure inventory | Decoded `_Measures` metadata | 12 active measures |
| MRR total | `sum(mrr_amount)` | $39,146,742 |
| Plan totals | Grouped sum | Matches plan table in [[03 - Dataset and Data Dictionary]] |
| Null counts | Column null counts | 461 MRR, 827 CAC, 1,673 status, 6,743 cancellation |
| Date ranges | Min/max | Signup 2021-01-01 to 2025-12-06; cancellation 2021-02-09 to 2026-11-23 |
| Table filters | Parsed visual `filterConfig` | Customer/Products tables filter `status_cleaned IN ("Churned","Unassigned")` |
| Page targets | Compared `navigationSection` IDs to page IDs | 4 invalid targets |
| Report filters | Checked report/page metadata | None |
| Visual interactions | Searched report definition | No custom `visualInteractions` |
| Rendered page review | Interactive Power BI Desktop / screenshots | **Not performed** |
| SQL execution | MySQL run / output capture | **Not performed** |
| Financial reconciliation | Ledger or independent baseline | **Not available** |

## G. What would change a claim’s status

| Claim area | Evidence that would upgrade it |
|---|---|
| SQL execution | A clean-database run log with row counts, DDL, and constraint verification |
| Revenue | A billing/finance reconciliation and a documented current-MRR definition |
| Negative MRR | Source reason codes or finance sign-off on the treatment |
| Customer identity | Original-ID mapping and a collision test |
| Customer dimension | A documented SCD2 or snapshot design with tie-break rules |
| Active/churn | A metric contract with period, population, and denominator |
| ARPU/CAC | A period revenue base and acquisition-event definition |
| Unassigned exposure | Source plan mapping and an owner-assigned exception process |
| Churn narrative | Cohort, contract, telemetry, and renewal data, plus a controlled analysis |
| 20% threshold | A pilot with baseline, control, and a pre-registered decision rule |
| Report visuals | Rendered screenshots or an interactive review in Power BI Desktop |
| Production readiness | Scheduled refresh, monitoring, access control, deployment, and incident ownership |

## H. Claims this documentation does not make

- That the SQL executed successfully.
- That the MySQL constraints exist.
- That the PBIX is financially reconciled.
- That `Total MRR` is current MRR.
- That `Active Customers` is a distinct active-customer count.
- That `Churn Rate %` is a customer churn rate.
- That `Annual ARPU` is annual.
- That `Average Customer CAC` is per customer.
- That Unassigned plan revenue is lost or separately earned.
- That the churn narrative is causal.
- That the 20% threshold is validated.
- That the 15% impact is achievable.
- That the project is production-ready.
- That a public Git repository exists.

## Related notes

- [[03 - Dataset and Data Dictionary]]
- [[06 - Data Model and Grain]]
- [[08 - DAX and KPI Dictionary]]
- [[09 - Power BI Dashboard Walkthrough]]
- [[10 - Business Findings]]
- [[14 - Known Limitations]]
- [[16 - Artifact Inventory]]
