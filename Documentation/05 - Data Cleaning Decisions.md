---
title: "05 - Data Cleaning Decisions"
tags:
  - vectra
  - note/cleaning
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Data Cleaning Decisions

> [!warning] Recorded transformations, not validated outcomes
> This note documents what the SQL script does and what the imported PBIX contains. It does not claim that every transformation was correct, that each statement executed, or that the resulting values are financially validated. Where the script gives no explicit reason, the reason is marked **INFERRED**.

## Decision register

| # | Original issue | Transformation recorded | Reason (established or inferred) | Potential effect | Evidence | Remaining concern |
|---:|---|---|---|---|---|---|
| 1 | Status has mixed case and whitespace-only values | Whitespace-only → `NULL`; remaining text Title Cased | Separate missing from real status; standardise labels | `active`, `ACTIVE`, `CANCELLED` become `Active`, `Cancelled`; blank becomes null | `SQL-RECORDED`; PBIX confirms Title Case | Null status meaning is undefined; 1,673 rows (16.73%) |
| 2 | MRR contains `$` and commas | `REPLACE` removes `$` and `,` | Make values castable to numeric | Values become parseable; no type change in SQL | `SQL-RECORDED` | `mrr_amount` is never altered to a numeric type in SQL |
| 3 | MRR has leading negative signs | `REPLACE(mrr_amount, '-', '')` on `-%` values | Not stated; inferred intent was to make values positive | Negative values become positive revenue | `SQL-RECORDED`; PBIX has no negatives | **Financial correctness unresolved** |
| 4 | MRR has blank values | Exact blanks → `NULL` | Preserve missing as missing | 461 nulls in PBIX; excluded from `SUM` | `SQL-RECORDED` | Whitespace-only non-exact blanks may not be caught |
| 5 | Acquisition channel has blanks | Whitespace-only → `Unknown` | Make missing channel explicit | 2,096 fact rows with `Unknown`; $8.28M all-row MRR | `SQL-RECORDED`; PBIX confirms | `Unknown` is not a real channel; upstream cause unknown |
| 6 | Plan names have inconsistent casing/spelling | `CASE` maps `start%`, `growth%`, `enterprise%`, `ent_l1%`; blanks/unrecognised → `NULL` | Standardise the three known plans | `Unassigned` created later in Power Query | `SQL-RECORDED`; PBIX confirms | Mapping is heuristic; source catalogue absent |
| 7 | `region_tier` combines two attributes | Split into `region` and `tier`; drop `region_tier` | Normalise a combined field | Region/tier available separately | `SQL-RECORDED`; PBIX confirms | Brittle parsing; source dictionary absent |
| 8 | Customer IDs have multiple formats | `CUST-` + final four characters | Standardise identifier format | 1,200 unique IDs in PBIX | `SQL-RECORDED`; PBIX confirms | Possible collisions; original IDs lost |
| 9 | Signup dates have several text formats | Three-pattern `STR_TO_DATE`; replace column | Produce a real `DATE` | Dates range 2021-01-01 to 2025-12-06 | `SQL-RECORDED`; PBIX confirms | Exact conversion count unverified; format assumptions |
| 10 | Cancellation dates are often blank and text | Blank → `NULL`; `MODIFY DATE`; no full `STR_TO_DATE` path | Produce a nullable date | 6,743 nulls; dates range to 2026-11-23 | `SQL-RECORDED`; PBIX confirms | Full mixed-format parsing unverified |
| 11 | CAC has blanks | Blank → `NULL`; `MODIFY DECIMAL(10,2)` | Preserve missing as missing | 827 nulls; mean 4,473.58 | `SQL-RECORDED`; PBIX confirms | Meaning of CAC per row undefined |
| 12 | Potential duplicates | `ROW_NUMBER()` CTE; delete by `transaction_id`; re-check | Remove duplicates | 10,000 unique transaction IDs in PBIX | `SQL-RECORDED`; PBIX confirms only the output | Logic is unsafe; effect unverified |
| 13 | Customer attributes conflict | Rank by `signup_date DESC`; keep row 1 per customer | Build a one-row dimension | 1,200 unique customers | `SQL-RECORDED`; PBIX confirms shape | Not a historised dimension; ties unresolved |

## 1. Status: blanks, casing, and meaning

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET status = NULL
WHERE TRIM(status) = '';

UPDATE vectra_analytics.stg_vectra_raw
SET status = CONCAT(
  UPPER(LEFT(status, 1)),
  LOWER(SUBSTRING(status, 2))
);
```

### What this does

- Whitespace-only values become `NULL`.
- `active` becomes `Active`; `CANCELLED` becomes `Cancelled`; `CHURNED` becomes `Churned`.
- It does not trim internal spaces or create a status codebook.

### What the imported model shows

| Status | Rows | Share |
|---|---:|---:|
| `Active` | 3,396 | 33.96% |
| `Cancelled` | 1,692 | 16.92% |
| `Churned` | 1,565 | 15.65% |
| `Downgraded` | 1,674 | 16.74% |
| `NULL` | 1,673 | 16.73% |

### Why it matters

The project intended to preserve a distinction between `Churned` and `Cancelled`. The SQL does not define either term. The Power Query layer later merges both into `status_cleaned = "Churned"` and maps `Downgraded` to `Active`. The active DAX measures, however, use raw `status = "Cancelled"` for churn. The same business concept is therefore represented three ways:

- raw `status` (four values plus null),
- `status_cleaned` (three values),
- DAX filters (only `Cancelled`).

> [!warning] Unresolved
> The business meaning of `Cancelled`, `Churned`, `Downgraded`, and null is not documented. Any churn conclusion depends on a taxonomy the project has not established.

## 2. MRR: currency symbols, commas, and blanks

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(REPLACE(mrr_amount, '$', ''), ',', '')
WHERE mrr_amount LIKE '%$%' OR mrr_amount LIKE '%,%';

UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = NULL
WHERE TRIM(mrr_amount) = '';
```

### What this does

- Removes `$` and comma separators from matching values.
- Converts exact blank strings to `NULL`.
- Leaves the column type unchanged in SQL.
- Does not trim nonblank values before the `REPLACE`.

### What the imported model shows

| Check | Result |
|---|---:|
| Non-null MRR rows | 9,539 |
| Null MRR rows | 461 (4.61%) |
| Negative MRR rows | 0 |
| Minimum | 299 |
| Median | 2,499 |
| Maximum | 12,000 |
| Sum | $39,146,742 |
| Mean (non-null) | 4,103.86 |

### Why it matters

`SUM(mrr_amount)` ignores the 461 nulls. The measure is an all-row total, not a current-MRR or net-revenue measure. The absence of negatives is a result of the sign-removal step, not independent evidence that no legitimate negative values existed.

**Remaining concern:** the SQL never alters `mrr_amount` to `DECIMAL`. The PBIX imports it as a double, but the SQL column type and the conversion path are not documented. See [[04 - SQL Development Timeline]].

## 3. Negative MRR: the most consequential decision

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(mrr_amount, '-', '')
WHERE mrr_amount LIKE '-%';
```

### What this does

It removes every hyphen from values that begin with `-`, turning a negative amount into a positive amount. It does not record the original value, the count, the customer, or the reason.

### Why it is not a formatting fix

A negative MRR value could represent:

- A data-entry error.
- A refund.
- A credit or service-level credit.
- A reversal or adjustment.
- A legitimate negative contract value.
- A synthetic-data artifact.

The script establishes none of these. The imported model has no negative values, so any downstream total is computed after the sign change. That makes the revenue total internally consistent with the transformed data but does not make it financially correct.

> [!danger] Business-rule review required
> The negative-sign removal must be reviewed against the source system’s financial rules before any revenue figure is treated as validated. A defensible treatment would preserve the original value, classify the reason, and apply an explicit policy: keep, exclude, or reclassify. This is **RECOMMENDED**, not implemented.

## 4. Acquisition channel: blanks to `Unknown`

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET acquisition_channel = 'Unknown'
WHERE TRIM(acquisition_channel) = '';
```

### What the imported model shows

| Channel | Fact rows | MRR sum | MRR share |
|---|---:|---:|---:|
| Direct Sales | 2,047 | $7,945,041 | 20.30% |
| Organic Search | 1,864 | $7,255,862 | 18.54% |
| Paid Ads | 1,969 | $7,810,811 | 19.95% |
| Partner Referral | 2,024 | $7,858,452 | 20.07% |
| `Unknown` | 2,096 | $8,276,576 | 21.14% |

### Why it matters

`Unknown` is an explicit bucket, not an inferred channel. That is better than silently assigning a plausible channel. But 21.14% of all-row MRR sitting in `Unknown` is a material attribution gap, not a channel performance result.

**Remaining concern:** the source of the blank channel values is not investigated. The script profiles blanks by plan and region but does not establish a root cause.

## 5. Plan type: heuristic mapping and Unassigned

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET plan_type = CASE
  WHEN LOWER(TRIM(plan_type)) LIKE 'start%' THEN 'Starter'
  WHEN LOWER(TRIM(plan_type)) LIKE 'growth%' THEN 'Growth'
  WHEN LOWER(TRIM(plan_type)) LIKE 'enterprise%'
       OR LOWER(TRIM(plan_type)) LIKE 'ent_l1%' THEN 'Enterprise'
  WHEN LOWER(TRIM(plan_type)) = '' THEN NULL
  ELSE NULL
END;
```

### What this does

- Maps variants beginning with `start`, `growth`, `enterprise`, or `ent_l1` to three labels.
- Sends blank and unrecognised values to `NULL`.
- Does not create `Unassigned` in SQL.
- Does not record the original unmapped values.

Power Query later replaces null `plan_type` with `Unassigned`.

### What the imported model shows

| Plan | Rows | MRR sum | MRR share | Distinct customers with a row |
|---|---:|---:|---:|---:|
| Enterprise | 3,656 | $14,147,984 | 36.14% | 1,143 |
| Growth | 2,493 | $10,106,914 | 25.82% | 1,044 |
| Starter | 2,619 | $10,163,091 | 25.96% | 1,073 |
| Unassigned | 1,232 | $4,728,753 | 12.08% | 781 |

### Why it matters

- The mapping is a text heuristic, not a product catalogue.
- Unrecognised values are not preserved, so the business cannot see what failed to map.
- `Unassigned` is a reporting category, not a plan.
- The $4.73M / 12.08% figure is revenue exposure from unmapped plan attributes, not a separately earned revenue stream.

**Remaining concern:** the source value list and the upstream plan-mapping rules are absent. The project cannot prove that every legitimate plan was mapped.

## 6. Region and tier: splitting a combined field

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET region = SUBSTRING_INDEX(SUBSTRING_INDEX(region_tier, '_', 1), '|', 1);

UPDATE vectra_analytics.stg_vectra_raw
SET tier = CASE
  WHEN UPPER(TRIM(region_tier)) = 'UNKNOWN' THEN 'UNKNOWN'
  ELSE CONCAT('TIER_', RIGHT(TRIM(region_tier), 1))
END;

ALTER TABLE vectra_analytics.stg_vectra_raw
DROP COLUMN region_tier;
```

### What this does

- `region` = text before the first `_`, then before the first `|`.
- `tier` = `UNKNOWN` or `TIER_` plus the last character.
- The original combined field is dropped.

### What the imported model shows

| Region | Customers | Tier | Customers |
|---|---:|---|---:|
| AMER | 388 | TIER_1 | 397 |
| APAC | 194 | TIER_2 | 402 |
| EMEA | 217 | TIER_3 | 195 |
| LATAM | 195 | UNKNOWN | 206 |
| UNKNOWN | 206 | | |

### Why it matters

The split is brittle. A source value ending in `10` would become `TIER_0`; a region containing an underscore would be truncated. The source dictionary is not available, so full validation of malformed values is **UNVERIFIED**.

## 7. Customer ID: normalisation, not identity resolution

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET customer_id = CONCAT('CUST-', RIGHT(TRIM(customer_id), 4));
```

### What this does

- Discards the prefix and any characters before the final four.
- Rebuilds every ID as `CUST-` plus those four characters.
- Compares the last four characters before and after through a backup join.

### What the imported model shows

- 1,200 unique `customer_id` values in `dim_customers`.
- 1,200 distinct customers in `fact_subscriptions`.
- No fact customer missing from the dimension.
- No duplicate dimension keys.

### Why it matters

The output shape is consistent, but the rule assumes the final four characters uniquely identify the customer. If two original IDs shared the same last four characters, they would collapse into one `CUST-` value. The script does not test for that. **Collision-free identity is UNVERIFIED.**

A safer approach would preserve the original ID, build a mapping table, and test for collisions before replacing the key. That is **RECOMMENDED**, not implemented.

## 8. Signup date: three-format parsing

### Recorded treatment

```sql
CASE
  WHEN signup_date LIKE '%-%-%' AND signup_date REGEXP '[a-zA-Z]'
    THEN STR_TO_DATE(signup_date, '%d-%b-%Y')
  WHEN signup_date LIKE '%-%-%'
    THEN STR_TO_DATE(signup_date, '%Y-%m-%d')
  WHEN signup_date LIKE '%/%/%'
    THEN STR_TO_DATE(signup_date, '%m/%d/%Y')
  ELSE NULL
END
```

The script writes the result to `signup_date1`, creates `backup12`, drops the old text column, and renames `signup_date1`.

### What the imported model shows

| Signup year | Rows |
|---|---:|
| 2021 | 2,010 |
| 2022 | 1,984 |
| 2023 | 2,023 |
| 2024 | 2,024 |
| 2025 | 1,959 |

Range: 2021-01-01 to 2025-12-06.

### Why it matters

The slash-format interpretation (`MM/DD/YYYY`) is supported by the project history: approximately 2,981 slash dates were investigated, all had a first component from 1 to 12, and 1,742 had a second component from 13 to 31. That evidence is **CONVERSATION-RECORDED**; the exact query output is not attached.

The dash-format branch assumes either `DD-Mon-YYYY` or `YYYY-MM-DD`. A numeric `DD-MM-YYYY` value would be misread by the `%Y-%m-%d` branch if it happened to parse. The project does not show a complete format census.

**Remaining concern:** exact conversion success and NULL counts are not attached. The PBIX dates are plausible, but that is not a format-level validation.

## 9. Cancellation date: blank handling without full parsing

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET cancellation_date = NULL
WHERE cancellation_date = '';

ALTER TABLE vectra_analytics.stg_vectra_raw
MODIFY cancellation_date DATE;
```

### What the imported model shows

- 6,743 null cancellation dates (67.43%).
- Non-null range: 2021-02-09 to 2026-11-23.
- 319 rows with a 2026 cancellation date.
- 371 rows with a cancellation date after the maximum signup date (2025-12-06).
- 5 rows with a cancellation date after 2026-11-03.
- 0 rows with cancellation before signup.
- All `Cancelled`/`Churned` rows have a cancellation date; all `Active`/`Downgraded`/null-status rows do not.

### Why it matters

The blank-to-`NULL` rule and the type change are not equivalent to the signup-date conversion. The script has no full `STR_TO_DATE` path for cancellation dates. If the nonblank values were not already in a MySQL-recognised format, the `MODIFY` could coerce, truncate, or fail. The imported model has valid dates, but the SQL path is **UNVERIFIED**.

The blank interpretation was recorded as “no cancellation date recorded,” not a synthetic date. That is reasonable for active records. It does not explain why 6,743 rows are blank, or whether some blanks are missing data rather than non-cancellation.

## 10. CAC: preserving missing values

### Recorded treatment

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET cac_cost = NULL
WHERE cac_cost = '';

ALTER TABLE vectra_analytics.stg_vectra_raw
MODIFY cac_cost DECIMAL(10,2);
```

### What the imported model shows

| Check | Result |
|---|---:|
| Non-null CAC rows | 9,173 |
| Null CAC rows | 827 (8.27%) |
| Mean CAC (non-null rows) | 4,473.58 |
| Minimum | 500.82 |
| Maximum | 8,497.93 |
| Sum of CAC | $41,036,103.67 |

### Why it matters

`Average Customer CAC` is `AVERAGE(cac_cost)` across subscription rows. It is not a per-customer acquisition cost. If the business wants CAC per acquired customer, it needs a denominator of acquired customers and a definition of which rows represent acquisition events. That definition is not documented.

## 11. Duplicates: attempted deletion with unsafe logic

### Recorded treatment

```sql
WITH RankedDuplicate AS (
  SELECT transaction_id,
    ROW_NUMBER() OVER (
      PARTITION BY transaction_id, customer_id, signup_date,
                   plan_type, mrr_amount, region
    ) AS row_num
  FROM vectra_analytics.stg_vectra_raw
)
DELETE FROM vectra_analytics.stg_vectra_raw
WHERE transaction_id IN (
  SELECT transaction_id FROM RankedDuplicate WHERE row_num > 1
);
```

### What the imported model shows

- 10,000 unique `transaction_id` values.
- 0 duplicate full business combinations by customer, signup date, plan, MRR, and region.
- 24 customer/signup groups containing 48 rows; these differ by plan or MRR and are not duplicates by the full combination.

### Why it matters

If `transaction_id` is unique, the CTE assigns `row_num = 1` to every row and the delete removes nothing. If `transaction_id` is not unique, the delete can remove every row sharing that ID, not just the extra copies. There is no `ORDER BY`, so retention is nondeterministic. The final check uses a different duplicate definition from the CTE.

**The imported model’s unique transaction IDs do not validate the delete.** They may simply mean the delete had nothing to remove. See [[04 - SQL Development Timeline]].

## 12. Customer attribute conflicts and the latest-signup policy

The project history reports approximately **1,198** customer IDs associated with conflicting region, tier, or acquisition-channel values. The exact counting unit and query output are not attached, so this is **CONVERSATION-RECORDED / UNVERIFIED**.

The SQL resolves conflicts by ranking rows per customer by `signup_date DESC` and keeping row 1. This:

- Produces one row per customer in the output.
- Uses the latest signup record’s attributes.
- Does not prove those attributes are the customer’s current master data.
- Does not preserve attribute history.
- Has no tie-breaker for equal latest dates.

This is a **latest-signup-record selection policy**, not a slowly changing dimension. See [[06 - Data Model and Grain]].

## Cleaning outcome summary

| Area | PBIX-visible outcome | Interpretation |
|---|---|---|
| Status | 1,673 nulls; four Title Case values | Cleaning applied; taxonomy unresolved |
| MRR | 461 nulls; no negatives; $39.15M sum | Symbol/sign cleaning applied; financial correctness unresolved |
| Channel | 2,096 `Unknown` rows; $8.28M | Explicit missing bucket; attribution gap |
| Plan | 1,232 `Unassigned` rows; $4.73M | Explicit reporting bucket; upstream mapping gap |
| Region/tier | 206 `UNKNOWN` customers | Explicit unknown; parsing dictionary absent |
| Customer ID | 1,200 unique `CUST-` values | Output shape consistent; collisions unverified |
| Signup date | 2021–2025 date range | Conversion applied; exact success count unverified |
| Cancellation date | 6,743 nulls; dates to 2026 | Blank handling applied; full parsing unverified |
| CAC | 827 nulls; mean 4,473.58 | Missing preserved; per-row semantics unclear |
| Duplicates | 10,000 unique transaction IDs | Output unique; delete logic unvalidated |
| Customer dimension | 1,200 unique customers | One row per customer; history lost |

## Related notes

- [[04 - SQL Development Timeline]]
- [[06 - Data Model and Grain]]
- [[08 - DAX and KPI Dictionary]]
- [[13 - Validation and Evidence Register]]
