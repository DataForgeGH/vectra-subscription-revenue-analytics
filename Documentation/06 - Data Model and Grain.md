---
title: "06 - Data Model and Grain"
tags:
  - vectra
  - note/data-model
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Data Model and Grain

> [!warning] Intended design vs imported model
> The SQL script describes an intended star-like model. The PBIX contains the model that was actually imported. They agree on the two main tables and the customer relationship, but they differ on the date model and on the final measure set. This note records both and flags the differences.

## Model at a glance

```text
dim_customers[customer_id] (1)
        │
        │  active, single-direction, many-to-one
        ▼
fact_subscriptions[customer_id] (*)

fact_subscriptions[transaction_id]  ← primary key in SQL

Automatic date tables (hidden):
  LocalDateTable_...signup_date       ← fact[signup_date]
  LocalDateTable_...cancellation_date ← fact[cancellation_date]

_Measures (calculated single-row table) ← 12 DAX measures
```

The PBIX table names carry the database prefix:

- `vectra_analytics dim_customers`
- `vectra_analytics fact_subscriptions`

The SQL table names are `dim_customers` and `fact_subscriptions`. The prefix is a Power BI import artefact, not a separate schema in the SQL script.

## Table inventory

| Table | Rows | Columns | Role | Evidence |
|---|---:|---|---|---|
| `vectra_analytics fact_subscriptions` | 10,000 | 8 SQL columns + 2 Power Query columns | Subscription fact | `PBIX-INSPECTED` |
| `vectra_analytics dim_customers` | 1,200 | 4 columns | Customer dimension | `PBIX-INSPECTED` |
| `_Measures` | 1 (placeholder) | `Placeholder` + 12 measures | Measure table | `PBIX-INSPECTED` |
| `DateTableTemplate_...` | 1 date | Date hierarchy columns | Hidden automatic date template | `PBIX-INSPECTED` |
| `LocalDateTable_...signup_date` | Date range | Date hierarchy columns | Hidden automatic date table for signup | `PBIX-INSPECTED` |
| `LocalDateTable_...cancellation_date` | Date range | Date hierarchy columns | Hidden automatic date table for cancellation | `PBIX-INSPECTED` |

There is **no standalone `dim_date`** in the inspected PBIX, despite the audited handover describing one. This is a source conflict resolved in favour of the actual PBIX. See [[13 - Validation and Evidence Register]].

## Fact-table grain

### Intended grain

The SQL creates `fact_subscriptions` by selecting eight columns and grouping by all eight:

```sql
CREATE TABLE fact_subscriptions AS
SELECT transaction_id, customer_id, signup_date, plan_type,
       mrr_amount, cac_cost, status, cancellation_date
FROM vectra_analytics.stg_vectra_raw
GROUP BY transaction_id, customer_id, signup_date, plan_type,
         mrr_amount, cac_cost, status, cancellation_date;
```

**INFERRED grain:** one row per subscription transaction identified by `transaction_id`.

The grain is not explicitly defined in the source. The script’s `GROUP BY` makes the fact a distinct projection across those eight fields, but it does not prove that a row is a current subscription, a historical event, a snapshot, or a mixture.

### What the imported data shows

| Check | Result | Implication |
|---|---:|---|
| Fact rows | 10,000 | Model snapshot |
| Unique `transaction_id` | 10,000 | Unique key per fact row; the business event is not confirmed |
| Distinct `customer_id` | 1,200 | Multiple rows per customer |
| Average rows per customer | 8.33 | Not a one-row-per-customer model |
| Customers with more than one signup date | 1,198 of 1,200 | The fact is not a one-row-per-customer current snapshot |
| Customers with four plan types | 576 | Customers can hold multiple plans across rows |
| Customer + signup groups with more than one row | 24 groups / 48 rows | May be multiple subscriptions on the same date; not duplicates by the full business key |

> [!danger] Do not read `SUM(mrr_amount)` as current MRR
> The fact contains 10,000 transaction-level rows across 1,200 customers, with an average of 8.33 rows per customer. Summing every row produces an **all-row total** of $39,146,742. Whether that is current MRR depends on whether each row is a current subscription, a historical transaction, a snapshot, or a mixture — and the source does not say. The report’s `Total MRR` measure and its “MRR Growth Trend” visual therefore need a grain caveat, not a current-MRR claim.

## Customer-dimension grain

### Intended grain

The SQL creates one selected row per `customer_id`:

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
```

**Implemented grain:** one selected customer profile per `customer_id`.

**Selection policy:** keep the row with the latest `signup_date` and use its `region`, `tier`, and `acquisition_channel`.

### What this policy does and does not establish

| It does | It does not |
|---|---|
| Return at most one row per `customer_id` if the ranking behaves as expected | Prove that the selected attributes are the customer’s true current master data |
| Select attributes from the latest signup record | Preserve the history of region, tier, or channel changes |
| Produce a unique key for the Power BI relationship | Define a deterministic tie-breaker when two rows share the latest signup date |
| Give the report one region/tier/channel per customer | Validate that the latest signup record is the right source for master data |

The imported dimension has 1,200 unique keys. The project history reports approximately 1,198 customer-attribute conflicts, but the exact counting definition and output are not attached. The dimension’s one-row shape is therefore verified; the **semantic correctness of the selected attributes is not**.

> [!note] Correct terminology
> Call this a **latest-signup-record customer attribute selection policy**. Do not call it a historised customer dimension, a customer master, or an SCD Type 2 model.

## Keys and relationships

### SQL design

| Constraint | Table | Statement | Status |
|---|---|---|---|
| Primary key | `fact_subscriptions` | `ADD PRIMARY KEY (transaction_id)` | `SQL-RECORDED`; execution unverified |
| Foreign key | `fact_subscriptions` | `ADD FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)` | `SQL-RECORDED`; ordering risk |
| Primary key | `dim_customers` | `ADD PRIMARY KEY (customer_id)` | `SQL-RECORDED`; execution unverified |

The foreign key is added **before** `dim_customers` is created in the displayed script. On a fresh database, the statement could fail because the referenced table does not yet exist. If the dimension already existed from an earlier session, it might succeed. The final MySQL constraint state is **UNVERIFIED**.

### PBIX relationship

| From | To | Cardinality | Direction | Active | Referential integrity |
|---|---|---|---|---|---|
| `fact_subscriptions[customer_id]` | `dim_customers[customer_id]` | Many-to-one | Single | Yes | No missing fact keys; no orphan dimension rows in the imported model |

The PBIX relationship is an **import-model relationship**, not proof that the SQL foreign key exists. It is active and single-direction, from the dimension to the fact.

### Filter-direction consequence

Because the relationship is single-direction (`dim_customers` → `fact_subscriptions`):

- Filtering `dim_customers[region]` or `[acquisition_channel]` filters the fact.
- Filtering a fact column such as `plan_type` does **not** filter `dim_customers`.

This matters for measures that divide by `DISTINCTCOUNT(dim_customers[customer_id])`. A plan-level filter on the fact side does not reduce the dimension denominator. See [[08 - DAX and KPI Dictionary]] for the ARPU consequence.

## Date model

### What exists

The PBIX contains Power BI automatic date tables:

- `LocalDateTable_...signup_date`
- `LocalDateTable_...cancellation_date`
- A hidden `DateTableTemplate_...`

Both date relationships use `datePartOnly`. The report slicers use the `signup_date` hierarchy (Year → Quarter → Month → Day).

### What does not exist

- No standalone `dim_date` table.
- No date dimension with a continuous date spine, fiscal calendar, or explicit active/inactive relationship design.
- No YoY measure in the active model.

### Why it matters

The handover describes a standalone `dim_date` and a `YoY Revenue Growth %` measure. Neither is present in the inspected PBIX. The README’s statement that the model uses automatic date tables and has no YoY measure is consistent with the PBIX.

The “MRR Growth Trend (2021–2025)” visual is a sum of `Total MRR` by the `signup_date` hierarchy. It is **MRR by signup cohort**, not a monthly recurring revenue time series. A cancellation-date hierarchy exists, but the report’s slicers use signup date.

## Model design strengths

- The model separates subscription rows from customer attributes.
- `transaction_id` is unique in the imported fact.
- `dim_customers` is unique by `customer_id`.
- The customer relationship is active and key-complete in the imported model.
- Measures are held in a dedicated `_Measures` table rather than scattered across the fact.
- Automatic date tables are hidden, so they do not clutter the report field list.

These are real modelling strengths. They do not resolve the grain, KPI-definition, or customer-history issues.

## Model design risks

| Risk | Why it matters | Evidence |
|---|---|---|
| Fact grain is inferred, not documented | All-row revenue may be mistaken for current MRR | `INFERRED`; 8.33 rows/customer |
| Customer dimension is not historised | Region/tier/channel history is lost; “current” attributes may be wrong | `SQL-RECORDED`; semantic validity `UNVERIFIED` |
| Ties on latest signup date | Selected attributes may be nondeterministic | `SQL-RECORDED`; no tie-breaker |
| Customer ID normalisation | Distinct source customers may collapse | `SQL-RECORDED`; collisions `UNVERIFIED` |
| Date model is automatic | No controlled date table or YoY; date filtering depends on the signup hierarchy | `PBIX-INSPECTED` |
| Single-direction relationship | Fact-side plan filters do not flow to the customer dimension | `PBIX-INSPECTED` |
| Measures in `_Measures` use raw fact columns | Status/plan semantics are inconsistent across measures | `PBIX-INSPECTED` |
| Table name prefix | DAX must use the full `'vectra_analytics fact_subscriptions'` name | `PBIX-INSPECTED` |

## SQL design vs PBIX model

| Design element | SQL script | PBIX model | Conflict? |
|---|---|---|---|
| Fact table | `fact_subscriptions` | `vectra_analytics fact_subscriptions` | Name prefix only |
| Customer table | `dim_customers` | `vectra_analytics dim_customers` | Name prefix only |
| Fact key | `transaction_id` PK | Unique in imported data | No conflict in data; SQL constraint unverified |
| Customer key | `customer_id` PK | Unique, 1,200 rows | No conflict in data; SQL constraint unverified |
| Relationship | FK to `dim_customers` | Active M:1 relationship | PBIX relationship exists; SQL FK unverified |
| Date table | None created in SQL | Automatic date tables | Handover says `dim_date`; PBIX says automatic |
| Measures | None | 12 in `_Measures` | Handover lists fewer/different measures |
| Power Query columns | None | `plan_type_cleaned`, `status_cleaned` | These are not physical SQL columns |

## Embedded TMDL scripts are stale

The PBIX contains two embedded TMDL scripts (`Script 1.tmdl`, `Script 2.tmdl`). They do not describe the active model:

- `Script 1` defines four measures inside the fact table, including `Enterprise Customers`.
- `Script 2` defines four measures in `_Measures`.
- The active model has **12 measures** in `_Measures`, including `Enterprise Revenue` and `Unassigned Revenue`.

These scripts appear to be saved migration/authoring artefacts, not the current model definition. Do not cite them as the model of record. The decoded active model is authoritative for [[08 - DAX and KPI Dictionary]].

## Related notes

- [[03 - Dataset and Data Dictionary]]
- [[05 - Data Cleaning Decisions]]
- [[07 - Power Query Transformations]]
- [[08 - DAX and KPI Dictionary]]
- [[14 - Known Limitations]]
