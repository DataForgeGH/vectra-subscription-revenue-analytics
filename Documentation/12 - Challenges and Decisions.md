---
title: "12 - Challenges and Decisions"
tags:
  - vectra
  - note/decisions
  - note/challenges
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Challenges and Decisions

> [!warning] A record of choices under incomplete evidence
> This note explains the main technical and analytical decisions in the project: what was chosen, what alternative was available, and what the choice cost. It does not claim that every choice was correct. Some are defensible development shortcuts; others are defects that a production review should reject. The distinction is part of the project’s value.

## Decision map

| # | Decision | Where it appears | Status | Assessment |
|---:|---|---|---|---|
| 1 | Strip leading minus signs from MRR | SQL lines 108–114 | Implemented | **High-risk**; financial meaning unresolved |
| 2 | Title-case status values | SQL lines 225–252 | Implemented | Reasonable normalisation; taxonomy still undefined |
| 3 | Map recognised plan prefixes; null the rest | SQL lines 301–335 | Implemented | Useful heuristic; loses unmapped source values |
| 4 | Replace null plan with `Unassigned` | Power Query | Implemented | Makes exposure visible; conflates missing with a plan |
| 5 | Merge Cancelled/Churned in `status_cleaned` | Power Query | Implemented | Simplifies reporting; conflicts with DAX churn measures |
| 6 | Count rows for “Active Customers” and “Churned Customers” | DAX | Implemented | **Defect**; labels imply distinct customers |
| 7 | Divide all-row MRR by all 1,200 customers for “Annual ARPU” | DAX | Implemented | **Defect**; not annual and not plan-sensitive |
| 8 | Keep latest signup row per customer | SQL lines 672–692 | Implemented | Reasonable one-row shape; loses history and has no tie-breaker |
| 9 | Normalise customer IDs to `CUST-` + last four | SQL lines 402–436 | Implemented | Convenient; collision risk unresolved |
| 10 | Attempt duplicate deletion by `transaction_id` | SQL lines 616–640 | Implemented | **Unsafe as written**; effect unverified |
| 11 | Use automatic date tables, no `dim_date` | PBIX model | Observed | Limits time intelligence and period analysis |
| 12 | Keep the strategic narrative despite contrary data | PBIX Insights page | Observed | **Not acceptable for decision use**; documented, not silently fixed |
| 13 | Use stale page IDs in navigation buttons | PBIX report | Observed | Report defect; Insights unreachable from Overview/Customer |
| 14 | Document source conflicts rather than overwrite them | This vault | Deliberate | Preserves audit trail; may frustrate a reader who wants one clean answer |

## 1. Negative MRR: a formatting fix applied to a financial value

### Recorded decision

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(mrr_amount, '-', '')
WHERE mrr_amount LIKE '-%';
```

The script turns every value beginning with `-` into a positive value.

### Why it may have seemed reasonable

The downstream model and report need positive revenue values. A negative MRR row breaks simple sums and looks like a data-entry problem. Removing the sign makes the column visually consistent and eliminates negative bars.

### What the decision cost

- The original value is not preserved in the analytical table.
- The reason for the negative value is lost.
- Refunds, credits, reversals, adjustments, and genuine negative contract values are treated identically.
- Every revenue total is computed after the sign change, so the total is internally consistent but not financially validated.
- The absence of negative values in the PBIX cannot be used as evidence that none existed.

### Better decision

Preserve the signed value, classify the reason, and apply an explicit reporting rule. A credit should not become revenue merely because a dashboard cannot display a negative number.

**Status:** unresolved business rule. See [[05 - Data Cleaning Decisions#3. Negative MRR: the most consequential decision]].

## 2. Status: normalise the text, but do not define the states

### Recorded decision

Whitespace-only status becomes `NULL`; remaining text is Title Cased. Later, Power Query creates `status_cleaned`:

```text
Active      → Active
Cancelled   → Churned
Churned     → Churned
Downgraded  → Active
otherwise   → Unassigned
```

The DAX churn measures then use raw `status = "Cancelled"` rather than `status_cleaned`.

### Why it may have seemed reasonable

- Title casing makes the values consistent.
- `status_cleaned` gives the report three simple categories.
- The DAX measures were probably written before or alongside the Power Query layer, so they use the raw column they can see.

### What the decision cost

The project now has three different status models:

| Layer | Definition | Effect |
|---|---|---|
| SQL | Four Title Case states plus null | Preserves the source distinctions |
| Power Query | Active / Churned / Unassigned | Merges Cancelled + Churned; maps Downgraded to Active |
| DAX | Raw Cancelled for churn; raw Active for active customers | Disagrees with both the cleaned field and the narrative |

Consequences:

- `Active Customers` = 3,396 rows; `Active Subscriptions` = 5,070 rows.
- `Churned Customers` = 1,692 rows; `status_cleaned = "Churned"` = 3,257 rows.
- A customer can be in both the Active and Churned populations.
- The Insights page’s “mid-tier churn” claim uses `[Churned Customers]`, which excludes `Churned` rows.

### Better decision

Choose one canonical status taxonomy and make SQL, Power Query, DAX, and report copy use it. If `Cancelled` and `Churned` are distinct, keep both and define the difference. If they are the same, merge them once and use the merged field everywhere.

**Status:** unresolved taxonomy. See [[05 - Data Cleaning Decisions#1. Status: blanks, casing, and meaning]] and [[07 - Power Query Transformations#Why the Power Query layer matters]].

## 3. Plan mapping: a heuristic that hides what it cannot map

### Recorded decision

```sql
CASE
  WHEN LOWER(TRIM(plan_type)) LIKE 'start%' THEN 'Starter'
  WHEN LOWER(TRIM(plan_type)) LIKE 'growth%' THEN 'Growth'
  WHEN LOWER(TRIM(plan_type)) LIKE 'enterprise%'
       OR LOWER(TRIM(plan_type)) LIKE 'ent_l1%' THEN 'Enterprise'
  ELSE NULL
END
```

Power Query then replaces null plan values with `Unassigned`.

### Why it may have seemed reasonable

The three named plans are the business’s known products. Prefix matching handles casing and spelling variants. Turning everything else into a visible category is better than leaving nulls in a chart.

### What the decision cost

- The source values that failed to map are not preserved.
- A typo, a new plan, a legacy plan, and a genuinely missing plan all become `Unassigned`.
- The report can quantify the bucket but cannot diagnose it.
- The plan mapping is a text heuristic, not a product catalogue.
- The category is labelled like a plan, which invites the reader to treat it as one.

### Better decision

Keep the original plan value, map through a maintained table, and quarantine unmapped values. The exception report should show the source strings, not just the aggregate bucket.

**Status:** implemented heuristic; source catalogue missing. See [[05 - Data Cleaning Decisions#5. Plan type: heuristic mapping and Unassigned]].

## 4. `Unassigned` and `Unknown`: explicit defaults, but not root-cause analysis

### Recorded decision

- Blank plan → `Unassigned`.
- Blank acquisition channel → `Unknown`.
- Unknown region/tier → `UNKNOWN`.
- Null status → `status_cleaned = "Unassigned"`.

### Why it may have seemed reasonable

An explicit bucket prevents silent exclusion. A reader can see that attribution is incomplete rather than seeing a chart that quietly drops rows.

### What the decision cost

- The defaults are heterogeneous: `Unassigned` is a reporting label, `Unknown` is a channel label, and `UNKNOWN` is a region/tier value.
- The report can show the size of the gap but not its cause.
- A reader may treat `Unassigned` as a plan or `Unknown` as a real channel.
- The categories overlap across fields, so their percentages cannot be added.

### Better decision

Keep the explicit buckets but pair them with an exception table that records the original value, source system, row count, MRR, and owner. The bucket is the symptom; the exception table is the diagnostic.

**Status:** implemented defaults; root cause not investigated.

## 5. Customer dimension: one row is not the same as one truth

### Recorded decision

```sql
ROW_NUMBER() OVER (
  PARTITION BY customer_id ORDER BY signup_date DESC
) AS row_num
...
WHERE row_num = 1
```

The dimension keeps the attributes from each customer’s latest signup row.

### Why it may have seemed reasonable

- It produces exactly one row per customer, which is required for a clean one-to-many relationship.
- The latest signup record is a plausible proxy for the customer’s current region, tier, and channel.
- It avoids a complex SCD design in a portfolio project.

### What the decision cost

- Attribute history is lost. The report cannot show region or tier at the time of a subscription.
- The “latest” record may be a new subscription in a different region or tier, not a master-data update.
- Ties on `signup_date` have no deterministic tie-breaker.
- The selected attributes cannot be proven to be the customer’s current master data.
- 1,198 of 1,200 customers have multiple signup dates, so the choice affects almost every customer.

### Better decision

Use a proper SCD Type 2 dimension with effective dates, or a monthly customer snapshot. Add a deterministic tie-breaker such as `signup_date DESC, transaction_id DESC`. Document which source system owns each attribute.

**Status:** implemented latest-signup policy; semantic validity unverified. See [[06 - Data Model and Grain#Customer-dimension grain]].

## 6. Customer IDs: normalisation without collision testing

### Recorded decision

```sql
customer_id = CONCAT('CUST-', RIGHT(TRIM(customer_id), 4))
```

### Why it may have seemed reasonable

The source has multiple ID formats. Taking the last four characters produces a consistent `CUST-` format and a clean join key.

### What the decision cost

- The original identifier is discarded.
- Two distinct source IDs that share the same final four characters collapse into one customer.
- The output has 1,200 unique IDs, but that is the post-normalisation result, not a collision test.
- The join can silently merge customers and their revenue.

### Better decision

Preserve the original ID, create a mapping table from source ID to canonical customer key, and test for one-to-many and many-to-one collisions before replacing the key.

**Status:** collision-free identity unverified. See [[05 - Data Cleaning Decisions#7. Customer ID: normalisation, not identity resolution]].

## 7. Duplicate deletion: the logic can remove the wrong rows

### Recorded decision

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

### Why it may have seemed reasonable

The developer wanted to identify repeated rows and remove extras. A `ROW_NUMBER()` CTE is a common pattern.

### What the decision cost

- If `transaction_id` is unique, every row gets `row_num = 1`, and the delete removes nothing.
- If `transaction_id` repeats, every row with that ID can be deleted, not just the extra copy.
- There is no `ORDER BY`, so which row is retained is nondeterministic.
- The partition omits `cac_cost`, `status`, and `cancellation_date`.
- The final check uses a different duplicate definition, so it cannot validate the delete.

The imported model has 10,000 unique transaction IDs, but that may mean the delete had nothing to remove.

### Better decision

Define the business key first. Then use a deterministic `ROW_NUMBER()` with an explicit order and delete only `row_num > 1` rows by a stable surrogate key. Retain the pre- and post-delete counts.

**Status:** unsafe as written; effect unverified. See [[04 - SQL Development Timeline#Phase 12 — Duplicate investigation and deletion (lines 616–640)]].

## 8. Dates: signup was parsed, cancellation was coerced

### Recorded decision

Signup dates use a three-branch `STR_TO_DATE` conversion. Cancellation dates use:

```sql
UPDATE ... SET cancellation_date = NULL WHERE cancellation_date = '';
ALTER TABLE ... MODIFY cancellation_date DATE;
```

### Why it may have seemed reasonable

Signup date is central to the trend and slicers, so it received explicit format handling. Cancellation date is often blank, so converting blanks to null and letting MySQL cast the rest may have looked sufficient.

### What the decision cost

- The two date fields are not cleaned equivalently.
- A nonblank cancellation value in a mixed format could be coerced, truncated, or rejected depending on SQL mode.
- 371 cancellation dates fall after the latest signup date, including 5 after the documentation date.
- The date model is automatic; there is no controlled period dimension.

### Better decision

Profile every cancellation format, apply explicit `STR_TO_DATE` branches, retain the parse failures, and validate that cancellation dates are on or after signup and not in an unexplained future. Build a controlled date dimension.

**Status:** blank handling recorded; full parsing and future-date rule unverified.

## 9. Fact grain: a `GROUP BY` is not a grain definition

### Recorded decision

```sql
CREATE TABLE fact_subscriptions AS
SELECT transaction_id, customer_id, signup_date, plan_type,
       mrr_amount, cac_cost, status, cancellation_date
FROM vectra_analytics.stg_vectra_raw
GROUP BY transaction_id, customer_id, signup_date, plan_type,
         mrr_amount, cac_cost, status, cancellation_date;
```

### Why it may have seemed reasonable

`GROUP BY` removes exact duplicates and creates a compact table with the fields the report needs. `transaction_id` is assumed to be the key.

### What the decision cost

- The `GROUP BY` defines a distinct projection, not a business event.
- It does not establish whether a row is a current subscription, a transaction, a snapshot, or a mixture.
- `SUM(mrr_amount)` becomes an all-row total that is easy to mistake for current MRR.
- A customer can have many rows with different plans and statuses.
- The foreign key is added before the dimension exists.

### Better decision

Document the event being modelled. If the row is a subscription, include start/end dates and a status effective date. If it is a monthly snapshot, include a snapshot date and one row per customer per month. Then build the fact around that grain and reconcile it.

**Status:** grain inferred, not established. See [[06 - Data Model and Grain#Fact-table grain]].

## 10. Measure labels: arithmetic that is right but answers the wrong question

### Recorded decision

The active model contains 12 measures, including:

- `Active Customers = COUNTROWS(...)`.
- `Churned Customers = COUNTROWS(...)`.
- `Customer Count = COUNT(customer_id)`.
- `Annual ARPU = Total MRR ÷ DISTINCTCOUNT(customer_id)`.
- `Average Customer CAC = AVERAGE(cac_cost)`.

### Why it may have seemed reasonable

Each formula is simple and returns a number. The labels describe the business concept the developer intended to measure. In a portfolio project, the formulas may have been written before the grain and taxonomy issues were understood.

### What the decision cost

- A reader cannot trust the label.
- A “customer” number can be 8.33× the actual customer count.
- A “churn” number excludes a large churn-status population.
- An “annual” number has no annual period.
- A “CAC” number is per row, not per acquisition.
- The report’s visual titles repeat the ambiguity.

### Better decision

Name the measure for its unit and population, or change the calculation. A `DISTINCTCOUNT` measure is not automatically correct either; the active population and date must be defined. The formula should follow the definition, not the other way around.

**Status:** definitions unresolved. See [[08 - DAX and KPI Dictionary]].

## 11. Date model: automatic tables are convenient, not a semantic layer

### Recorded decision

The PBIX relies on Power BI automatic date tables for `signup_date` and `cancellation_date`. No standalone `dim_date` was created.

### Why it may have seemed reasonable

Automatic date tables require no modelling effort. The slicer works, the hierarchy expands, and the report can drill from year to quarter to month.

### What the decision cost

- No controlled date spine, fiscal calendar, or `IsCurrent` flag.
- No YoY measure in the active model, despite the handover’s claim.
- The slicer filters on signup date, not revenue period.
- Cancellation-date analysis has no active relationship.
- The “MRR Growth Trend” is a cohort chart, not a monthly trend.

### Better decision

Build a proper date dimension and define the active relationship around the revenue or snapshot date. Keep signup date as a separate cohort attribute. Add time intelligence only after the grain is correct.

**Status:** no standalone date table. See [[06 - Data Model and Grain#Date model]].

## 12. The Insights page: narrative outran the evidence

### Observed decision

The report includes a polished strategy page with:

- “Enterprise plan tier contributes the majority share.”
- “Cancellation counts are disproportionately clustered in Growth and Starter.”
- A 20% session-decline alert threshold.
- A 15% churn-reduction target.
- A 100% data-integrity target.

### Why it may have seemed reasonable

A portfolio report benefits from a business narrative. The page connects the data to actions and shows that the analyst can think beyond charts.

### What the decision cost

- Two factual claims conflict with the imported model.
- The impact figures are not modelled, tested, or sourced.
- The 20% threshold is presented without telemetry or validation.
- A reader may treat the page as the report’s conclusion rather than as a proposal.
- The page is the default active page, so it is the first thing a reader sees.

### Better decision

Separate **observed findings**, **hypotheses**, and **proposed actions** into distinct sections. Put the evidence and confidence beside each claim. Remove impact percentages until they are tested. Do not make the narrative page the default view.

**Status:** documented, not silently corrected. See [[09 - Power BI Dashboard Walkthrough]] and [[10 - Business Findings]].

## 13. Navigation: stale page IDs

### Observed decision

The report’s action buttons target page IDs. Four of those IDs do not match any page in the current file. As a result:

- Overview cannot navigate to Insights.
- Customer cannot navigate to Insights.
- Products cannot navigate to itself.
- Insights cannot navigate to itself.

### Why it may have happened

Page IDs can change when pages are duplicated, recreated, or migrated. Buttons may retain the old target. The report still renders, so the defect is easy to miss without clicking every button.

### What the decision cost

- A reader may never reach the strategic page.
- The selected-state styling may not display correctly.
- The report feels less finished than its visual design suggests.

### Better decision

Use the current page IDs, test every navigation path after any page change, and add a simple navigation checklist to the release process.

**Status:** report defect. See [[09 - Power BI Dashboard Walkthrough#Navigation rail]].

## 14. Documentation decisions in this vault

The source artifacts conflict. This vault deliberately resolves some questions and preserves others.

### Decisions made for the documentation

| Decision | Reason | Consequence |
|---|---|---|
| Treat the PBIX as authoritative for active model/report facts | It is the actual report, not a description of it | Handover claims about `dim_date`, YoY, and measure names are marked stale |
| Treat the SQL as a script, not an execution log | No outputs, DDL, or row counts were supplied | Every SQL claim is `SQL-RECORDED`, not “executed” |
| Add `PBIX-INSPECTED` and `MODEL-COMPUTED` labels | The handover’s label set did not distinguish model inspection from computation | Readers can see the evidence basis for report and value claims |
| Record source conflicts rather than silently harmonise them | The conflict is itself evidence of project risk | Some notes repeat the same conflict in different contexts |
| Do not alter the PBIX or SQL | The documentation documents the artifacts; it does not rewrite history | The broken navigation and unsupported claims remain visible |
| Do not fabricate screenshots or SQL outputs | No rendered pages or query results were available | The walkthrough is definition-level, not a visual review |
| Use relative Markdown links for source files, wikilinks for notes | Source files sit outside `VECTRA/`; notes are vault-native | Links work in Obsidian and in the file system |
| Mark all recommendations `RECOMMENDED` | None were implemented in the artifacts | No recommendation is presented as a result |

### What was not decided

- Whether `Cancelled` and `Churned` should be merged.
- Whether negative MRR represented refunds, credits, errors, or legitimate adjustments.
- Whether the fact is transaction-level or snapshot-level.
- Whether the latest signup record is the right customer master.
- Whether `Unassigned` should be excluded, retained, or remapped.
- Whether the business wants customer-level or subscription-level retention.

These are business decisions, not documentation decisions. The vault flags them rather than inventing answers.

## Cross-cutting lessons

1. **A cleaning step can be syntactically correct and semantically destructive.** Negative-sign removal is the clearest example.
2. **A one-row-per-customer dimension is not automatically a customer master.** The selection rule matters as much as the row count.
3. **A measure can be arithmetically valid and still be mislabelled.** `Annual ARPU` and `Churn Rate %` are the clearest examples.
4. **A polished narrative can outrun the data.** The Insights page is visually strong and evidentially weak.
5. **A report can be visually coherent and semantically fragmented.** The same words mean different things on different pages.
6. **Evidence labels are not bureaucracy.** They prevent a recorded statement from being mistaken for a verified result.
7. **The most useful validation question is often “what is the denominator?”** It exposes row-versus-customer confusion, filter-context changes, and ARPU errors.

## Related notes

- [[04 - SQL Development Timeline]]
- [[05 - Data Cleaning Decisions]]
- [[06 - Data Model and Grain]]
- [[08 - DAX and KPI Dictionary]]
- [[10 - Business Findings]]
- [[13 - Validation and Evidence Register]]
