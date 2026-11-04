---
title: "08 - DAX and KPI Dictionary"
tags:
  - vectra
  - note/dax
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# DAX and KPI Dictionary

> [!warning] Read the definition, not the label
> The active PBIX model contains **12 measures**. Several names describe a different calculation from the one they perform. The DAX below was read from the decoded model, not reconstructed from the handover. Values are recomputed from the imported 10,000-row model and are **not** a financial reconciliation.

## Model context

| Item | Detail |
|---|---|
| Measure table | `_Measures` (a calculated single-row table) |
| Fact table | `'vectra_analytics fact_subscriptions'` |
| Customer dimension | `'vectra_analytics dim_customers'` |
| Relationship | `dim_customers[customer_id]` 1 → * `fact_subscriptions[customer_id]`, active, single-direction |
| Date table | No standalone `dim_date`; automatic date tables only |
| Measures | 12 |

The table names include the database prefix because of the MySQL import. DAX must use the full quoted name.

## Measure summary

Values are unfiltered totals from the imported model. A slicer or visual filter can change them.

| Measure | Unfiltered value | What the name suggests | What it actually returns |
|---|---:|---|---|
| `Total MRR` | $39,146,742 | Current monthly recurring revenue | Sum of every `mrr_amount` row |
| `Enterprise Revenue` | $14,147,984 | Enterprise revenue | Sum of rows where `plan_type = "Enterprise"` |
| `Customers Enterprise %` | 36.14% | Share of customers that are Enterprise | Enterprise revenue ÷ total revenue |
| `Plan_type % share` | 100% across plans | Plan share of revenue | Plan revenue ÷ revenue with the plan filter removed |
| `Unassigned Revenue` | $4,728,753 | Revenue from unassigned plans | Sum of rows where `plan_type = "Unassigned"` |
| `Annual ARPU` | $32,622.29 | Annual revenue per user | All-row revenue ÷ 1,200 distinct dimension customers |
| `Churn Rate %` | 16.92% | Customer churn rate | `Cancelled` rows ÷ all rows, with the status filter removed |
| `Active Customers` | 3,396 | Distinct active customers | Rows where `status = "Active"` |
| `Churned Customers` | 1,692 | Churned customers | Rows where `status = "Cancelled"` |
| `Average Customer CAC` | $4,473.58 | CAC per customer | Average `cac_cost` across non-null subscription rows |
| `Customer Count` | 10,000 | Number of customers | Count of fact rows with a non-null `customer_id` |
| `Active Subscriptions` | 5,070 | Active subscriptions | Rows where `status_cleaned = "Active"` |

## Full measure table

The DAX column is whitespace-normalised for table readability. Exact multi-line definitions follow in the detailed sections.

| Measure | Actual DAX | Plain-English explanation | Intended business interpretation | What it actually calculates | Known semantic issue | Evidence |
|---|---|---|---|---|---|---|
| `Total MRR` | `SUM('vectra_analytics fact_subscriptions'[mrr_amount])` | Adds every non-null MRR value in the current filter context | Current recurring revenue | All-row sum; nulls ignored | Not current MRR unless the fact grain is a current snapshot; includes cancelled/churned/downgraded rows | `PBIX-INSPECTED`; value `MODEL-COMPUTED` |
| `Enterprise Revenue` | `CALCULATE([Total MRR], '...'[plan_type] = "Enterprise")` | Sums MRR for Enterprise rows | Enterprise revenue | Same all-row sum, filtered to one plan | Name was corrected from `Enterprise Customers`; it is still not a customer count | `PBIX-INSPECTED` |
| `Customers Enterprise %` | `DIVIDE([Enterprise Revenue], [Total MRR])` | Enterprise revenue as a share of total revenue | Enterprise customer share | A **revenue share** | The name says customers; the calculation says revenue | `PBIX-INSPECTED` |
| `Plan_type % share` | `DIVIDE([Total MRR], CALCULATE([Total MRR], ALL('...'[plan_type])))` | Plan revenue divided by revenue with the plan filter removed | Plan share of revenue | Plan share within the current non-plan filter context | Correct arithmetic for an all-row revenue share; not a customer or unit share | `PBIX-INSPECTED` |
| `Unassigned Revenue` | `CALCULATE([Total MRR], '...'[plan_type] = "Unassigned")` | Sums MRR for the Unassigned plan category | Revenue from unmapped plans | All-row MRR in the `Unassigned` bucket | Exposure, not a separate revenue stream; 63 of 1,232 rows have null MRR | `PBIX-INSPECTED` |
| `Annual ARPU` | `DIVIDE([Total MRR], DISTINCTCOUNT('...dim_customers'[customer_id]), 0)` | All-row revenue divided by distinct dimension customers | Annual revenue per user | All-row revenue ÷ 1,200; no annualisation | Not annualised; numerator is not period revenue; plan filters do not reduce the denominator | `PBIX-INSPECTED` |
| `Churn Rate %` | `DIVIDE(CALCULATE(COUNTROWS('...'), '...'[status] = "Cancelled"), CALCULATE(COUNTROWS('...'), REMOVEFILTERS('...'[status])), 0)` | Cancelled rows divided by all rows after removing the status filter | Customer churn rate | Cancelled **row** share of all rows | Not a period or customer churn rate; excludes `Churned`; denominator includes null status; filter-context sensitive | `PBIX-INSPECTED` |
| `Active Customers` | `COUNTROWS(FILTER('...', '...'[status] = "Active"))` | Counts rows whose raw status is Active | Distinct active customers | **Rows**, not distinct customers | 3,396 rows vs 1,135 distinct customers with an Active row | `PBIX-INSPECTED` |
| `Churned Customers` | `CALCULATE(COUNTROWS('...'), '...'[status] = "Cancelled")` | Counts rows whose raw status is Cancelled | Churned customers | **Rows** with `Cancelled`; excludes `Churned` | 1,692 rows; excludes 1,565 `Churned` rows; 906 distinct customers | `PBIX-INSPECTED` |
| `Average Customer CAC` | `AVERAGE('...'[cac_cost])` | Averages non-null CAC values across rows | CAC per customer | Average per subscription row | Not a per-customer acquisition cost; blanks excluded; allocation undefined | `PBIX-INSPECTED` |
| `Customer Count` | `COUNT('...'[customer_id])` | Counts fact rows with a customer ID | Number of customers | **Rows**, not distinct customers | 10,000 rows vs 1,200 distinct customers | `PBIX-INSPECTED` |
| `Active Subscriptions` | `CALCULATE(COUNT('...'[customer_id]), '...'[status_cleaned] = "Active")` | Counts rows in the cleaned Active group | Active subscriptions | Rows where `status_cleaned = "Active"` | Includes `Downgraded`; 5,070 rows vs 1,177 distinct customers; differs from `Active Customers` | `PBIX-INSPECTED` |

## Detailed definitions and audit

### 1. Total MRR

```dax
Total MRR =
SUM('vectra_analytics fact_subscriptions'[mrr_amount])
```

**Plain English:** add every non-null `mrr_amount` in the current filter context.

**What it actually calculates:** an all-row sum of 10,000 transaction-level rows, of which 9,539 have a value. Nulls are ignored.

**Intended interpretation:** monthly recurring revenue. The name implies a current, recurring, period-based measure.

**Why the label needs care:**

- The fact has 10,000 rows across 1,200 customers (8.33 rows per customer on average).
- 1,198 of 1,200 customers have more than one signup date.
- The fact includes `Active`, `Cancelled`, `Churned`, `Downgraded`, and null-status rows.
- The source does not establish whether a row is a current subscription, a historical transaction, a snapshot, or a mixture.

The result, **$39,146,742**, is therefore an **all-row total**, not a demonstrated current MRR. It is also not a financial reconciliation: no billing ledger or baseline was supplied. The nearest defensible label is `All-Row MRR Total`.

**Format note:** the measure uses a numeric format (`#,0` in the embedded script), not a currency format. The report titles use `$`, but the model has no currency table or code.

### 2. Enterprise Revenue

```dax
Enterprise Revenue =
CALCULATE(
    [Total MRR],
    'vectra_analytics fact_subscriptions'[plan_type] = "Enterprise"
)
```

**Plain English:** apply a filter for `plan_type = "Enterprise"` and then sum MRR.

**What it actually calculates:** $14,147,984, or 36.14% of the all-row total. This is the largest plan, but not a majority.

**Intended interpretation:** Enterprise revenue.

**Why the label needs care:** the measure was corrected from an earlier `Enterprise Customers` measure that used the same revenue calculation. The name is now more accurate, but it still inherits the all-row grain and the sign-removal caveat. It is not a count of Enterprise customers.

**Note:** the filter uses `plan_type`, not `plan_type_cleaned`. In the imported data the two columns are identical, so the result is the same. If the Power Query mapping changes, the measure will not follow the cleaned field.

### 3. Customers Enterprise %

```dax
Customers Enterprise % =
DIVIDE([Enterprise Revenue], [Total MRR])
```

**Plain English:** divide Enterprise revenue by total revenue.

**What it actually calculates:** a **revenue share**, 36.14% in the unfiltered model.

**Intended interpretation:** the name suggests “the percentage of customers that are Enterprise.” That is not what it does.

**Why it is misleading:**

- The numerator is revenue, not a customer count.
- The denominator is total revenue, not total customers.
- If the page is filtered to `plan_type = "Enterprise"`, both numerator and denominator become the same filtered total, so the measure returns **100%**. It is not a stable customer-share KPI.

A correct customer share would require `DISTINCTCOUNT` of customer IDs in the Enterprise population divided by the distinct customer population, with both populations defined. That measure does not exist in the model.

### 4. Plan_type % share

```dax
Plan_type % share =
DIVIDE(
    [Total MRR],
    CALCULATE(
        [Total MRR],
        ALL('vectra_analytics fact_subscriptions'[plan_type])
    )
)
```

**Plain English:** divide the current plan’s revenue by total revenue after removing the plan filter.

**What it actually calculates:** each plan’s share of all-row revenue within the current non-plan filter context. Unfiltered values:

| Plan | Revenue | Share |
|---|---:|---:|
| Enterprise | $14,147,984 | 36.14% |
| Growth | $10,106,914 | 25.82% |
| Starter | $10,163,091 | 25.96% |
| Unassigned | $4,728,753 | 12.08% |

**Intended interpretation:** plan revenue mix.

**Why it is mostly sound but not a full KPI:** the arithmetic is a valid revenue share. It still inherits the all-row revenue grain and the `Unassigned` category. It is not a share of customers, units, or current MRR.

### 5. Unassigned Revenue

```dax
Unassigned Revenue =
CALCULATE(
    [Total MRR],
    'vectra_analytics fact_subscriptions'[plan_type] = "Unassigned"
)
```

**Plain English:** sum MRR where the plan is `Unassigned`.

**What it actually calculates:** $4,728,753 across 1,232 rows. 1,169 of those rows have an MRR value; 63 are null.

**Intended interpretation:** revenue exposure from records whose plan attribute could not be mapped.

**Why the label needs care:**

- It is **not** a plan called “Unassigned”; it is a bucket for missing or unmapped plan attributes.
- It is **not** a separately earned revenue stream.
- The figure is model-level exposure, not a financial reconciliation.
- The `$` convention is not independently documented beyond the report and handover.

**Recommended label:** `Revenue Exposure from Unassigned Plan Attributes`.

### 6. Annual ARPU

```dax
Annual ARPU =
DIVIDE(
    [Total MRR],
    DISTINCTCOUNT('vectra_analytics dim_customers'[customer_id]),
    0
)
```

**Plain English:** divide all-row revenue by the number of distinct customers in the customer dimension.

**What it actually calculates:** $39,146,742 ÷ 1,200 = **$32,622.29**.

**Why the label is wrong on two counts:**

1. **It is not annualised.** There is no monthly or annual period in the numerator, and no multiplication by 12.
2. **It is not a per-user measure in the usual sense.** The numerator is an all-row total, including cancelled, churned, downgraded, and null-status rows. The denominator is every customer in the dimension.

**Filter-direction problem:** the relationship is single-direction from `dim_customers` to `fact_subscriptions`. A filter on `plan_type` (a fact column) does **not** filter the customer dimension. Therefore, on the “Monetization Yield by Account Tier ($)” chart:

| Plan | Revenue | `Annual ARPU` as modelled (÷1,200) |
|---|---:|---:|
| Enterprise | $14,147,984 | $11,789.99 |
| Growth | $10,106,914 | $8,422.43 |
| Starter | $10,163,091 | $8,469.24 |
| Unassigned | $4,728,753 | $3,940.63 |

Those are **plan revenue divided by all 1,200 customers**, not plan-level ARPU. A denominator based on distinct customers with a row in each plan would produce different values (for example, Enterprise revenue ÷ 1,143 = $12,377.94). That alternative is an analyst illustration, not a dashboard measure.

**Also:** a date slicer on `signup_date` filters the fact but not the dimension, so the denominator stays at 1,200 while the numerator changes. The measure is not a period ARPU.

### 7. Churn Rate %

```dax
Churn Rate % =
DIVIDE(
    CALCULATE(
        COUNTROWS('vectra_analytics fact_subscriptions'),
        'vectra_analytics fact_subscriptions'[status] = "Cancelled"
    ),
    CALCULATE(
        COUNTROWS('vectra_analytics fact_subscriptions'),
        REMOVEFILTERS('vectra_analytics fact_subscriptions'[status])
    ),
    0
)
```

**Plain English:** count `Cancelled` rows, divide by all rows after removing the status filter.

**What it actually calculates:** 1,692 ÷ 10,000 = **16.92%** in the unfiltered model.

**Why it is not a customer churn rate:**

- The numerator and denominator are **rows**, not distinct customers.
- The numerator includes only `Cancelled`; it excludes 1,565 `Churned` rows. Counting both gives 3,257 ÷ 10,000 = **32.57%**.
- There is no period definition. It is not “churn this month” or “churn this year.”
- The denominator includes 1,673 null-status rows, which may be unknown rather than active.
- `REMOVEFILTERS` removes only the `status` filter. A visual filter on `status_cleaned` is **not** removed, so the denominator can change dramatically.

**Filter-context example:** the Products page table is filtered to `status_cleaned IN ("Churned", "Unassigned")`. The measure then operates on 4,930 rows, not 10,000:

| Plan / cleaned status | Rows in context | Cancelled rows | `Churn Rate %` in that context |
|---|---:|---:|---:|
| Enterprise / Churned | 1,176 | 601 | 51.11% |
| Growth / Churned | 810 | 452 | 55.80% |
| Starter / Churned | 831 | 424 | 51.02% |
| Unassigned plan / Churned | 440 | 215 | 48.86% |
| Enterprise / Unassigned | 635 | 0 | 0.00% |
| Growth / Unassigned | 418 | 0 | 0.00% |
| Starter / Unassigned | 437 | 0 | 0.00% |
| Unassigned plan / Unassigned | 183 | 0 | 0.00% |
| **All filtered rows** | **4,930** | **1,692** | **34.32%** |

This is **INFERRED** from the DAX and the visual filter, not a rendered screenshot. It shows why the same measure can display 16.92% on one page and a very different value in a filtered table. The measure name does not communicate that context dependence.

A defensible churn rate needs an explicit period and a denominator such as customers active at the start of the period. That definition is not present.

### 8. Active Customers

```dax
Active Customers =
COUNTROWS(
    FILTER(
        'vectra_analytics fact_subscriptions',
        'vectra_analytics fact_subscriptions'[status] = "Active"
    )
)
```

**Plain English:** count fact rows whose raw status is `Active`.

**What it actually calculates:** 3,396 rows. The number of **distinct customers** with at least one `Active` row is **1,135**.

**Why the label is misleading:**

- It counts subscription rows, not customers.
- A customer with multiple active rows is counted multiple times.
- It excludes `Downgraded` rows, even though `status_cleaned` maps `Downgraded` to `Active`.
- It counts a customer as active even if they also have churned/cancelled rows elsewhere in the fact.

A correct distinct active-customer measure would use `DISTINCTCOUNT` over customer IDs filtered to an agreed active definition. That measure does not exist.

### 9. Churned Customers

```dax
Churned Customers =
CALCULATE(
    COUNTROWS('vectra_analytics fact_subscriptions'),
    'vectra_analytics fact_subscriptions'[status] = "Cancelled"
)
```

**Plain English:** count rows whose raw status is `Cancelled`.

**What it actually calculates:** 1,692 rows across 906 distinct customers.

**Why the label is misleading:**

- It excludes 1,565 rows with `status = "Churned"`.
- It is a row count, not a distinct customer count.
- It treats `Cancelled` as the only churn status, while `status_cleaned` treats both `Cancelled` and `Churned` as churned.
- The report’s Insights page refers to `[Churned Customers]` while making a claim about cancellation counts; the measure does not count all churned records.

If the business considers `Cancelled` and `Churned` distinct, the measure needs a documented reason for excluding one. If it considers them the same, the measure is undercounting by 1,565 rows. Either way, the current label is not self-explanatory.

### 10. Average Customer CAC

```dax
Average Customer CAC =
AVERAGE('vectra_analytics fact_subscriptions'[cac_cost])
```

**Plain English:** average the non-null `cac_cost` values across fact rows.

**What it actually calculates:** $4,473.58 across 9,173 non-null rows. The sum of CAC is $41,036,103.67; dividing that sum by 1,200 customers gives $34,196.75, which is a different (and also not necessarily correct) per-customer figure.

**Why the label is misleading:**

- It is an average per **subscription row**, not per customer.
- It excludes 827 null rows.
- It does not define which rows represent acquisition events.
- It does not account for customers with multiple rows or multiple plan purchases.

A true CAC measure would need a numerator of acquisition spend and a denominator of newly acquired customers in a defined period. Neither is present.

### 11. Customer Count

```dax
Customer Count =
COUNT('vectra_analytics fact_subscriptions'[customer_id])
```

**Plain English:** count fact rows with a non-null customer ID.

**What it actually calculates:** 10,000 rows. The distinct customer count is 1,200.

**Why the label is wrong:** it is a row count. In a visual by region, it shows the number of subscription rows per region, not the number of customers. The overstatement factor is 8.33× in the unfiltered model.

### 12. Active Subscriptions

```dax
Active Subscriptions =
CALCULATE(
    COUNT('vectra_analytics fact_subscriptions'[customer_id]),
    'vectra_analytics fact_subscriptions'[status_cleaned] = "Active"
)
```

**Plain English:** count rows whose cleaned status is `Active`.

**What it actually calculates:** 5,070 rows. That is `Active` (3,396) + `Downgraded` (1,674). The distinct customer count in this group is 1,177.

**Why the label needs care:**

- It counts rows, not distinct subscriptions unless the fact grain is one row per subscription.
- It includes `Downgraded` rows because `status_cleaned` maps them to `Active`.
- It excludes 1,673 null-status rows, which `status_cleaned` labels `Unassigned`.
- It differs from `Active Customers` (3,396) not because the business changed, but because the measures use different status columns.

## Measures that are not in the active model

The audited handover describes several measures that are **not present** in the inspected PBIX:

| Handover measure | Status in active model | Consequence |
|---|---|---|
| `Average ARPU` | Not present; active model has `Annual ARPU` | The handover’s denominator (`[Active Customers]`) is not the actual denominator (`DISTINCTCOUNT(dim_customers[customer_id])`) |
| `Total Churned MRR` | Not present | No churned-revenue measure exists |
| `YoY Revenue Growth %` | Not present | No time-intelligence measure and no standalone date table |
| `Enterprise Customers` | Not present; active model has `Enterprise Revenue` | The old name survives only in an embedded stale TMDL script |
| `Churn Rate %` using `[Active Customers]` | Different definition | Active model uses `COUNTROWS` with `status = "Cancelled"` |
| `Active Customers` using `DISTINCTCOUNT` | Different definition | Active model uses `COUNTROWS` with `status = "Active"` |

This is a source conflict, not a small naming difference. The handover describes an earlier or proposed measure set; the PBIX is the model of record. See [[13 - Validation and Evidence Register]].

## KPI naming rules for a corrected model

These are **RECOMMENDED** labels, not implemented changes:

| Current name | Problem | Proposed name or definition |
|---|---|---|
| `Total MRR` | All-row sum; grain unclear | `All-Row MRR Total` until grain is defined; then `Current MRR (as of date)` |
| `Customers Enterprise %` | Revenue share | `Enterprise Revenue Share` |
| `Annual ARPU` | Not annualised; all-row numerator | `All-Row Revenue per Customer`; a true `Monthly ARPU` needs period MRR ÷ active customers |
| `Churn Rate %` | Row share; excludes Churned; no period | `Cancelled Row Share (All Rows)`; a true `Period Churn Rate` needs a cohort denominator |
| `Active Customers` | Row count | `Active Subscription Rows` or `Distinct Active Customers` |
| `Churned Customers` | Row count; Cancelled only | `Cancelled Rows` or `Distinct Churned Customers (Cancelled + Churned)` |
| `Average Customer CAC` | Per-row average | `Average CAC per Subscription Row`; a true `CAC per Acquired Customer` needs acquisition events |
| `Customer Count` | Row count | `Subscription Row Count` or `Distinct Customer Count` |
| `Active Subscriptions` | Includes Downgraded | `Active + Downgraded Subscription Rows` or a defined active-subscription count |

## What would make these measures trustworthy

1. A documented fact grain and a current-MRR definition.
2. A documented customer definition and active-customer definition.
3. A documented churn period and denominator.
4. A currency and unit convention.
5. A status taxonomy agreed across SQL, Power Query, and DAX.
6. A date table with a clear active relationship.
7. Reconciliation to at least one independent total.
8. Measure descriptions and format strings in the model.
9. Validation queries whose outputs are retained.

None of these is currently demonstrated. See [[13 - Validation and Evidence Register]] and [[15 - Future Improvements]].

## Related notes

- [[06 - Data Model and Grain]]
- [[07 - Power Query Transformations]]
- [[09 - Power BI Dashboard Walkthrough]]
- [[10 - Business Findings]]
- [[14 - Known Limitations]]
