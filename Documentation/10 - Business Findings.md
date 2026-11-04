---
title: "10 - Business Findings"
tags:
  - vectra
  - note/findings
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Business Findings

> [!warning] Scope of these findings
> The figures below are **descriptive results computed from the unfiltered 10,000-row model** in `vectra_analytics.pbix`. Vectra Global Technologies is a fictional portfolio company and the data is synthetic. These are not SQL outputs, a financial reconciliation, or a current-state business report. Unless a finding explicitly says otherwise, “revenue” means the all-row sum of `mrr_amount` after the recorded cleaning, and “customer” means a distinct `customer_id`. No causal claim is made.

## Executive summary

1. **The revenue total is an all-row total, not demonstrated current MRR.** The model sums to **$39,146,742** across 10,000 transaction-level rows and 1,200 customers. It includes Active, Cancelled, Churned, Downgraded, and null-status rows.
2. **Enterprise is the largest plan, but not a majority.** Enterprise contributes **$14,147,984**, or **36.14%** of the all-row total. The narrative claim that Enterprise is a majority is false as written.
3. **Customer-level concentration is not demonstrated.** The ten largest customers by summed MRR account for only about **2.2%** of the total. The concentration story is a plan-bucket story, not evidence of a small number of dominant accounts.
4. **The “mid-tier churn” story does not hold as stated.** Enterprise has the largest number of Cancelled rows (601). Growth has the highest Cancelled-only rate (18.13%), but only 1.69 percentage points above Enterprise and 1.94 points above Starter. When Cancelled and Churned are combined, the plan rates are close together.
5. **The Unassigned plan category is material but misunderstood.** It contains **$4,728,753**, or **12.08%** of the all-row total, across 1,232 rows and 781 customers. The revenue is already in the total; what is missing is the plan attribution. It is **not** a separate revenue stream and not necessarily lost revenue.
6. **The governance problem is multi-field.** Plan, region, acquisition channel, status, MRR, and CAC all have material missing or unmapped categories. These categories overlap and cannot be added together.
7. **The report’s customer and churn measures do not measure customers or churn.** Several named measures count subscription rows. A customer can have Active, Cancelled, Churned, and Downgraded rows at the same time.
8. **The time story is not a monthly revenue story.** The model has no standalone date table and no YoY measure. The “MRR Growth Trend” is MRR by signup cohort, and 371 cancellation dates fall after the latest signup date.

> [!important] The defensible headline
> Vectra’s imported model contains **$39.15M of all-row subscription value** across **10,000 subscription rows and 1,200 customers**, with **$4.73M (12.08%) in an Unassigned plan bucket** and substantial missing attribution across region, channel, and status. The model is useful for describing those patterns after the caveats; it is not yet reliable enough to declare current revenue, customer churn, or unit economics.

## How to read the numbers

| Term in this note | Operational meaning | What it is not |
|---|---|---|
| All-row MRR | `SUM(mrr_amount)` across every non-null fact row | Current MRR, monthly revenue, or net revenue |
| Customer | Distinct `customer_id` in the imported model | A company, account, contract, or active customer unless defined |
| Subscription row | One fact row identified by `transaction_id` | Necessarily one current subscription |
| Active | Raw `status = "Active"` unless stated | A current customer state |
| Churned | Raw `status = "Churned"` unless stated | The same population as `Cancelled` |
| Cancelled | Raw `status = "Cancelled"` unless stated | All churn-related rows |
| Plan share | Plan MRR ÷ all-row MRR | Customer share or current-revenue share |

The distinction between rows and customers is not cosmetic. The fact has **8.33 rows per customer on average**, and **1,198 of 1,200 customers have more than one signup date**. A measure that counts rows can be several times larger than the corresponding customer count.

## Finding 1 — Revenue scale is real in the model but not current MRR

### What the model shows

| Check | Result |
|---|---:|
| Fact rows | 10,000 |
| Rows with non-null MRR | 9,539 |
| Null MRR rows | 461 (4.61%) |
| All-row MRR | **$39,146,742** |
| Mean MRR per non-null row | $4,103.86 |
| Median MRR per row | $2,499 |
| Minimum / maximum | $299 / $12,000 |
| Distinct customers | 1,200 |
| Average rows per customer | 8.33 |

### Why it is not current MRR

The all-row total includes every lifecycle status:

| Raw status | Rows | MRR | Share of all-row MRR |
|---|---:|---:|---:|
| Active | 3,396 | $13,187,386 | 33.69% |
| Cancelled | 1,692 | $6,596,289 | 16.85% |
| Churned | 1,565 | $6,429,141 | 16.42% |
| Downgraded | 1,674 | $6,617,832 | 16.91% |
| NULL | 1,673 | $6,316,094 | 16.13% |
| **Total** | **10,000** | **$39,146,742** | **100%** |

If the fact is a current subscription snapshot, `Total MRR` should represent current subscriptions only. If it is a transaction history, summing every row double-counts across time. If it mixes current and historical rows, the total is a hybrid. The source does not establish which case applies.

**What can be said:** the imported model contains $39.15M of recorded MRR values across 10,000 rows.

**What cannot be said:** that Vectra currently earns $39.15M in MRR, or that this total reconciles to a billing system.

**What would settle it:** a documented fact grain, a current-subscription flag or month-end snapshot, and a reconciliation to an independent billing total.

## Finding 2 — Enterprise is the largest plan, not a majority, and not a customer concentration story

### Plan mix

| Plan | Rows | Distinct customers with a row | MRR | Share of all-row MRR | Null MRR rows |
|---|---:|---:|---:|---:|---:|
| Enterprise | 3,656 | 1,143 | $14,147,984 | 36.14% | 169 |
| Growth | 2,493 | 1,044 | $10,106,914 | 25.82% | 106 |
| Starter | 2,619 | 1,073 | $10,163,091 | 25.96% | 123 |
| Unassigned | 1,232 | 781 | $4,728,753 | 12.08% | 63 |
| **Total** | **10,000** | **1,200** | **$39,146,742** | **100%** | **461** |

Enterprise has the largest plan revenue and the largest row count, but 36.14% is a **plurality**, not a majority.

### Why “Enterprise concentration” needs careful language

- **1,143 of 1,200 customers** have at least one Enterprise row. Enterprise is not a small, exclusive segment in this data.
- **576 customers** have rows in all four plan categories. Plan is a subscription-row attribute, not a mutually exclusive customer segment.
- The **top ten customers** by summed MRR account for only **2.2%** of all-row MRR; the top customer accounts for about **0.25%**.
- Customer-level revenue is therefore broadly distributed in this model. The report does not show a small set of dominant accounts.

This does not mean Enterprise is unimportant. It means the current evidence supports a **plan-mix** statement, not a **key-account concentration** statement.

### What the Insights page says

> “Enterprise plan tier contributes the majority share of total [Total MRR].”

**Assessment:** contradicted. Enterprise is 36.14%, the largest share but not a majority. The page also says losing a small percentage of Enterprise accounts creates severe volatility; the customer-level totals do not demonstrate that concentration.

## Finding 3 — Churn is a row-status pattern, not a customer churn rate

### Raw status counts

| Raw status | Rows | Share of rows | MRR | Distinct customers with that status |
|---|---:|---:|---:|---:|
| Active | 3,396 | 33.96% | $13,187,386 | 1,135 |
| Cancelled | 1,692 | 16.92% | $6,596,289 | 906 |
| Churned | 1,565 | 15.65% | $6,429,141 | 885 |
| Downgraded | 1,674 | 16.74% | $6,617,832 | 909 |
| NULL | 1,673 | 16.73% | $6,316,094 | 907 |

The active-model `Churn Rate %` is:

```text
1,692 Cancelled rows ÷ 10,000 rows = 16.92%
```

It excludes the 1,565 `Churned` rows. Counting both statuses gives:

```text
(1,692 + 1,565) ÷ 10,000 = 32.57%
```

Neither calculation has a period definition or a customer denominator.

### Cancelled-only rate by plan

| Plan | Cancelled rows | All rows | Cancelled-only rate |
|---|---:|---:|---:|
| Enterprise | 601 | 3,656 | 16.44% |
| Growth | 452 | 2,493 | 18.13% |
| Starter | 424 | 2,619 | 16.19% |
| Unassigned | 215 | 1,232 | 17.45% |

Growth has the highest rate, but the spread is **1.94 percentage points** from Starter to Growth. That is a modest descriptive difference, not a “disproportionate cluster.”

### Cancelled + Churned rate by plan

| Plan | Cancelled + Churned rows | All rows | Combined rate |
|---|---:|---:|---:|
| Enterprise | 1,176 | 3,656 | 32.17% |
| Growth | 810 | 2,493 | 32.49% |
| Starter | 831 | 2,619 | 31.73% |
| Unassigned | 440 | 1,232 | 35.71% |

Combining the two statuses makes the plan rates even closer: 31.73% to 35.71%, with the Unassigned plan bucket highest. This directly undercuts a simple “Growth/Starter mid-tier churn” story.

### The customer-level picture is more important

| Check | Result |
|---|---:|
| Distinct customers with at least one Active row | 1,135 |
| Of those, also have a Cancelled or Churned row | **1,067** |
| Distinct customers with at least one Cancelled row | 906 |
| Distinct customers with at least one Churned row | 885 |
| Distinct customers with at least one Cancelled **or** Churned row | **1,131 (94.25% of 1,200)** |
| Customers with exactly one distinct raw status across all rows | 10 |
| Customers with exactly one distinct non-null raw status | 32 |

> [!danger] A customer can be Active and Churned at the same time
> Only 10 customers have a single raw status across all their rows. The model’s status field describes the state of a **subscription row**, not a customer. “Active Customers” and “Churned Customers” are row counts that can both include the same customer. They cannot be used to calculate customer churn, retention, or a customer lifecycle.

### What the Insights page says

> “Cancellation counts ([Churned Customers]) are disproportionately clustered in Growth and Starter tiers.”

**Assessment:** not supported as written. Enterprise has the largest Cancelled count (601). Growth has the highest Cancelled-only rate (18.13%), but the difference is modest and disappears into a 31.73%–35.71% range when both churn statuses are combined. A plan-level causal explanation would require cohort, contract, product-usage, and renewal data that the project does not contain.

## Finding 4 — Unassigned plan revenue is exposure, not a separate stream

### What the model shows

| Check | Result |
|---|---:|
| `plan_type_cleaned = "Unassigned"` rows | 1,232 |
| Rows with an MRR value | 1,169 |
| Rows with null MRR | 63 |
| Distinct customers with an Unassigned row | 781 |
| MRR in the bucket | **$4,728,753** |
| Share of all-row MRR | **12.08%** |

Status composition of the Unassigned plan bucket:

| Raw status | Rows |
|---|---:|
| Active | 415 |
| Cancelled | 215 |
| Churned | 225 |
| Downgraded | 194 |
| NULL | 183 |
| **Total** | **1,232** |

### Interpretation

- The dollars are **already inside** the $39.15M total. The issue is not that revenue is missing from the report; it is that the plan attribute is missing.
- The bucket is not a plan called “Unassigned.” It is a reporting category for null or unmapped plan values.
- It is not a separately earned revenue stream, a product line, or incremental revenue.
- It is not necessarily revenue at risk. Some of those customers may be active on a valid plan that was not captured.
- It does bias plan-level shares and any product decision based on them.

**Defensible label:** `Revenue Exposure from Unassigned Plan Attributes`, not “Unassigned revenue” as if it were a product.

**What would reduce it:** a source-system plan catalogue, a mapping table with owners, and a rule that prevents unmapped plans from entering the reporting layer silently.

## Finding 5 — Data quality is multi-field, and the categories overlap

### Exception snapshot

| Field / category | Exception rows | MRR affected | Share of all-row MRR | Distinct customers affected |
|---|---:|---:|---:|---:|
| Plan = `Unassigned` | 1,232 | $4,728,753 | 12.08% | 781 |
| Region = `UNKNOWN` | 1,664 | $6,525,129 | 16.67% | 206 |
| Acquisition channel = `Unknown` | 2,096 | $8,276,576 | 21.14% | 246 |
| Status = `NULL` | 1,673 | $6,316,094 | 16.13% | 907 |
| MRR = `NULL` | 461 | — | — | — |
| CAC = `NULL` | 827 | — | — | — |
| Cancellation date = `NULL` | 6,743 | — | — | — |

> [!warning] Do not add these percentages
> The same row can have an Unassigned plan, an Unknown channel, an UNKNOWN region, and a null status. The categories overlap. They describe different attribution gaps, not a single “16% data-quality rate.”

### Region and channel splits

| Region | Rows | MRR | Share of all-row MRR | Distinct customers |
|---|---:|---:|---:|---:|
| AMER | 3,239 | $12,741,335 | 32.55% | 388 |
| APAC | 1,628 | $6,221,246 | 15.89% | 194 |
| EMEA | 1,818 | $7,097,798 | 18.13% | 217 |
| LATAM | 1,651 | $6,561,234 | 16.76% | 195 |
| UNKNOWN | 1,664 | $6,525,129 | 16.67% | 206 |

| Channel | Rows | MRR | Share of all-row MRR | Distinct customers |
|---|---:|---:|---:|---:|
| Direct Sales | 2,047 | $7,945,041 | 20.30% | 250 |
| Organic Search | 1,864 | $7,255,862 | 18.54% | 222 |
| Paid Ads | 1,969 | $7,810,811 | 19.95% | 239 |
| Partner Referral | 2,024 | $7,858,452 | 20.07% | 243 |
| Unknown | 2,096 | $8,276,576 | 21.14% | 246 |

### Interpretation

- The Missing/Unknown share is material in **four** fields, not just plan type.
- Region and channel are dimension attributes, so their customer counts are non-overlapping partitions of 1,200. Their MRR shares still reflect the all-row revenue base.
- `Unknown` is an explicit bucket, which is better than inventing a channel, but it is not a channel performance result.
- The upstream root cause is not established. The SQL records the defaulting rule; it does not prove why source values were blank or unmapped.
- The `UNKNOWN` region and `Unknown` channel are not the same category as `Unassigned` plan or `status_cleaned = "Unassigned"`.

**What can be said:** attribution is incomplete across several dimensions and materially affects any plan, region, or channel comparison.

**What cannot be said:** that a specific source system, team, or process caused the gaps. That would require source-system investigation.

## Finding 6 — The KPI labels overstate what the measures calculate

| Measure | Value | What it actually counts | Customer-equivalent | Why it matters |
|---|---:|---|---:|---|
| `Active Customers` | 3,396 | Rows with raw `status = "Active"` | 1,135 distinct customers | Not a current customer count; 1,067 also have Cancelled/Churned rows |
| `Churned Customers` | 1,692 | Rows with raw `status = "Cancelled"` | 906 distinct customers | Excludes 1,565 `Churned` rows |
| `Customer Count` | 10,000 | Fact rows with a customer ID | 1,200 customers | 8.33× overstatement as a customer count |
| `Active Subscriptions` | 5,070 | Rows with `status_cleaned = "Active"` | 1,177 distinct customers | Includes `Downgraded`; differs from Active Customers |
| `Churn Rate %` | 16.92% | Cancelled rows ÷ all rows | — | Not a period or customer churn rate |
| `Annual ARPU` | $32,622.29 | All-row MRR ÷ 1,200 customers | — | Not annualised; numerator is all-row |
| `Average Customer CAC` | $4,473.58 | Average CAC per non-null row | — | Not CAC per acquired customer |
| `Customers Enterprise %` | 36.14% | Enterprise revenue ÷ total revenue | — | Revenue share, not customer share |

### Why this is a business finding, not just a naming issue

A reported number can be arithmetically correct and still lead to the wrong decision. Examples:

- A “customer volume” bar of 3,656 Enterprise is a row count; treating it as 3,656 Enterprise customers overstates the segment by more than 3× relative to the 1,143 distinct customers with an Enterprise row.
- `Annual ARPU` of $32,622 looks like a yearly yield; it is actually all-row revenue divided by every customer. A plan-filtered chart still divides by 1,200.
- `Churn Rate %` of 16.92% looks like a customer churn rate; it is a Cancelled-row share with no period.
- `Customer Count` of 10,000 can look like a large customer base; the model has 1,200 customers.

The reporting layer needs definitions before it needs more visuals. See [[08 - DAX and KPI Dictionary]] and [[14 - Known Limitations]].

## Finding 7 — The time story is a signup-cohort story, not a monthly revenue trend

### What the model contains

| Check | Result |
|---|---|
| Signup date range | 2021-01-01 to 2025-12-06 |
| Cancellation date range | 2021-02-09 to 2026-11-23 |
| Null cancellation dates | 6,743 (67.43%) |
| Cancellations dated 2026 | 319 |
| Cancellation dates after maximum signup date | 371 |
| Cancellation dates after 2026-11-03 | 5 |
| Cancellation dates before signup | 0 |
| Standalone `dim_date` | None |
| YoY measure | None in active model |
| Customers with more than one signup date | 1,198 of 1,200 |

### Why the visuals are not a time series

The slicers and the “MRR Growth Trend” visual use the `signup_date` hierarchy. They group all rows by the date on which the customer signed up. They do not group revenue by the month in which it was earned or recognised.

That means:

- The trend is a **signup cohort profile**, not monthly recurring revenue.
- The date slicer changes which customers’ rows are included, not which revenue month is shown.
- Cancellation dates exist but are not used by the page slicers.
- There is no YoY measure, despite the handover’s description of one.

### The future-dated cancellations

371 cancellation dates fall after the latest signup date, including 319 in 2026 and 5 after the documentation date. These could be legitimate future-dated cancellations, synthetic-data artefacts, or date-quality problems. The source does not establish which.

**What can be said:** the model’s date fields span inconsistent horizons and the report does not use a controlled date dimension.

**What cannot be said:** that the trend shows revenue growth, seasonality, or year-over-year performance.

## Finding 8 — Unit economics are not decision-ready

### What the model shows

| Check | Result |
|---|---:|
| All-row MRR | $39,146,742 |
| `Annual ARPU` as modelled | $32,622.29 |
| Average CAC per non-null row | $4,473.58 |
| Sum of CAC across rows | $41,036,103.67 |
| Sum of CAC ÷ 1,200 customers | $34,196.75 |
| Null CAC rows | 827 |

### Why these are not unit economics

- `Annual ARPU` has no annual period and no active-customer denominator. It is all-row revenue divided by all 1,200 customers.
- `Average Customer CAC` is an average per subscription row, not per acquired customer.
- The total CAC sum is **higher** than the all-row MRR total, but the two figures are not comparable: one is an acquisition-cost sum across rows, the other is an all-row revenue sum. Neither is a cohort-level payback calculation.
- There is no gross margin, expansion revenue, contract length, or retention curve. CAC payback and LTV cannot be computed from the supplied model.

**What can be said:** the model contains CAC values and revenue values; their labels imply unit economics that the calculations do not deliver.

**What cannot be said:** that CAC is $4,473.58 per customer, that annual ARPU is $32,622, or that the business is profitable or unprofitable on a unit basis.

## What the evidence supports — and what it does not

| Claim | Verdict | Basis |
|---|---|---|
| The imported model has 10,000 fact rows and 1,200 customers | **Supported** | `MODEL-COMPUTED`; unique keys |
| All-row MRR is $39,146,742 | **Supported as an all-row sum** | `MODEL-COMPUTED` |
| Enterprise is the largest plan at 36.14% | **Supported** | `MODEL-COMPUTED` |
| Enterprise is a majority of MRR | **Contradicted** | 36.14% is not a majority |
| A small number of Enterprise accounts dominate revenue | **Not supported** | Top ten customers ≈ 2.2% of all-row MRR |
| Unassigned plan exposure is $4.73M / 12.08% | **Supported with definition** | `MODEL-COMPUTED`; category is unmapped plan, not a stream |
| Missing attribution affects multiple fields | **Supported** | Plan, region, channel, status all show material gaps |
| Cancellations are disproportionately clustered in Growth/Starter | **Not supported as written** | Enterprise has the largest count; rate differences are modest |
| Growth has the highest Cancelled-only rate | **Supported descriptively** | 18.13% vs 16.44% Enterprise, 16.19% Starter |
| `Churn Rate %` is a customer churn rate | **Contradicted** | It is a Cancelled-row share with no period |
| `Active Customers` is a distinct active-customer count | **Contradicted** | 3,396 rows vs 1,135 distinct customers; 1,067 overlap with churn statuses |
| `Annual ARPU` is annual | **Contradicted** | No annualisation; all-row numerator |
| `Average Customer CAC` is per customer | **Contradicted** | Average per subscription row |
| The 20% session-decline threshold predicts churn | **Unverified** | No telemetry, no validation, no control group |
| The initiative will reduce churn by 15% | **Unsupported** | No experiment or model |
| Governance work will produce 100% data integrity | **Unsupported** | No validation results or acceptance criteria |
| The report is production-ready | **Contradicted** | No deployment, refresh, monitoring, or reconciliation evidence |

## What a business audience should take away

### Safe conclusions

- The imported dataset is a **transaction-level subscription dataset** with 10,000 rows and 1,200 customers, not a clean current-customer snapshot.
- **Plan mix can be described** at the all-row level: Enterprise 36.14%, Growth 25.82%, Starter 25.96%, Unassigned 12.08%.
- **Unassigned plan value is material**: $4.73M, 12.08% of all-row MRR. The issue is attribution, not missing cash.
- **Data quality is a first-order business problem**, visible in plan, region, channel, status, MRR, and CAC.
- **The churn narrative is not established.** The model contains lifecycle statuses, not a customer churn cohort.

### Unsafe conclusions

- “Current MRR is $39.15M.”
- “Enterprise is the majority of revenue.”
- “Growth and Starter customers are churning disproportionately.”
- “3,396 customers are active.”
- “Annual ARPU is $32,622.”
- “CAC is $4,473.58 per customer.”
- “The retention programme will reduce churn by 15%.”
- “The pipeline will achieve 100% data integrity.”
- “The dashboard is production-ready.”

These are not reasons to discard the project. They are the boundary between a descriptive portfolio model and a decision-grade revenue system. [[11 - Strategic Recommendations]] sets out what to fix first; [[13 - Validation and Evidence Register]] records the claim-level evidence.

## Related notes

- [[06 - Data Model and Grain]]
- [[08 - DAX and KPI Dictionary]]
- [[09 - Power BI Dashboard Walkthrough]]
- [[11 - Strategic Recommendations]]
- [[13 - Validation and Evidence Register]]
- [[14 - Known Limitations]]
