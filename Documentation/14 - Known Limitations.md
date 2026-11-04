---
title: "14 - Known Limitations"
tags:
  - vectra
  - note/limitations
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Known Limitations

> [!warning] The project is not decision-grade in its current form
> The SQL script and PBIX are real artifacts, but the evidence is incomplete and several measures do not calculate what their labels claim. This note records the limitations that matter for interpretation, not every cosmetic defect. None of the recommendations implied here have been implemented.

## The five limitations that matter most

1. **The revenue total is not current MRR.** It is a sum of 10,000 transaction-level rows with mixed lifecycle statuses.
2. **The customer and churn measures count rows, not customers.** `Active Customers` returns 3,396 rows; 1,135 distinct customers have an Active row, and 1,067 of those also have a Cancelled/Churned row.
3. **The customer dimension is not historised.** One latest-signup row per customer loses attribute history and has no tie-breaker.
4. **The major data-quality gaps are unresolved.** Plan, region, channel, and status all contain material missing/unmapped categories, and the root cause is not established.
5. **The report narrative overstates the evidence.** Enterprise is not a majority, the mid-tier churn claim does not hold as written, and the 15%/100% impact figures are unsupported.

If a reader remembers only those five, they have the correct boundary.

## Limitation register

| # | Limitation | Why it matters | Affected claims | Evidence status |
|---:|---|---|---|---|
| 1 | SQL is a development script, not an execution log | Statements may not have run or may have failed | All SQL outcomes, constraints, row counts | `SQL-RECORDED`; execution `UNVERIFIED` |
| 2 | No raw source data or DDL | The transformations cannot be independently reproduced | Cleaning correctness, source-value coverage | `UNVERIFIED` |
| 3 | No financial baseline | Revenue totals cannot be reconciled | Current MRR, ARPU, CAC, plan mix in dollars | `UNVERIFIED` |
| 4 | Negative MRR was sign-flipped | Refunds, credits, and errors may be counted as positive revenue | Every revenue total | `SQL-RECORDED`; correctness `UNVERIFIED` |
| 5 | Fact grain is inferred | Summing every row may double-count or mix periods | `Total MRR`, trend, plan shares | `INFERRED` |
| 6 | Customer dimension is latest-signup only | Region/tier/channel history is lost; current attributes may be wrong | Segment cuts, customer-level analysis | `SQL-RECORDED`; semantics `UNVERIFIED` |
| 7 | No tie-breaker on latest signup date | The selected attributes may be nondeterministic | Customer dimension | `SQL-RECORDED` |
| 8 | Customer ID normalisation can collide | Distinct source customers may be merged | Customer count, revenue per customer | `SQL-RECORDED`; collisions `UNVERIFIED` |
| 9 | Duplicate deletion is unsafe | It can delete nothing or delete too much | Fact row count, transaction uniqueness | `SQL-RECORDED`; effect `UNVERIFIED` |
| 10 | Status taxonomy is inconsistent | Active/churn measures use different populations | Active customers, churn, retention | `PBIX-INSPECTED` |
| 11 | Churn is a row share with no period | It is not a customer or period churn rate | Churn claims, plan comparisons | `PBIX-INSPECTED`; label contradicted |
| 12 | `Active Customers` counts rows | Overstates the customer count and mixes lifecycle states | Active customer KPI, ARPU denominator | `PBIX-INSPECTED`; 3,396 vs 1,135 |
| 13 | `Annual ARPU` is not annualised | The label implies a yearly yield that is not calculated | ARPU, plan yield, unit economics | `PBIX-INSPECTED` |
| 14 | Plan filters do not reduce the ARPU denominator | Plan-level “ARPU” is plan revenue ÷ all 1,200 customers | Monetization Yield chart | `PBIX-INSPECTED`; relationship single-direction |
| 15 | `Average Customer CAC` is per row | It is not a per-customer acquisition cost | CAC, payback, unit economics | `PBIX-INSPECTED` |
| 16 | No controlled date dimension | No YoY, fiscal calendar, or period revenue | Trend, time intelligence | `PBIX-INSPECTED` |
| 17 | “MRR Growth Trend” uses signup date | It is a cohort profile, not monthly revenue | Revenue trend claims | `PBIX-INSPECTED` |
| 18 | Cancellation dates include unexplained future values | Date quality and synthetic-data provenance are unclear | Churn timing, future cancellations | `MODEL-COMPUTED`; 371 after max signup |
| 19 | `Unassigned` is treated like a plan label | Readers may mistake exposure for a product line | Plan mix, revenue share | `MODEL-COMPUTED`; category caveat |
| 20 | Quality gaps overlap across fields | Percentages cannot be added into one score | Data-quality totals | `MODEL-COMPUTED` |
| 21 | Watchlist contains 4,930 rows / 1,188 customers | It is not a prioritised risk list | Customer Success use | `MODEL-COMPUTED` |
| 22 | Products table filter changes churn denominator | The same measure shows 16.92% or 34.32% | Churn comparisons | `PBIX-INSPECTED`; DAX |
| 23 | Navigation targets are stale | Insights is not reachable from Overview/Customer | Report usability | `PBIX-INSPECTED` |
| 24 | Insights claims are static and unsupported | The page looks analytical but is narrative copy | Strategy conclusions | `PBIX-INSPECTED`; `UNVERIFIED` |
| 25 | No full rendered screenshots | Visual review is definition-level only | Visual QA, layout claims | Artifact check |
| 26 | No Git commits or remote | Publication and version history are not demonstrated | Repository claim | Workspace Git check |
| 27 | No production operations | No refresh, monitoring, access control, or deployment | Production-readiness claim | `UNVERIFIED` |

## 1. Evidence limitations

### 1.1 The SQL is a script, not a run record

The 692-line script proves which statements were written. It does not prove:

- That the script ran to completion.
- That every statement succeeded.
- That the final row counts match the PBIX.
- That the primary and foreign keys exist.
- That the duplicate delete removed anything.
- That the date conversions produced the intended values.
- That the monetary column has the expected SQL type.

No MySQL execution log, `DESCRIBE` output, `SHOW CREATE TABLE`, row-count export, or query result set was supplied.

**Consequence:** “the SQL cleans X” means “the script contains a statement that attempts to clean X.” It does not mean the final database contains the intended result.

### 1.2 The PBIX is the report of record, but it is still an import snapshot

The PBIX was inspected at report-definition and model level. It proves what the imported model contains and how the report is bound. It does not prove:

- That the MySQL source matches the import.
- That the SQL produced the import.
- That the imported values are financially correct.
- That the report renders exactly as described without a visual review.

The M queries point to a local MySQL instance. The database is not included, so the report cannot be refreshed from this workspace alone.

### 1.3 No source data or financial baseline

The source extract, source-system dictionary, billing ledger, and finance reconciliation are absent. This blocks:

- Source-to-fact reconciliation.
- Validation of the negative-MRR treatment.
- Verification of plan/region/channel mappings.
- Currency confirmation.
- Any claim that the totals are financially correct.

### 1.4 No rendered screenshots or interactive review

The report walkthrough is based on JSON definitions and field bindings. It does not prove:

- That every visual renders without an error.
- That labels fit their containers.
- That colors and contrast meet accessibility requirements.
- That tooltips and interactions behave as intended.
- That the page looks correct at different screen sizes.

The embedded banner images are available, but they are not full report screenshots. No screenshot should be fabricated.

## 2. Data and financial limitations

### 2.1 Negative MRR is unresolved

The script removes leading minus signs:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(mrr_amount, '-', '')
WHERE mrr_amount LIKE '-%';
```

A negative value could be a refund, credit, reversal, adjustment, error, or legitimate negative contract. The model has no negative MRR after cleaning, which is expected from the transformation, not evidence that the transformation was correct.

**Consequence:** `Total MRR` and every plan/region/channel share inherit this unresolved business rule. They are not financially validated.

### 2.2 Fact grain is not defined

The fact has 10,000 rows, 1,200 customers, and 8.33 rows per customer. It could be:

- A transaction history.
- A current subscription snapshot with multiple subscriptions per customer.
- A mixture of historical and current rows.
- A synthetic dataset with repeated customer events.

The SQL’s eight-column `GROUP BY` creates a distinct projection, not a business grain. Because the grain is not documented, `SUM(mrr_amount)` cannot be interpreted as current MRR.

**Consequence:** the report’s largest number is an all-row total, and the “MRR Growth Trend” is a signup-cohort aggregation.

### 2.3 Customer ID normalisation may merge customers

`CUST-` plus the last four characters is a formatting rule, not identity resolution. If two source IDs share the same final four characters, they become one customer. The final dimension has 1,200 unique IDs, but that is the post-normalisation output.

**Consequence:** customer counts and per-customer revenue may be wrong even if the join is technically valid.

### 2.4 Duplicate logic is unsafe

The duplicate CTE partitions by `transaction_id`, not by a business key, and has no `ORDER BY`. If transaction IDs are unique, it does nothing. If they repeat, it can delete every row with that ID. The imported model’s unique transaction IDs do not validate the logic.

**Consequence:** the fact row count may reflect an unknown duplicate treatment, not a clean business key.

### 2.5 Date cleaning is asymmetric and future dates are unexplained

Signup dates have a three-branch `STR_TO_DATE` path. Cancellation dates have blank-to-null handling and a `MODIFY DATE`, but no equivalent full parsing path. The imported cancellation dates extend to 2026-11-23, with 371 dates after the maximum signup date and 5 after the documentation date.

**Consequence:** cancellation timing and churn-period analysis are not reliable. The future dates may be legitimate, synthetic, or errors; the source does not say.

## 3. Customer and retention limitations

### 3.1 The customer dimension is not a customer master

The dimension keeps the attributes from the row with the latest `signup_date` for each `customer_id`. This is a **latest-signup-record selection policy**, not:

- A historised dimension.
- An SCD Type 2 model.
- A customer master-data system.
- A guarantee that the selected region, tier, or channel is current.

It loses attribute history and has no tie-breaker. 1,198 of 1,200 customers have multiple signup dates, so the policy affects almost the whole base.

### 3.2 A customer can hold several lifecycle states

Only **10 customers** have a single raw status across all their rows. **1,067 of the 1,135 customers with an Active row also have a Cancelled or Churned row.** The status field describes a subscription row, not a customer.

**Consequence:**

- `Active Customers` (3,396) is not a current customer count.
- `Churned Customers` (1,692) is not a customer churn count.
- A customer can appear in both active and churned populations.
- Customer-level retention cannot be derived without a rule for aggregating status across rows.

### 3.3 The churn measure is not a churn rate

`Churn Rate %` is:

```text
Cancelled rows ÷ all rows in the current filter context
```

It has:

- No period.
- No customer denominator.
- No exclusion of null status.
- No inclusion of `Churned`.
- A denominator that changes when `status_cleaned` is filtered.

The Products table shows 34.32% because its `status_cleaned` filter reduces the denominator to 4,930. The unfiltered measure is 16.92%. Neither is a standard churn rate.

### 3.4 The watchlist is not prioritised

The Customer and Products tables filter to 4,930 rows across 1,188 customers — about 99% of the customer base. The table:

- Is at subscription-row grain.
- Repeats customers.
- Has no risk score.
- Has no recency rule.
- Has no active-subscription condition.
- Uses “Monthly Revenue” for an all-row measure.

It is an audit view, not a Customer Success call list.

## 4. Measurement limitations

### 4.1 Customer counts are row counts

| Measure | Value | Actual unit | Distinct equivalent |
|---|---:|---|---:|
| `Customer Count` | 10,000 | Fact rows | 1,200 |
| `Active Customers` | 3,396 | Active rows | 1,135 |
| `Churned Customers` | 1,692 | Cancelled rows | 906 |
| `Active Subscriptions` | 5,070 | Cleaned Active rows | 1,177 |

A reader who treats any of these as a customer count will overstate the base or the segment by a large factor.

### 4.2 ARPU is not annual and not plan-level

`Annual ARPU` is:

```text
All-row MRR ÷ DISTINCTCOUNT(dim_customers[customer_id])
= $39,146,742 ÷ 1,200
= $32,622.29
```

It has no monthly or annual period. Because the relationship is single-direction, a plan slicer filters the fact but not the dimension. The “Monetization Yield by Account Tier” chart therefore shows plan revenue divided by all 1,200 customers, not plan-level ARPU.

### 4.3 CAC is per row

`Average Customer CAC` is `AVERAGE(cac_cost)` over 9,173 non-null subscription rows. It is not per acquired customer, and the model does not define which rows are acquisition events.

The sum of CAC is $41,036,103.67; dividing by 1,200 gives $34,196.75, which is also not a validated per-customer CAC. Neither figure supports CAC payback or LTV.

### 4.4 Unassigned is an exposure category, not a plan

The $4,728,753 Unassigned bucket is already inside the $39,146,742 total. The revenue is present; the plan attribution is missing. It is not:

- A separate revenue stream.
- Necessarily lost revenue.
- Necessarily revenue at risk.
- A product called “Unassigned.”

It is material because it biases plan shares and any product decision based on them.

### 4.5 Data-quality percentages overlap

Plan, region, channel, and status gaps occur on overlapping rows. They cannot be added into a single “data-quality percentage.” A row can be Unassigned, UNKNOWN, Unknown, and null-status at the same time.

## 5. Report and narrative limitations

### 5.1 The report’s story conflicts with the data

Two factual claims on the Insights page do not hold:

| Claim | Data |
|---|---|
| Enterprise is a majority | 36.14% — largest plan, not a majority |
| Cancellations cluster in Growth/Starter | Enterprise has the largest count (601); Growth’s rate is 18.13% vs 16.44% Enterprise |

The page also includes:

- A 20% session-decline threshold with no telemetry.
- A 15% churn-reduction impact with no experiment.
- A 100% data-integrity target with no validation.

These are hypotheses or aspirations, not findings.

### 5.2 The narrative page is the default view

`activePageName` is Insights. A reader who opens the PBIX lands on the static strategy page before seeing the data pages. That amplifies the risk that the unsupported claims are read as the report’s conclusion.

### 5.3 Navigation is broken

Four navigation targets use stale page IDs. The Insights buttons on Overview and Customer do not resolve. Products cannot reach itself. Insights cannot reach itself. The page is still viewable through the page tabs, but the intended rail navigation is not reliable.

### 5.4 Labels do not match fields

Examples:

- “Monetization Yield by Account Tier” uses `plan_type`, not `tier`.
- “Revenue by Tier” uses `plan_type_cleaned`.
- “Customer Volume” counts rows.
- “Customer ID” in the Products table is a COUNT aggregation, not an identifier.
- “Monthly Revenue” is an all-row total.
- “Annual ARPU” is not annual.
- “Churn Rate %” is a row share.
- “Customers Enterprise %” is a revenue share.

A reader cannot rely on titles alone.

### 5.5 No visual QA evidence

No rendered screenshots or interactive review were available. Layout, readability, color contrast, tooltip behavior, and cross-filter behavior are not verified.

## 6. Operational and publication limitations

### 6.1 Not production-ready

There is no evidence of:

- Scheduled refresh.
- Incremental refresh or performance tuning.
- Deployment pipeline.
- Row-level security.
- Access control.
- Monitoring or alerting.
- Incident ownership.
- Data-quality SLAs.
- Backup and recovery.
- Change management.

### 6.2 No version history or public repository

The workspace root is a Git repository, but it has:

- No commits.
- No remotes.

The README’s repository label is not evidence of a published GitHub project. Do not claim one.

### 6.3 The PBIX is tied to a local database

The M queries use `localhost:3306` and `vectra_analytics`. The database is not included. The report cannot be refreshed from the documentation alone, and the connection is not a production data source.

## What is still defensible

The limitations do not erase the project’s value. The following statements are defensible:

- The project demonstrates an end-to-end workflow from MySQL profiling and cleaning to a Power BI import model and a four-page report.
- The SQL script records a substantial set of cleaning operations and an analytical table design.
- The PBIX contains a working import model with two tables, a relationship, 12 measures, and four report pages.
- The documentation identifies real modelling and KPI defects rather than hiding them.
- The model supports descriptive statements about row counts, all-row plan mix, the Unassigned exposure, and multi-field attribution gaps, with caveats.
- The project demonstrates the ability to audit one’s own work and distinguish recorded operations from verified results.

## How to describe the project honestly

### A defensible interview summary

> Built a subscription revenue analytics portfolio project using MySQL and Power BI. Profiled and cleaned approximately 10,000 synthetic subscription rows, standardised customer identifiers and plan attributes, handled missing values and inconsistent dates, built subscription and customer tables, and developed a four-page report covering revenue mix, customer status, plan performance, and data-quality exposure. The project documents its own modelling and KPI limitations, including an all-row revenue grain, row-based customer measures, and unresolved negative-MRR treatment.

### What not to say

- “Built a production-ready revenue dashboard.”
- “Validated $39M in current MRR.”
- “Reduced churn by 15%.”
- “Achieved 100% data integrity.”
- “Built a churn prediction model.”
- “Created an SCD Type 2 customer dimension.”
- “Published the project on GitHub” — unless a remote and commits are actually created.

## Limitations by audience

| Audience | Most important limitation |
|---|---|
| Recruiter / hiring manager | The project is a portfolio artifact, not production experience; the value is the audit and workflow |
| Business stakeholder | The revenue and churn labels overstate what the measures calculate |
| Analytics engineer | The SQL is not reproducible as written; the dimension and duplicate logic need redesign |
| Data engineer | No source data, execution log, DDL, or refresh monitoring |
| Product / Customer Success | The watchlist is not prioritised, and the churn narrative is not supported |
| Finance | Negative MRR and revenue grain are unresolved; no reconciliation |

## Related notes

- [[05 - Data Cleaning Decisions]]
- [[06 - Data Model and Grain]]
- [[08 - DAX and KPI Dictionary]]
- [[10 - Business Findings]]
- [[13 - Validation and Evidence Register]]
- [[15 - Future Improvements]]
