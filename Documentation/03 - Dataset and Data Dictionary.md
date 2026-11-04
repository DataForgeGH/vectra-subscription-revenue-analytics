---
title: "03 - Dataset and Data Dictionary"
tags:
  - vectra
  - note/data-dictionary
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Dataset and Data Dictionary

> [!warning] Scope of this dictionary
> This is a **reconstructed** data dictionary from the SQL script and the imported PBIX model. No original source-system data dictionary, CSV profile, or `DESCRIBE` output was available. Types marked “PBIX” come from the imported model metadata; types marked “SQL” are inferred from the operations the script performs. Where a definition is not documented, it is marked **not documented** rather than guessed.

## Source object

| Item | Detail | Evidence |
|---|---|---|
| Database | `vectra_analytics` | `SQL-RECORDED` |
| Working table | `stg_vectra_raw` | `SQL-RECORDED` |
| Approximate raw rows | ~10,000 | `HANDOVER-REPORTED`; PBIX fact has 10,000 rows |
| Raw data file | Not present in the vault | `UNVERIFIED` |
| Source system | Not documented | `UNVERIFIED` |
| Observation unit | Appears to be one subscription transaction row; not formally defined | `INFERRED` |
| Currency | `$` appears in handover and report titles; no currency table or code exists | `UNVERIFIED` |

The SQL script cleans `stg_vectra_raw` in place, then creates `fact_subscriptions` and `dim_customers`. The PBIX imports the two analytical tables. The staging table itself is not imported into the report.

## Physical columns supported by the SQL

The following columns are referenced by the SQL script. The list is complete for the columns the script uses, but it is not proof that the table contained no other columns.

| Column | Initial role | Expected type before cleaning | Type after SQL operations | Business meaning | Evidence / note |
|---|---|---|---|---|---|
| `transaction_id` | Subscription transaction key | Text | Text; primary key on `fact_subscriptions` | Identifier for a subscription transaction row | `SQL-RECORDED`; uniqueness in the imported model is confirmed, but the source definition is not documented |
| `customer_id` | Customer identifier | Text, multiple formats | Text, normalised to `CUST-` + last four characters | Customer identifier | `SQL-RECORDED`; collision-free identity is `UNVERIFIED` |
| `signup_date` | Signup date | Text in several formats | `DATE` after conversion; original column dropped and replaced | Date the customer/subscription signed up | `SQL-RECORDED`; exact source semantics not documented |
| `plan_type` | Plan name | Text, inconsistent casing/spelling | Text; `Starter`, `Growth`, `Enterprise`, or `NULL`; later `Unassigned` in Power Query | Subscription plan | `SQL-RECORDED`; business catalogue not documented |
| `mrr_amount` | Monthly recurring revenue | Text with `$`, commas, negatives, blanks | Values stripped of `$`, commas, and leading `-`; blanks → `NULL`; **no SQL type alteration**; PBIX imports as double | Monthly recurring revenue per row | `SQL-RECORDED`; financial meaning `UNVERIFIED` |
| `cac_cost` | Customer acquisition cost | Text/numeric with blanks | Blanks → `NULL`; altered to `DECIMAL(10,2)` | Acquisition cost associated with the row | `SQL-RECORDED`; whether it is per customer, per acquisition, or allocated is not documented |
| `status` | Subscription status | Text, mixed case/whitespace | Whitespace-only → `NULL`; remaining values Title Cased (`Active`, `Cancelled`, `Churned`, `Downgraded`) | Subscription status | `SQL-RECORDED`; status definitions not documented |
| `cancellation_date` | Cancellation date | Text, often blank | Blanks → `NULL`; column altered to `DATE`; no full `STR_TO_DATE` path | Date of cancellation, if any | `SQL-RECORDED`; mixed-format parsing `UNVERIFIED` |
| `region_tier` | Combined region/tier attribute | Text | Split into `region` and `tier`; original column dropped | Region and account tier encoded together | `SQL-RECORDED`; source dictionary not documented |
| `acquisition_channel` | Acquisition channel | Text, blanks | Whitespace-only → `Unknown` | Marketing/acquisition source | `SQL-RECORDED`; channel taxonomy not documented |

> [!note] `region_tier` is not a normal column name
> It is a combined field. The SQL extracts `region` from the portion before the first `_` or `|`, and derives `tier` as `UNKNOWN` or `TIER_` plus the final character of the source value. The original field is then dropped. The full set of source values is not included in the evidence.

## Analytical table: `fact_subscriptions`

The SQL creates this table with `CREATE TABLE ... AS SELECT` over eight columns and `GROUP BY` all eight. The PBIX imports the result.

| Column | PBIX data type | Role | Business meaning | Note |
|---|---|---|---|---|
| `transaction_id` | String | Primary key; transaction identifier | One subscription transaction | 10,000 unique values in the imported model |
| `customer_id` | String | Foreign key to `dim_customers` | Customer identifier | 1,200 distinct customers |
| `signup_date` | Date/time (date) | Date | Signup date | Range 2021-01-01 to 2025-12-06 |
| `plan_type` | String | Dimension attribute | Plan name | Enterprise, Growth, Starter, Unassigned |
| `mrr_amount` | Double | Measure | MRR amount per row | 461 nulls; no negatives in the imported model |
| `cac_cost` | Double | Measure | Acquisition cost | 827 nulls; mean 4,473.58 across non-null rows |
| `status` | String | Dimension attribute | Raw status | 1,673 nulls; four non-null values |
| `cancellation_date` | Date/time (date) | Date | Cancellation date | 6,743 nulls; range to 2026-11-23 |

### Power Query-derived columns in the PBIX

These are **not** physical MySQL columns. They are added in the fact-table Power Query expression.

| Column | PBIX type | Logic | Business meaning |
|---|---|---|---|
| `plan_type_cleaned` | String | If `plan_type` is empty, `Unassigned`; otherwise `plan_type` | Reporting copy of plan type |
| `status_cleaned` | String | `Active` → `Active`; `Cancelled`/`Churned` → `Churned`; `Downgraded` → `Active`; otherwise `Unassigned` | Grouped status for reporting |

> [!warning] Do not confuse the “unknown” categories
> `plan_type = "Unassigned"`, `status_cleaned = "Unassigned"`, `region = "UNKNOWN"`, and `acquisition_channel = "Unknown"` are four different categories. They are not interchangeable, and they are not four measures of the same data-quality problem.

## Analytical table: `dim_customers`

| Column | PBIX data type | Role | Business meaning | Note |
|---|---|---|---|---|
| `customer_id` | String | Primary key | Customer identifier | 1,200 unique values; no duplicates |
| `region` | String | Attribute | Sales region | AMER, APAC, EMEA, LATAM, UNKNOWN |
| `tier` | String | Attribute | Account tier | TIER_1, TIER_2, TIER_3, UNKNOWN |
| `acquisition_channel` | String | Attribute | Acquisition channel | Direct Sales, Organic Search, Paid Ads, Partner Referral, Unknown |

The dimension is built by ranking staging rows per `customer_id` by `signup_date DESC` and keeping `row_num = 1`. It is a **latest-signup-record selection policy**, not a historised customer dimension. See [[06 - Data Model and Grain]].

## Date tables in the PBIX

The model has no standalone `dim_date`. It contains Power BI automatic date tables:

| Table | Role | Evidence |
|---|---|---|
| `DateTableTemplate_...` | Hidden template table | `PBIX-INSPECTED` |
| `LocalDateTable_...signup_date` | Hidden automatic date table for `signup_date` | `PBIX-INSPECTED` |
| `LocalDateTable_...cancellation_date` | Hidden automatic date table for `cancellation_date` | `PBIX-INSPECTED` |

Both relationships use `datePartOnly`. The report slicers use the `signup_date` hierarchy (Year → Quarter → Month → Day). There is no YoY measure in the active model.

## Value domains in the imported model

### Status

| `status` value | Rows | Share of rows | MRR sum | Note |
|---|---:|---:|---:|---|
| `Active` | 3,396 | 33.96% | $13,187,386 | Raw status |
| `Cancelled` | 1,692 | 16.92% | $6,596,289 | Used by `Churned Customers` and `Churn Rate %` |
| `Churned` | 1,565 | 15.65% | $6,429,141 | Excluded from `Churned Customers` |
| `Downgraded` | 1,674 | 16.74% | $6,617,832 | Mapped to `Active` in `status_cleaned` |
| `NULL` | 1,673 | 16.73% | $6,316,094 | Mapped to `Unassigned` in `status_cleaned` |
| **Total** | **10,000** | **100%** | **$39,146,742** | |

### Plan

| `plan_type` value | Rows | Share of rows | MRR sum | MRR share | Null MRR rows |
|---|---:|---:|---:|---:|---:|
| `Enterprise` | 3,656 | 36.56% | $14,147,984 | 36.14% | 169 |
| `Growth` | 2,493 | 24.93% | $10,106,914 | 25.82% | 106 |
| `Starter` | 2,619 | 26.19% | $10,163,091 | 25.96% | 123 |
| `Unassigned` | 1,232 | 12.32% | $4,728,753 | 12.08% | 63 |
| **Total** | **10,000** | **100%** | **$39,146,742** | **100%** | **461** |

`plan_type_cleaned` is identical to `plan_type` in the imported snapshot: the Power Query step replaces null `plan_type` with `Unassigned`, and no empty strings remain.

### Region and tier

| Dimension | Values in the imported model | Counts |
|---|---|---|
| `region` | AMER, APAC, EMEA, LATAM, UNKNOWN | 388, 194, 217, 195, 206 customers |
| `tier` | TIER_1, TIER_2, TIER_3, UNKNOWN | 397, 402, 195, 206 customers |
| `acquisition_channel` | Direct Sales, Organic Search, Paid Ads, Partner Referral, Unknown | 250, 222, 239, 243, 246 customers |

The number of `UNKNOWN` regions (206) and `UNKNOWN` tiers (206) is consistent with the combined `region_tier = UNKNOWN` group. The source mapping dictionary is not available, so the meaning of `TIER_1` versus `TIER_2` is not documented.

### Dates

| Field | Minimum | Maximum | Comment |
|---|---|---|---|
| `signup_date` | 2021-01-01 | 2025-12-06 | Five signup years; roughly 2,000 rows per year |
| `cancellation_date` | 2021-02-09 | 2026-11-23 | 6,743 nulls; 319 rows with a 2026 date |

There are **371** rows whose cancellation date is after the maximum signup date, including **5** after 2026-11-03 (the documentation date). That may be legitimate future-dated cancellations, a synthetic-data artifact, or a date-quality issue; the source does not establish which.

## Data-quality snapshot

These counts are from the imported PBIX model, not from SQL output.

| Check | Result | Interpretation |
|---|---:|---|
| Fact rows | 10,000 | Imported model snapshot |
| Distinct `transaction_id` | 10,000 | No duplicate transaction IDs in the model |
| Distinct `customer_id` in fact | 1,200 | Customer count in the fact |
| `dim_customers` rows | 1,200 | One row per customer |
| Duplicate `customer_id` in dimension | 0 | Dimension is unique by key |
| Fact customers missing from dimension | 0 | Referential integrity in the imported model |
| Dimension customers missing from fact | 0 | No orphan dimension rows |
| Negative `mrr_amount` | 0 | But the SQL sign removal is not financially validated |
| Null `mrr_amount` | 461 (4.61%) | Excluded from `SUM` |
| Null `cac_cost` | 827 (8.27%) | Excluded from `AVERAGE` |
| Null `status` | 1,673 (16.73%) | Becomes `Unassigned` in `status_cleaned` |
| Null `cancellation_date` | 6,743 (67.43%) | Mostly active/downgraded/null-status rows |
| Rows with `cancellation_date < signup_date` | 0 | Internal date ordering is consistent |
| Customer + signup groups with more than one row | 24 groups / 48 rows | Not duplicates by the full business key; may be multiple subscriptions |
| Duplicate full business combination (`customer_id`, `signup_date`, `plan_type`, `mrr_amount`, `region`) | 0 | The SQL duplicate check used a different definition |

> [!warning] What the snapshot does not prove
> These are properties of the imported model. They do not prove that the SQL script executed successfully, that its foreign key exists in MySQL, that the duplicate-deletion statement removed anything, or that the monetary values are financially correct. See [[13 - Validation and Evidence Register]].

## Missing or uncertain definitions

The following definitions are **not documented** in the available sources. They should not be invented in a public README or interview:

| Concept | What is missing | Why it matters |
|---|---|---|
| Subscription vs transaction | Whether a row is a current subscription, a historical transaction, a snapshot, or a mixture | Determines whether `SUM(mrr_amount)` is current MRR or an all-row total |
| Customer | Whether a customer is a company, an account, a billing entity, or a subscription | Determines whether customer counts are 1,200, 10,000, or something else |
| Active | Whether active means raw `Active`, `status_cleaned = Active`, or “has at least one active subscription” | Changes the active-customer and ARPU denominators |
| Churn | The period, denominator, and treatment of `Cancelled` vs `Churned` | The current measures are not period churn rates |
| Plan catalogue | The official plan names, prices, and feature boundaries | The `Starter`/`Growth`/`Enterprise` mapping is a text normalisation, not a product catalogue |
| Status codebook | The business meaning of `Cancelled`, `Churned`, and `Downgraded` | The report merges them inconsistently |
| Region/tier | The source values and their intended hierarchy | `TIER_1`/`TIER_2`/`TIER_3` are labels without documented semantics |
| Acquisition channel | The channel taxonomy and attribution rules | `Unknown` is an explicit bucket, not an inferred channel |
| CAC | Whether `cac_cost` is per customer, per acquisition, or allocated across rows | `AVERAGE(cac_cost)` is not a per-customer CAC |
| Currency | Currency code, scale, and whether `$` is USD | Totals cannot be treated as a financial statement |
| Date semantics | Whether `signup_date` is contract start, account creation, or transaction date | The “MRR growth” visual is by signup date, not by revenue month |

## Related notes

- [[04 - SQL Development Timeline]]
- [[05 - Data Cleaning Decisions]]
- [[06 - Data Model and Grain]]
- [[14 - Known Limitations]]
