---
title: "07 - Power Query Transformations"
tags:
  - vectra
  - note/power-query
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Power Query Transformations

> [!warning] What was inspectable
> The PBIX contains the saved Power Query (M) expressions for the two imported tables. The expressions were read directly from the model metadata. The Power Query Editor was not opened interactively, and no query-folding trace, refresh log, or step-level diagnostics were available. The M below is the saved expression, not a reconstruction.

## Data source

Both tables use the MySQL connector in import mode:

```powerquery
Source = MySQL.Database(
    "localhost:3306",
    "vectra_analytics",
    [ReturnSingleDatabase=true]
)
```

| Table | Source object | Mode |
|---|---|---|
| `vectra_analytics dim_customers` | `[Schema="vectra_analytics", Item="dim_customers"]` | Import |
| `vectra_analytics fact_subscriptions` | `[Schema="vectra_analytics", Item="fact_subscriptions"]` | Import |

No credentials are stored in the visible expressions. The connection points to a local MySQL instance; the database itself is not included in the vault, so the report cannot be refreshed from this documentation alone.

## Customer dimension query

The dimension query is a direct import with no visible transformations:

```powerquery
let
    Source = MySQL.Database("localhost:3306", "vectra_analytics", [ReturnSingleDatabase=true]),
    vectra_analytics_dim_customers =
        Source{[Schema="vectra_analytics", Item="dim_customers"]}[Data]
in
    vectra_analytics_dim_customers
```

The dimension’s `customer_id`, `region`, `tier`, and `acquisition_channel` columns arrive as text. The one-row-per-customer selection happens in SQL, not in Power Query.

## Fact query: the saved expression

The saved expression is longer than the final logic because it contains two intermediate conditional columns that are added and immediately removed. The final steps are:

```powerquery
let
    Source = MySQL.Database("localhost:3306", "vectra_analytics", [ReturnSingleDatabase=true]),
    fact = Source{[Schema="vectra_analytics", Item="fact_subscriptions"]}[Data],

    // Replace null plan_type values with the reporting category
    #"Replaced Value" = Table.ReplaceValue(
        fact,
        null,
        "Unassigned",
        Replacer.ReplaceValue,
        {"plan_type"}
    ),

    // Final plan_type_cleaned: empty string becomes Unassigned
    #"Added Conditional Column2" = Table.AddColumn(
        #"Replaced Value",
        "plan_type_cleaned",
        each if [plan_type] = "" then "Unassigned" else [plan_type]
    ),

    // Final status grouping
    #"Added Conditional Column3" = Table.AddColumn(
        #"Added Conditional Column2",
        "status_cleaned",
        each
            if [status] = "Active" then "Active"
            else if [status] = "Cancelled" then "Churned"
            else if [status] = "Churned" then "Churned"
            else if [status] = "Downgraded" then "Active"
            else "Unassigned"
    )
in
    #"Added Conditional Column3"
```

> [!note] This is a readable equivalent, not a byte-for-byte copy
> The saved expression uses auto-generated step names such as `#"Added Conditional Column2"` and includes intermediate steps that are removed. The final logic shown above matches the saved final steps. The exact saved text is quoted where it matters below.

### The intermediate dead code

Before the final `plan_type_cleaned` step, the saved expression adds two conditional columns and removes them immediately:

```powerquery
#"Added Conditional Column" = Table.AddColumn(
    fact,
    "plan_type_cleaned",
    each if [plan_type] = " " then "Unassigned" else "[plan_type]"
),
#"Removed Columns" = Table.RemoveColumns(
    #"Added Conditional Column",
    {"plan_type_cleaned"}
),
#"Added Conditional Column1" = Table.AddColumn(
    #"Removed Columns",
    "plan_type_cleaned",
    each if [plan_type] = "  " then "Unassigned" else "[plan_type]"
),
#"Removed Columns1" = Table.RemoveColumns(
    #"Added Conditional Column1",
    {"plan_type_cleaned"}
)
```

Two issues are visible:

1. The `else` branch is the **literal string** `"[plan_type]"`, not the column reference `[plan_type]`. If these columns were not removed, every non-matching row would receive the text `[plan_type]`.
2. The tests are for one space and two spaces. They do not trim arbitrary whitespace.

Because both intermediate columns are removed before the final output, they have no effect on the imported data. They remain a code-quality and maintainability issue, not a data-quality issue in the current snapshot.

## Transformation table

| Step | Actual behaviour | Effect in the imported model | Evidence | Concern |
|---|---|---|---|---|
| Source | MySQL import of `fact_subscriptions` | 10,000 rows | `PBIX-INSPECTED` | Local database not included |
| Replace null `plan_type` | `null` → `"Unassigned"` | No null plan values remain | `PBIX-INSPECTED` | Conflates missing plan with a real plan label |
| `plan_type_cleaned` | `""` → `"Unassigned"`, else `[plan_type]` | 1,232 `Unassigned` rows | `PBIX-INSPECTED` | Does not trim multi-space values |
| `status_cleaned` | `Active` → `Active`; `Cancelled`/`Churned` → `Churned`; `Downgraded` → `Active`; else `Unassigned` | 5,070 Active; 3,257 Churned; 1,673 Unassigned | `PBIX-INSPECTED` | Merges business-distinct statuses |
| Type handling | No explicit `Table.TransformColumnTypes` step is visible in the saved expression | PBIX schema shows `mrr_amount`/`cac_cost` as double and dates as date | `PBIX-INSPECTED`; type promotion `INFERRED` | Type detection is not documented |
| Query folding | Not evidenced | Import mode; transformations are simple | `UNVERIFIED` | No refresh diagnostics |

## Resulting values

### `plan_type_cleaned`

| Value | Rows | MRR sum | Distinct customers with a row |
|---|---:|---:|---:|
| Enterprise | 3,656 | $14,147,984 | 1,143 |
| Growth | 2,493 | $10,106,914 | 1,044 |
| Starter | 2,619 | $10,163,091 | 1,073 |
| Unassigned | 1,232 | $4,728,753 | 781 |

`plan_type_cleaned` is **identical to `plan_type`** in the imported snapshot. The null replacement already removed null plan values, and no empty strings remain. The extra column is therefore redundant in this data, though it may have been intended as a stable reporting layer.

### `status_cleaned`

| Value | Rows | MRR sum | Raw statuses included |
|---|---:|---:|---|
| Active | 5,070 | $19,805,218 | `Active` + `Downgraded` |
| Churned | 3,257 | $13,025,430 | `Cancelled` + `Churned` |
| Unassigned | 1,673 | $6,316,094 | `NULL` status |

## What the transformations mean in plain language

- **Plan type.** If the plan is missing, call it `Unassigned`. Otherwise keep the plan label. The expression does not fix multi-space values or unknown spellings that SQL already turned into nulls.
- **Status.** Treat `Active` as active, treat both `Cancelled` and `Churned` as churned, treat `Downgraded` as active, and put everything else — including null — into `Unassigned`.
- **The reporting layer changes the business taxonomy.** A customer who downgraded is counted as active in `status_cleaned` but excluded from the `Active Customers` measure, which uses raw `status = "Active"`. A customer whose status is `Churned` is counted as churned in `status_cleaned` but excluded from the `Churned Customers` measure, which counts only `Cancelled`. These are not cosmetic differences; they change the numbers.

## Why the Power Query layer matters

The SQL layer already standardised plan and status text. Power Query then creates a **second** reporting taxonomy:

- SQL: `status` has four non-null values plus null.
- Power Query: `status_cleaned` has three values.
- DAX: some measures use `status`, some use `status_cleaned`; some use `plan_type`, some use `plan_type_cleaned`.

That three-layer arrangement is a major source of semantic inconsistency. A measure name such as `Active Customers` can mean raw active rows, while a visual using `status_cleaned` shows a different active population. See [[08 - DAX and KPI Dictionary]].

## What is not inspectable

- The Power Query Editor’s applied-step diagnostics.
- Query-folding indicators or native-query output.
- Refresh duration, errors, or row-count logs.
- The exact type-detection step, if any, applied by the connector.
- Whether the intermediate dead-code steps were intentional.

These are **UNVERIFIED**, not assumed.

## Recommended improvements

These are proposals, not implemented changes:

1. Remove the two dead intermediate conditional columns.
2. Replace the ad-hoc `if` logic with an explicit mapping table for plan and status.
3. Trim whitespace before testing for blanks.
4. Preserve the original `plan_type` and `status` values alongside the cleaned versions.
5. Add an explicit `Table.TransformColumnTypes` step for numeric and date columns.
6. Document the status taxonomy: `Cancelled` vs `Churned` vs `Downgraded` vs null.
7. Add a data-quality query that counts unmapped values before they are relabelled.

Completion evidence would be a reviewed M expression, a mapping table with owners, and a refresh that shows zero unexpected `Unassigned` values. See [[15 - Future Improvements]].

## Related notes

- [[05 - Data Cleaning Decisions]]
- [[06 - Data Model and Grain]]
- [[08 - DAX and KPI Dictionary]]
- [[14 - Known Limitations]]
