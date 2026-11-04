---
title: "01 - Project Overview"
tags:
  - vectra
  - note/overview
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Project Overview

> [!warning] Fictional business context
> Vectra Global Technologies is a fictional B2B SaaS company created for a portfolio project. The data is synthetic. Nothing in this vault describes a real company, real customers, or real financial results.

## Purpose

**Vectra Subscription Revenue Analytics** is an end-to-end data analytics project. It starts with a messy subscription dataset in MySQL and ends with a four-page Power BI report that examines revenue, customer activity, plan performance, retention signals, and data-quality exposure.

The project’s value is not that it produced a production-grade revenue platform. It is that it demonstrates a complete analytical workflow:

1. Profile raw data before changing it.
2. Clean inconsistent text, identifiers, dates, and monetary values.
3. Build analytical tables with explicit keys.
4. Model the data in Power BI.
5. Write DAX measures and interrogate what they actually calculate.
6. Design a report for a business audience.
7. Document what the evidence supports — and what it does not.

The documentation deliberately keeps the weaknesses visible. Several cleaning decisions are financially or semantically questionable, and the dashboard contains measure names that do not match their calculations. Those issues are part of the project record, not something to hide.

## Fictional business context

Vectra Global Technologies sells subscription software to other businesses on three named plans: **Starter**, **Growth**, and **Enterprise**. The source data also contains records whose plan cannot be mapped; those become an explicit **Unassigned** category in the Power BI layer.

The intended business questions are familiar SaaS questions:

- How large is subscription revenue, and how is it distributed by plan and region?
- How many customers are represented, and what churn-related statuses exist?
- How do Enterprise, Growth, and Starter compare on revenue, yield, and retention?
- Which fields are incomplete or unmapped, and how does that affect reporting confidence?

The data is not a clean production extract. It contains mixed status casing, currency-formatted MRR values, multiple plan spellings, multiple customer-ID formats, several date formats, missing values, and conflicting customer attributes. The project treats those imperfections as the analytical problem rather than as a preprocessing afterthought.

## Intended audience

| Audience | What they should take from the project |
|---|---|
| Recruiters and hiring managers | An end-to-end workflow, SQL and DAX fluency, and the ability to explain limitations honestly |
| Business stakeholders | A descriptive view of plan mix, revenue exposure, and data-quality gaps — with clear caveats |
| Analytics engineers | A realistic example of in-place SQL cleaning, grain decisions, and model-side transformations |
| Developing analysts | A worked example of why a query being written is not the same as a result being verified |

## Tools and deliverables

| Tool | Role in the project |
|---|---|
| MySQL Workbench / MySQL | Profiling, cleaning, table construction, primary and foreign keys |
| Power BI Desktop | Import model, relationships, DAX, report pages |
| Power Query (M) | `plan_type_cleaned` and `status_cleaned` reporting columns |
| DAX | 12 measures covering revenue, customers, churn, ARPU, and CAC |
| Git/GitHub | Intended version control and publication |
| Obsidian | This documentation vault |

The inspected deliverables are:

- A 692-line MySQL development script, `vectra_subscription_analytics.sql`.
- A Power BI file, `vectra_analytics.pbix`, containing four report pages and 12 measures.
- A public-facing `README.md`.
- An audited master handover, `VECTRA_PROJECT_MASTER_HANDOVER_AUDITED.md`.
- A Page 4 narrative note, `INSIGHTS.md`.

The exact artifact status is recorded in [[16 - Artifact Inventory]].

## Analytical workflow

```text
Raw subscription records in stg_vectra_raw
  → SQL profiling: row count, structure, status values, formats, blanks
  → cleaning: status, MRR, acquisition channel, plan type, region/tier,
    customer ID, signup date, cancellation date, CAC
  → duplicate investigation and attempted deletion
  → fact_subscriptions and dim_customers
  → Power BI import
  → Power Query: plan_type_cleaned and status_cleaned
  → 12 DAX measures
  → four-page report: Overview, Customer, Products, Insights
  → documentation of findings, limitations, and evidence gaps
```

The SQL work is described in [[04 - SQL Development Timeline]]; the cleaning decisions and their consequences are in [[05 - Data Cleaning Decisions]]. The model is covered in [[06 - Data Model and Grain]] and [[07 - Power Query Transformations]].

## What the project actually established

The imported Power BI model contains:

- **10,000** fact rows and **1,200** customer-dimension rows.
- **10,000** unique `transaction_id` values and **1,200** unique `customer_id` values in the dimension.
- **12** DAX measures.
- A single active relationship from `dim_customers[customer_id]` to `fact_subscriptions[customer_id]`.
- No standalone `dim_date`; the model relies on Power BI automatic date tables.
- An all-row `Total MRR` of **$39,146,742** across the 10,000 rows.
- An **Unassigned** plan category representing **$4,728,753**, or **12.08%** of that all-row total.

Those are model facts, not a financial reconciliation. The fact grain and the meaning of each MRR row are not established well enough to call the total “current MRR.” See [[06 - Data Model and Grain]] and [[10 - Business Findings]].

> [!note] Important distinction
> A SQL statement being present proves that the operation was written. It does not prove that it executed successfully, that the final table has the expected constraints, or that the output is financially correct. A PBIX value proves what is in the imported model; it does not prove the SQL that produced it was correct.

## What the project did not establish

- No MySQL execution log, DDL export, or query outputs were supplied.
- No financial baseline was supplied, so the revenue totals are not reconciled to a ledger.
- The SQL foreign key, primary keys, and final column types are not independently demonstrated.
- The duplicate-removal logic is not proven correct.
- The customer dimension is not a historised master record.
- The negative-MRR treatment is not financially validated.
- The churn, ARPU, and active-customer measures are not defined in a way that supports their labels.
- The 20% session-decline threshold is a management hypothesis, not a tested predictor.
- The Page 4 claims of a 15% churn reduction and 100% data integrity are aspirational, not modelled.

These points are not reasons to discard the project. They are the difference between a portfolio exercise and a production analytics system, and the documentation states that difference plainly.

## Defensible positioning

A credible one-paragraph description is:

> Built a subscription revenue analytics portfolio project using MySQL and Power BI. Profiled and cleaned approximately 10,000 synthetic subscription records, standardised customer identifiers and plan attributes, handled missing values and inconsistent dates, created customer and subscription tables, and developed a four-page report exploring revenue distribution, customer activity, plan performance, and data-quality exposure. The project also documents modelling and KPI limitations discovered during validation.

The project should **not** be described as production-ready, fully validated, financially reconciled, or a statistically proven churn-prediction system. See [[14 - Known Limitations]] for the full non-claims.

## Related notes

- [[02 - Business Problem and Scope]]
- [[06 - Data Model and Grain]]
- [[13 - Validation and Evidence Register]]
- [[16 - Artifact Inventory]]
