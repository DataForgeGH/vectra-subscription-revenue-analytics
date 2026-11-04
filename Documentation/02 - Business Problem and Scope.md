---
title: "02 - Business Problem and Scope"
tags:
  - vectra
  - note/business-context
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Business Problem and Scope

> [!warning] Fictional scenario
> Vectra Global Technologies and all associated data are fictional. The business problem is a realistic SaaS analytics scenario, not a real client engagement.

## The business problem

A subscription business needs a trustworthy view of revenue, retention, plan performance, and data quality. The source data is not trustworthy enough to support that view directly:

- Status values arrive with inconsistent casing and whitespace.
- MRR values arrive with currency symbols, comma separators, blanks, and negative signs.
- Plan names arrive in several spellings.
- Customer IDs arrive in several formats.
- Signup dates arrive in several text formats.
- Cancellation dates are often blank and are not cleaned through the same path as signup dates.
- Customer attributes disagree across records for the same customer ID.
- Some records are incomplete or unmapped.

The project therefore treats **data quality as part of the business question**, not as a separate technical chore. A dashboard that looks polished but cannot explain its revenue grain or its customer counts is not decision-ready.

## Original analytical areas

The project brief described four areas:

| Area | Original question | What the project set out to do |
|---|---|---|
| Revenue performance | How large is subscription revenue, and how is it distributed by plan and region? | Clean MRR, build revenue measures, compare plans and regions |
| Customer and retention | How many customers are represented, what churn-related statuses exist, and where are retention risks? | Build customer counts, status views, and a churn-related narrative |
| Product and plan performance | How do Enterprise, Growth, and Starter compare? | Compare revenue, yield, and churn-related status by plan |
| Data governance | Which fields are incomplete or unmapped, and how does that affect reporting confidence? | Quantify blanks, unknown categories, and unmapped plan exposure |

These are the **intended** questions. The project does not prove that every question was answered correctly in the final dashboard. Several measures use labels that imply a different calculation from the one they perform.

## Scope

### In scope

- Profiling the staging table `stg_vectra_raw`.
- Cleaning status, MRR, acquisition channel, plan type, region/tier, customer ID, signup date, cancellation date, and CAC.
- Investigating and attempting to remove duplicates.
- Creating `fact_subscriptions` and `dim_customers`.
- Importing both tables into Power BI.
- Adding `plan_type_cleaned` and `status_cleaned` in Power Query.
- Building 12 DAX measures.
- Designing four report pages: Overview, Customer, Products, Insights.
- Documenting findings, limitations, and evidence status.

### Out of scope

- A production data warehouse or scheduled refresh.
- A full customer master-data system or SCD Type 2 history.
- Financial reconciliation to a general ledger or billing system.
- A statistically validated churn model.
- Telemetry, session, or product-usage analysis.
- Row-level security, deployment pipelines, or monitoring.
- A real customer, contract, or revenue dataset.

The absence of these items is a scope boundary, not a hidden failure. The project is a portfolio exercise in the analytics workflow.

## Business questions, restated precisely

The original questions are broad. For analysis, they need sharper definitions:

### Revenue

- What does `mrr_amount` represent: current monthly recurring revenue, a transaction value, a historical snapshot, or something else?
- Does summing every row produce current MRR, or an all-row historical total?
- Is the currency consistent, and is `$` the correct convention?
- Are negative values errors, refunds, credits, reversals, or legitimate adjustments?
- How should `Unassigned` plan records be treated in revenue reporting?

### Customers and retention

- Is a “customer” a distinct `customer_id`, a subscription row, or a contract?
- What does “active” mean: `status = "Active"`, `status_cleaned = "Active"`, or a customer with at least one active subscription?
- What is the difference between `Cancelled`, `Churned`, and `Downgraded`?
- Over what period is churn measured, and what is the denominator?
- Are null statuses unknown, inactive, or simply unrecorded?

### Plans

- Are Starter, Growth, and Enterprise mutually exclusive per customer, or can a customer hold multiple plans over time?
- Is plan type an attribute of the customer or of the subscription transaction?
- What is the business meaning of an `Unassigned` plan?
- Is “Enterprise concentration” about plan revenue share or about a small number of large accounts?

### Data quality

- Which fields are missing, and are they missing at random or systematically?
- Are `Unknown`, `UNKNOWN`, and `Unassigned` the same concept or three different ones?
- Which source-system mappings are missing, and who owns them?
- Can the final tables be rebuilt deterministically from the script?

## What was established, and what was not

| Question | What the evidence establishes | Status |
|---|---|---|
| Is there a working SQL script? | A 692-line script contains the profiling, cleaning, and table-building statements | `SQL-RECORDED`; execution `UNVERIFIED` |
| Are there analytical tables? | The PBIX imports `fact_subscriptions` and `dim_customers` | `PBIX-INSPECTED` |
| How many fact rows? | 10,000 rows; 10,000 unique `transaction_id` values | `PBIX-INSPECTED` / `MODEL-COMPUTED` |
| How many customers? | 1,200 unique `customer_id` values in `dim_customers` | `PBIX-INSPECTED` |
| What is total revenue? | All-row `SUM(mrr_amount)` = $39,146,742 | `MODEL-COMPUTED`; not a financial reconciliation |
| Is Enterprise a majority? | Enterprise is 36.14% of all-row MRR — the largest plan, not a majority | `MODEL-COMPUTED` |
| Are cancellations concentrated in Growth/Starter? | Enterprise has the largest Cancelled count (601); Growth has the highest Cancelled-only rate (18.13%), but the gap is modest | `MODEL-COMPUTED` |
| Is there a churn predictor? | No; the 20% session-decline threshold is a management hypothesis | `PBIX-INSPECTED` / `UNVERIFIED` |
| Is the model production-ready? | No scheduled refresh, deployment, monitoring, or financial validation is evidenced | `UNVERIFIED` |

The distinction matters. A query can be written without being executed successfully; a value can be present in a PBIX without being financially reconciled; a measure can return a number without measuring what its name says.

## Stakeholders and decisions the report was meant to support

| Stakeholder | Intended decision | What the current report can support |
|---|---|---|
| Executive leadership | Where revenue comes from and whether it is concentrated | Descriptive plan mix; not a current-MRR or customer-concentration conclusion |
| Revenue operations | Which plans and regions need attention | Descriptive plan/region splits, with data-quality caveats |
| Customer success | Which accounts are churn risks | A filtered churned/unassigned watchlist; not a validated risk score |
| Product management | Whether the Growth-to-Enterprise boundary needs review | A hypothesis; no causal or pricing evidence |
| Data engineering | Which fields need governance | A clear multi-field completeness problem; upstream cause not proven |

## Scope boundaries that affect interpretation

1. **No source-system documentation.** The dataset has no data dictionary, status codebook, plan catalogue, region/tier mapping table, or currency definition.
2. **No billing or CRM extract.** CAC, plan, status, and cancellation fields cannot be reconciled to their operational systems.
3. **No time-series snapshot.** The fact table appears to be transaction-level, with multiple rows per customer. It is not evidenced as a monthly snapshot.
4. **No telemetry.** The report cannot test whether usage declines predict churn.
5. **No experiment or control group.** Any proposed retention intervention is a hypothesis, not an evaluated programme.

## Success criteria for a stronger version

A future version would be decision-ready only if it could demonstrate:

- A documented fact grain and a current-MRR definition.
- A customer definition and an active-customer definition agreed with the business.
- A churn definition with an explicit period and denominator.
- A currency and unit convention.
- A documented status and plan taxonomy.
- Reconciliations from staging to fact, and from fact to reported totals.
- Reproducible SQL with constraints and validation queries.
- Retained query outputs and report screenshots.

These are **RECOMMENDED** completion criteria. None should be described as already achieved. See [[15 - Future Improvements]] and [[13 - Validation and Evidence Register]].

## Related notes

- [[01 - Project Overview]]
- [[03 - Dataset and Data Dictionary]]
- [[10 - Business Findings]]
- [[14 - Known Limitations]]
