---
title: "04 - SQL Development Timeline"
tags:
  - vectra
  - note/sql
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# SQL Development Timeline

> [!warning] This is a script, not an execution log
> The evidence is a 692-line MySQL development script, `vectra_subscription_analytics.sql.sql` (called `jj.sql` in the audited handover). The script proves which statements were written. It does **not** prove that they ran successfully, in the displayed order, or against the final data. Query outputs, DDL, row counts, and constraint states were not supplied.

## How to read the timeline

The script is an in-place cleaning script. It repeatedly:

1. Profiles a column.
2. Creates a backup table.
3. Updates the staging table.
4. Queries the result.

The backups are snapshots at different stages, not untouched copies of the raw source. There is no transaction wrapper, no rollback, and no idempotency guard. Re-running the script on an already-cleaned table would not reproduce the same starting state.

## Phase summary

| Phase | Lines | Main operation | Purpose | Destructive? | Evidence |
|---|---:|---|---|---|---|
| 1. Profiling | 1–45 | `COUNT`, `DESCRIBE`, distinct status, null/whitespace checks, cancellation and signup probes | Understand the raw data before changing it | No | `SQL-RECORDED` |
| 2. Status missing values | 47–75 | Whitespace-only `status` → `NULL`; count nulls | Separate “blank” from a real status | Yes, in place | `SQL-RECORDED` |
| 3. MRR profiling and cleaning | 77–223 | Profile `$`, commas, negatives, zeros, letters, decimals; remove symbols; remove minus signs; blanks → `NULL`; backups | Make MRR numerically usable | Yes, in place; financial sign change | `SQL-RECORDED`; sign correctness `UNVERIFIED` |
| 4. Status casing | 225–252 | Title Case remaining status text; check uppercase absence | Standardise `active`, `ACTIVE`, `CANCELLED` | Yes | `SQL-RECORDED` |
| 5. Acquisition channel | 254–299 | Profile blanks by plan/region; blanks → `Unknown`; backup | Make missing channel explicit | Yes | `SQL-RECORDED` |
| 6. Plan type | 301–335 | Map `start%`, `growth%`, `enterprise%`, `ent_l1%`; blanks/unrecognised → `NULL`; backup | Standardise plan labels | Yes | `SQL-RECORDED` |
| 7. Region and tier | 337–400 | Split `region_tier` into `region` and `tier`; drop the source column; backups | Normalise a combined attribute | Yes; drops a column | `SQL-RECORDED` |
| 8. Customer ID | 402–436 | `CUST-` + final four characters; compare to backup | Standardise identifier format | Yes; identity-changing | `SQL-RECORDED`; collision-free result `UNVERIFIED` |
| 9. Signup date | 438–546 | Add `signup_date1`; parse three text patterns; drop old column; rename; backup | Produce a real `DATE` | Yes; drops a column | `SQL-RECORDED` |
| 10. Cancellation date | 548–600 | Blank → `NULL`; alter to `DATE`; backup | Produce a nullable date | Yes; type change | `SQL-RECORDED`; full format parsing `UNVERIFIED` |
| 11. CAC | 602–614 | Blank → `NULL`; alter to `DECIMAL(10,2)` | Preserve missing CAC as missing | Yes; type change | `SQL-RECORDED` |
| 12. Duplicates | 616–640 | `ROW_NUMBER()` CTE; delete by `transaction_id`; re-check | Remove duplicates | Yes; deletes rows | `SQL-RECORDED`; correctness `UNVERIFIED` |
| 13. Fact table | 644–670 | `CREATE TABLE ... AS SELECT` eight columns; add PK and FK | Build the analytical fact | Creates a table; may fail on FK | `SQL-RECORDED`; execution `UNVERIFIED` |
| 14. Customer dimension | 672–692 | Rank by `signup_date DESC`; keep row 1; add PK | Build a one-row-per-customer dimension | Creates a table | `SQL-RECORDED`; semantic validity `UNVERIFIED` |

## Phase 1 — Initial profiling (lines 1–45)

The script starts with a row count, `DESCRIBE`, a case-sensitive distinct status query, status counts, null/whitespace checks, cancellation-date/status combinations, and a signup-date format probe.

```sql
SELECT COUNT(*) 
FROM vectra_analytics.stg_vectra_raw;

DESCRIBE vectra_analytics.stg_vectra_raw;

SELECT DISTINCT status 
COLLATE utf8mb4_bin AS case_sensitive_status
FROM vectra_analytics.stg_vectra_raw;
```

**What it was intended to accomplish:** establish the dataset size, column structure, status spellings, missing-value patterns, and date formats before transformation.

**What it does not establish:** the actual row count, the actual distinct statuses, or the actual date-format distribution. No output is attached. The `WHERE STR_TO_DATE(signup_date, '%d-%M-%Y')` probe is a filter, not a count, and the `%M` token expects a month name rather than a numeric month.

## Phase 2 — Status missing values (lines 47–75)

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET status = NULL
WHERE TRIM(status) = '';
```

This separates whitespace-only status from a real status. The follow-up queries count nulls and confirm that whitespace-only values no longer match.

**Consequence:** `status` now has a genuine `NULL` category. In the imported model, that category has 1,673 rows (16.73%). The business meaning of a null status is not documented.

## Phase 3 — MRR profiling and cleaning (lines 77–223)

The script profiles:

- Null or blank `mrr_amount`.
- `$` symbols.
- Comma separators.
- Negative values.
- Zero values.
- Alphabetic characters.
- Decimal values.

It previews a cleaned expression:

```sql
CASE
  WHEN TRIM(mrr_amount) = '' OR mrr_amount IS NULL THEN NULL
  ELSE CAST(
    REPLACE(REPLACE(TRIM(mrr_amount), '$', ''), ',', '')
    AS DECIMAL(10, 2)
  )
END AS cleaned_value
```

It then removes `$` and commas in place:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(REPLACE(mrr_amount, '$', ''), ',', '')
WHERE mrr_amount LIKE '%$%' OR mrr_amount LIKE '%,%';
```

After that it creates `stg_vectra_raw_backup`, then removes leading minus signs:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(mrr_amount, '-', '')
WHERE mrr_amount LIKE '-%';
```

> [!danger] Negative MRR is a financial decision, not a formatting fix
> `REPLACE(mrr_amount, '-', '')` turns a negative value into a positive one. The script does not establish whether the original values were data-entry errors, refunds, credits, reversals, or legitimate adjustments. The imported model has no negative MRR values, but that is a consequence of the transformation, not evidence that the transformation was correct. The financial meaning remains **UNVERIFIED**.

The script then creates `stg_vectra_raw_backup2` and converts exact blank strings to `NULL`:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = NULL
WHERE TRIM(mrr_amount) = '';
```

**Important missing step:** the script never alters `mrr_amount` to a numeric type. The `CAST` appears only in a preview `SELECT`. The fact table is created with `CREATE TABLE ... AS SELECT`, so it inherits the staging column type. The PBIX imports `mrr_amount` as a double, which suggests Power Query or the MySQL driver coerced it, but the SQL type is not documented. This is a reproducibility gap, not proof of failure.

## Phase 4 — Status casing (lines 225–252)

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET status = CONCAT(
  UPPER(LEFT(status, 1)),
  LOWER(SUBSTRING(status, 2))
);
```

This produces Title Case forms such as `Active`, `Cancelled`, `Churned`, and `Downgraded`. It does **not** produce uppercase `ACTIVE` or `CHURNED`. The imported model confirms those Title Case values.

The handover’s later DAX examples that filter `status_cleaned = "CHURNED"` do not match the active model. The active churn measures filter `status = "Cancelled"`. See [[08 - DAX and KPI Dictionary]].

## Phase 5 — Acquisition channel (lines 254–299)

The script profiles blank `acquisition_channel` values against `plan_type` and `region_tier`, creates `stg_vectra_raw_backup4`, and replaces whitespace-only values:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET acquisition_channel = 'Unknown'
WHERE TRIM(acquisition_channel) = '';
```

This is an explicit unknown-category treatment. It does **not** infer a channel from plan or region. The imported model has 2,096 fact rows with `Unknown` channel and $8,276,576 of all-row MRR in that category (21.14%).

## Phase 6 — Plan type (lines 301–335)

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

Recognised variants become `Starter`, `Growth`, or `Enterprise`. Blank and unrecognised values become `NULL`. The SQL does **not** create an `Unassigned` value; that happens in Power Query, where null `plan_type` is replaced with `Unassigned` and empty `plan_type_cleaned` is mapped to `Unassigned`.

The source plan catalogue is not documented. The mapping is a text heuristic, not a validated product hierarchy.

## Phase 7 — Region and tier (lines 337–400)

The script inspects distinct `region_tier` values, adds `region` and `tier`, and populates them:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET region = SUBSTRING_INDEX(
  SUBSTRING_INDEX(region_tier, '_', 1),
  '|', 1);

UPDATE vectra_analytics.stg_vectra_raw
SET tier = CASE
  WHEN UPPER(TRIM(region_tier)) = 'UNKNOWN' THEN 'UNKNOWN'
  ELSE CONCAT('TIER_', RIGHT(TRIM(region_tier), 1))
END;
```

The region expression takes the text before the first `_`, then before the first `|`. The tier expression takes the final character of the source value. This works for values shaped like `AMER_TIER_1` or `UNKNOWN`, but it is brittle: a value ending in `10` would become `TIER_0`, and a region containing an underscore would be truncated.

After validating counts, the script creates `stg_vectra_raw_backup8` and drops `region_tier`. The source dictionary is not available, so full validation of every malformed value is **UNVERIFIED**.

## Phase 8 — Customer ID (lines 402–436)

The script counts uppercase `CUST-`, lowercase `cust-`, and numeric-only patterns, then rewrites every identifier:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET customer_id = CONCAT('CUST-', RIGHT(TRIM(customer_id), 4));
```

A later query compares the last four characters before and after the update through `stg_vectra_raw_backup9`.

> [!warning] This is identifier normalisation, not identity resolution
> The rule assumes the final four characters uniquely identify a customer. The script does not prove that no two distinct source identifiers share the same final four characters. The imported dimension has 1,200 unique `CUST-` values, but that is the post-normalisation result, not a collision test against the original identifiers.

## Phase 9 — Signup date (lines 438–546)

The script:

1. Creates `stg_vectra_raw_backup10`.
2. Adds `signup_date1 DATE`.
3. Creates `stg_vectra_raw_backup11`.
4. Profiles slash-formatted dates.
5. Previews rows where the conversion would return `NULL`.
6. Updates `signup_date1` with three patterns.
7. Creates `stg_vectra_raw_backup12`.
8. Drops the original `signup_date`.
9. Renames `signup_date1` to `signup_date`.

The conversion logic:

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

The handover records that approximately 2,981 slash-formatted dates were investigated; all had a first component from 1 to 12, and 1,742 had a second component from 13 to 31, supporting `MM/DD/YYYY` for the inspected values. That count and conclusion are **CONVERSATION-RECORDED**, not an attached query output.

The imported model has signup dates from 2021-01-01 to 2025-12-06. The exact number of successful conversions and the number of `NULL` results are not attached. The script’s “no NULL” preview is a query, not a retained result.

## Phase 10 — Cancellation date (lines 548–600)

The script investigates blanks and date-format patterns, creates `stg_vectra_raw_backup13`, and runs:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET cancellation_date = NULL
WHERE cancellation_date = '';

ALTER TABLE vectra_analytics.stg_vectra_raw
MODIFY cancellation_date DATE;
```

> [!warning] Asymmetric date cleaning
> Signup date has an explicit multi-format `STR_TO_DATE` conversion. Cancellation date has blank-to-`NULL` handling and a type alteration, but no equivalent full parsing path. If nonblank cancellation values were not already in a MySQL-recognised date format, the `MODIFY` could coerce, truncate, or fail depending on SQL mode. The imported model contains valid dates, but the SQL conversion path is not fully documented.

The format-count query at lines 559–563 has questionable labels: `%m%d%Y` is labelled `'YYYY-MM-DD'`, `%d-%m-%Y` is labelled `'DD-MM-YYYY'`, and `%Y-%m-%d` is also labelled `'DD-MM-YYYY'`. The counts overlap and the labels do not establish the actual formats.

The imported model has 6,743 null cancellation dates, consistent with the handover’s recorded count. All `Cancelled` and `Churned` rows have a cancellation date; all `Active`, `Downgraded`, and null-status rows have none. That is internal consistency, not proof that the SQL parsing was correct.

## Phase 11 — CAC (lines 602–614)

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET cac_cost = NULL
WHERE cac_cost = '';

ALTER TABLE vectra_analytics.stg_vectra_raw
MODIFY cac_cost DECIMAL(10,2);
```

This preserves missing CAC as missing rather than replacing it with zero. The imported model has 827 null `cac_cost` rows and a mean of 4,473.58 across the 9,173 non-null rows. Whether `cac_cost` is per customer, per acquisition, or allocated across rows is not documented.

## Phase 12 — Duplicate investigation and deletion (lines 616–640)

The script inspects one customer/date combination, then defines:

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
  SELECT transaction_id
  FROM RankedDuplicate
  WHERE row_num > 1
);
```

> [!danger] The duplicate logic is not safe as written
> - Partitioning by `transaction_id` means a unique transaction ID always receives `row_num = 1`; if transaction IDs are unique, the delete is a no-op.
> - If transaction IDs repeat, every row with that ID can be deleted, not just the intended duplicate.
> - The partition omits `cac_cost`, `status`, and `cancellation_date`, so rows differing in those fields can be grouped together.
> - There is no `ORDER BY`, so which row is “first” is not deterministic.
> - The final duplicate check groups by customer, signup date, plan type, MRR, and region — a different definition from the CTE.

The imported model has 10,000 unique transaction IDs and no duplicate full business combinations. That does not validate the delete; it may simply mean the delete had nothing to remove.

## Phase 13 — Fact table (lines 644–670)

```sql
CREATE TABLE fact_subscriptions AS
SELECT transaction_id, customer_id, signup_date, plan_type,
       mrr_amount, cac_cost, status, cancellation_date
FROM vectra_analytics.stg_vectra_raw
GROUP BY transaction_id, customer_id, signup_date, plan_type,
         mrr_amount, cac_cost, status, cancellation_date;

ALTER TABLE fact_subscriptions
ADD PRIMARY KEY (transaction_id),
ADD FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id);
```

The `GROUP BY` across all eight columns behaves like a distinct projection. The primary key enforces `transaction_id` uniqueness only if the data already satisfies it. The foreign key references `dim_customers`, but **the dimension table is created later in the script** (lines 673–684). On a fresh database, the foreign-key statement could fail because the referenced table does not yet exist.

**Evidence status:** the statements are `SQL-RECORDED`; the final PK/FK state is `UNVERIFIED`. The PBIX has an active model relationship, but that is a Power BI relationship, not proof of a MySQL foreign key.

## Phase 14 — Customer dimension (lines 672–692)

```sql
CREATE TABLE dim_customers AS
SELECT customer_id, region, tier, acquisition_channel
FROM (
  SELECT customer_id, region, tier, acquisition_channel,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id ORDER BY signup_date DESC
    ) AS row_num
  FROM vectra_analytics.stg_vectra_raw
) ranked_customers
WHERE row_num = 1;

ALTER TABLE dim_customers
ADD PRIMARY KEY (customer_id);
```

This is the **latest-signup-record customer attribute selection policy**:

- It returns at most one row per `customer_id` if `ROW_NUMBER()` behaves as expected.
- It selects region, tier, and acquisition channel from the row with the latest `signup_date`.
- It does not preserve attribute history.
- It has no tie-breaker for two rows sharing the latest `signup_date`.
- It does not prove that the selected attributes are the customer’s true current master-data attributes.

The imported dimension has 1,200 unique customer IDs. That confirms the output shape, not the semantic correctness of the selected attributes.

## Backup history

| Backup | Created after / before | What it captures |
|---|---|---|
| `stg_vectra_raw_backup` | After `$`/comma removal, before negative-sign removal | Currency/comma-cleaned values, still possibly negative |
| `stg_vectra_raw_backup2` | After negative-sign removal, before blank MRR → `NULL` | Sign-stripped values, blanks still present |
| `stg_vectra_raw_backup3` | After blank MRR → `NULL`, before status Title Case | MRR nulls applied; status still mixed case |
| `stg_vectra_raw_backup4` | After status Title Case, before channel `Unknown` | Cleaned status, blank channel |
| `stg_vectra_raw_backup5` | After channel `Unknown`, before plan mapping | Channel explicit unknowns, raw plan values |
| `stg_vectra_raw_backup6` | After plan mapping, before region/tier columns | Standard plan labels, original `region_tier` |
| `stg_vectra_raw_backup7` | After adding `region`/`tier` columns, before populating region | Empty new columns, original `region_tier` |
| `stg_vectra_raw_backup8` | After region/tier population, before dropping `region_tier` | Split attributes plus original field |
| `stg_vectra_raw_backup9` | After dropping `region_tier`, before customer-ID rewrite | Old customer IDs, split attributes |
| `stg_vectra_raw_backup10` | After customer-ID rewrite, before adding `signup_date1` | Normalised IDs, text signup date |
| `stg_vectra_raw_backup11` | After adding `signup_date1`, before populating it | Empty date column, text signup date |
| `stg_vectra_raw_backup12` | After populating `signup_date1`, before drop/rename | Both old text and new date |
| `stg_vectra_raw_backup13` | Before cancellation blank → `NULL`/type change | Clean signup date, text cancellation date |
| `stg_vectra_raw_backup14` | After cancellation type change, before CAC blank → `NULL` | Date cancellation, text CAC |

> [!note] Backup names are not phase numbers
> `stg_vectra_raw_backup` and `stg_vectra_raw_backup12` are different snapshots, not duplicates. None of them is guaranteed to be an untouched raw copy.

## Destructive and non-rerunnable operations

- In-place `UPDATE` statements alter the only staging table.
- `DROP COLUMN signup_date` and `DROP COLUMN region_tier` remove source fields.
- `DELETE` removes rows from staging.
- `CREATE TABLE ... AS SELECT` creates tables without explicit column types or constraints beyond the later `ALTER`.
- The script has no transaction, no `IF EXISTS`, no idempotency guard, and no rollback.
- Running it twice would not reproduce the same starting state.

These are acceptable for a development script kept as an audit trail, but not for a clean, rerunnable production pipeline.

## What the script proves — and what it does not

| Claim | What the script proves | What remains unverified |
|---|---|---|
| Status was cleaned | The null and Title Case statements are written | Actual counts and final values |
| MRR was cleaned | `$`, commas, and `-` are removed; blanks → `NULL` | Whether sign removal was correct; final SQL type |
| Plan was mapped | A `CASE` maps recognised variants | Full source value coverage; `Unassigned` is Power Query-side |
| Customer IDs were normalised | `CUST-` + last four is written | Collision-free identity |
| Signup dates were parsed | Three formats are handled | Exact conversion count and NULL count |
| Cancellation dates were typed | Blank → `NULL`; `MODIFY DATE` | Full mixed-format parsing |
| Duplicates were removed | A CTE delete is written | Whether it ran, what it removed, and whether the logic is correct |
| Fact/dim tables were built | CTAS and PK/FK statements are written | Execution order, final constraints, final row counts |
| Customer dimension is unique | Ranking keeps row 1 per ID | Tie behaviour and semantic correctness |

See [[13 - Validation and Evidence Register]] for the claim-level register.

## Related notes

- [[03 - Dataset and Data Dictionary]]
- [[05 - Data Cleaning Decisions]]
- [[06 - Data Model and Grain]]
- [[12 - Challenges and Decisions]]
