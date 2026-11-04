---
title: "00 - Home"
tags:
  - vectra
  - note/home
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03

# Vectra Subscription Revenue Analytics

> [!warning] Fictional project
> Vectra Global Technologies is a fictional B2B SaaS company. All customers, contracts, plans, and financial figures in this project are synthetic and do not represent a real business.

This vault documents an end-to-end MySQL → Power BI portfolio project: profiling and cleaning subscription data, building a small analytical model, developing DAX measures, and designing a four-page report. It is written as an evidence-qualified project record, not as promotional copy.

> [!important] Current status
> **Portfolio project. Not production-ready. Not fully validated.**
> The SQL file is a development script, not an execution log. The PBIX report and model were inspected directly for this documentation, but no MySQL execution output, DDL export, financial baseline, or rendered page screenshots were available. Statements are labelled so recorded work is not confused with verified results.

## Project at a glance

| Item | Detail |
|---|---|
| Project owner | Joshua Ofoli Yaotey |
| Project type | End-to-end data analytics portfolio project |
| Business context | Vectra Global Technologies (fictional B2B SaaS) |
| Stack | MySQL Workbench / MySQL, Power BI Desktop, Power Query (M), DAX, Git/GitHub |
| Database | `vectra_analytics` |
| Analytical tables | `fact_subscriptions`, `dim_customers` |
| Model snapshot | 10,000 fact rows; 1,200 customer rows; 12 DAX measures |
| Report | Four pages: Overview, Customer, Products, Insights |
| Repository label (intended) | `vectra-subscription-revenue-analytics`; no commit history or remote is established in this workspace |

## Start here

| If you want to understand… | Read |
|---|---|
| The project purpose and scope | [[01 - Project Overview]] |
| The business questions | [[02 - Business Problem and Scope]] |
| The source columns and data quality | [[03 - Dataset and Data Dictionary]] |
| What the SQL script does, in order | [[04 - SQL Development Timeline]] |
| Each cleaning decision and its risk | [[05 - Data Cleaning Decisions]] |
| The fact grain, dimension, and relationships | [[06 - Data Model and Grain]] |
| The actual Power Query logic | [[07 - Power Query Transformations]] |
| The 12 measures and their real behaviour | [[08 - DAX and KPI Dictionary]] |
| The four report pages, visual by visual | [[09 - Power BI Dashboard Walkthrough]] |
| What the evidence supports | [[10 - Business Findings]] |
| What should happen next | [[11 - Strategic Recommendations]] |
| The main technical and analytical decisions | [[12 - Challenges and Decisions]] |
| Claim-by-claim evidence status | [[13 - Validation and Evidence Register]] |
| What the project cannot currently prove | [[14 - Known Limitations]] |
| Prioritised future work | [[15 - Future Improvements]] |
| Which files actually exist | [[16 - Artifact Inventory]] |

## Technology stack

| Tool | Role | Evidence basis |
|---|---|---|
| MySQL Workbench / MySQL | Profiling, in-place cleaning, table creation, keys | `SQL-RECORDED` |
| Power BI Desktop | Import model, relationships, report pages, visuals | `PBIX-INSPECTED` |
| Power Query (M) | Plan-type and status reporting columns | `PBIX-INSPECTED` |
| DAX | 12 revenue, customer, churn, ARPU, and CAC measures | `PBIX-INSPECTED` |
| Git/GitHub | Intended version control and publication | `UNVERIFIED` in this working copy |
| Obsidian | Project documentation | This vault |

## Source artifacts

| Artifact | What it is | Status |
|---|---|---|
| [README.md](../README.md) | Public-facing project description | Read; largely consistent with the inspected PBIX |
| [VECTRA_PROJECT_MASTER_HANDOVER_AUDITED.md](../VECTRA_PROJECT_MASTER_HANDOVER_AUDITED.md) | Audited handover and evidence boundary | Read; some pre-PBIX claims are stale |
| [vectra_subscription_analytics.sql.sql](../vectra_subscription_analytics.sql.sql) | 692-line MySQL development script (called `jj.sql` in the handover) | Inspected; execution not verified |
| [vectra_analytics.pbix](../vectra_analytics.pbix) | Four-page Power BI report and import model | Inspected at report-definition and model level |
| [INSIGHTS.md](../INSIGHTS.md) | Page 4 strategic narrative source | Read; contains unsupported impact claims |

> [!note] What “inspected” means here
> The PBIX container was opened and its report definition, embedded TMDL scripts, and decoded data model were read. The model data was queried read-only to recompute measures. The report was **not** opened interactively in Power BI Desktop, and no full-page rendered screenshots were available. Visual descriptions therefore come from the report definition and bindings, not from a visual review of every pixel.

## Major unresolved limitations

- **Negative MRR sign removal**: the SQL strips leading minus signs; whether those values were errors, refunds, credits, or adjustments is unresolved.
- **Customer dimension**: one “latest signup” row per customer ID; attribute history is lost and tied dates have no tie-breaker.
- **Customer-ID normalisation**: `CUST-` plus the final four characters may collapse distinct source IDs.
- **Duplicate deletion**: the CTE partitions by `transaction_id` and has no `ORDER BY`; its correctness and effect are unverified.
- **Revenue grain**: `Total MRR` is an all-row sum of 10,000 transaction-level rows, not a demonstrated current-MRR measure.
- **KPI labels**: several measures count rows rather than customers, or measure revenue share rather than customer share.
- **No standalone date table**: the model uses automatic date tables; there is no YoY measure in the inspected model.
- **Report narrative**: the Insights page says Enterprise is a majority and that cancellations cluster in Growth/Starter; the imported model does not support those claims as written.

## Evidence labels used in this vault

| Label | Meaning |
|---|---|
| `SQL-RECORDED` | The operation appears in the SQL script. Proves the statement is written, not that it executed. |
| `PBIX-INSPECTED` | Read directly from the PBIX report definition, model metadata, or embedded scripts. |
| `MODEL-COMPUTED` | Recomputed from the imported PBIX data. Not a rendered visual value or SQL output. |
| `CONVERSATION-RECORDED` | Recorded during project development or troubleshooting. Context, not execution proof. |
| `HANDOVER-REPORTED` | Appears in a generated handover or report description; secondary evidence. |
| `INFERRED` | A technically reasonable interpretation, not proven by an execution output or final artifact. |
| `UNVERIFIED` | The available material is insufficient to establish the claim. |
| `RECOMMENDED` | A proposed correction or improvement, not an implemented change. |

The full claim-by-claim register is in [[13 - Validation and Evidence Register]]. The practical consequences are in [[14 - Known Limitations]].

## Recommended reading paths

**Recruiter or hiring manager:** [[01 - Project Overview]] → [[06 - Data Model and Grain]] → [[08 - DAX and KPI Dictionary]] → [[09 - Power BI Dashboard Walkthrough]] → [[10 - Business Findings]] → [[13 - Validation and Evidence Register]].

**Business stakeholder:** [[02 - Business Problem and Scope]] → [[10 - Business Findings]] → [[11 - Strategic Recommendations]] → [[14 - Known Limitations]].

**Analytics engineer:** [[03 - Dataset and Data Dictionary]] → [[04 - SQL Development Timeline]] → [[05 - Data Cleaning Decisions]] → [[06 - Data Model and Grain]] → [[07 - Power Query Transformations]] → [[12 - Challenges and Decisions]].
