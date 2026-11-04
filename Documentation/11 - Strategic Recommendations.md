---
title: "11 - Strategic Recommendations"
tags:
  - vectra
  - note/recommendations
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Strategic Recommendations

> [!warning] These are proposals, not implemented changes
> Nothing in this note has been implemented in the inspected SQL script, PBIX model, or report. All recommendations are labelled `RECOMMENDED`. No impact percentage is claimed. The current evidence supports a set of **definition, governance, and modelling fixes**; it does not support a validated retention programme, a pricing change, or a production deployment.

## How these recommendations were derived

The recommendations follow four tests:

1. **Is the problem visible in the artifacts?** The SQL, PBIX model, measure definitions, or report definition must show it.
2. **Does it change a business number or a decision?** Cosmetic issues are separated from material ones.
3. **Can the problem be fixed without inventing business rules?** If a decision requires the business to define a term, the recommendation is to obtain that definition, not to guess.
4. **Is the proposed outcome measurable?** “Improve data quality” is not a completion criterion; an exception count with an owner and threshold is.

The claim-level basis is in [[13 - Validation and Evidence Register]]. The limitations that motivate the sequence are in [[14 - Known Limitations]].

## Recommendation portfolio

| # | Recommendation | Type | Priority | Status | Evidence trigger |
|---:|---|---|---|---|---|
| 1 | Agree a metric contract before quoting the dashboard | Measurement governance | P0 | `RECOMMENDED` | Measure labels contradict calculations |
| 2 | Define the fact grain and current-MRR rule | Data model / finance | P0 | `RECOMMENDED` | 8.33 rows per customer; all-row total |
| 3 | Review negative-MRR sign removal as a business rule | Finance / data quality | P0 | `RECOMMENDED` | SQL strips leading minus signs |
| 4 | Establish a canonical status taxonomy | Business rules | P0 | `RECOMMENDED` | Cancelled vs Churned vs Downgraded vs null used inconsistently |
| 5 | Build plan, region, and channel mapping tables with owners | Data governance | P1 | `RECOMMENDED` | $4.73M Unassigned; 16.67% UNKNOWN region; 21.14% Unknown channel |
| 6 | Replace row-count measures with explicitly named row or customer measures | Measurement / DAX | P1 | `RECOMMENDED` | Active Customers 3,396 rows vs 1,135 customers |
| 7 | Build a controlled date dimension and separate signup from revenue period | Data model | P1 | `RECOMMENDED` | No `dim_date`; no YoY; signup-date trend |
| 8 | Historise customer attributes or snapshot them with a tie-breaker | Data model | P1 | `RECOMMENDED` | Latest-signup policy; tied dates; 1,198 multi-signup customers |
| 9 | Preserve source customer IDs and test for collisions | Data quality | P1 | `RECOMMENDED` | `CUST-` + last four characters |
| 10 | Fix duplicate logic and make the SQL rerunnable | Engineering | P1 | `RECOMMENDED` | No `ORDER BY`; delete by `transaction_id`; no transaction |
| 11 | Turn the churned/unassigned table into a prioritised exception queue | Reporting | P2 | `RECOMMENDED` | 4,930 rows across 1,188 customers |
| 12 | Test the 20% usage-decline hypothesis with a controlled pilot | Customer Success | P2 | `RECOMMENDED` | No telemetry; threshold unvalidated |
| 13 | Research the Growth-to-Enterprise value boundary before changing price | Product strategy | P2 | `RECOMMENDED` | Growth rate 18.13% vs 16.44% Enterprise; modest difference |
| 14 | Fix report navigation, labels, and unsupported narrative claims | Reporting | P1 | `RECOMMENDED` | Invalid page IDs; “majority” and “cluster” claims |
| 15 | Add validation queries, retained outputs, and refresh monitoring | Operations | P2 | `RECOMMENDED` | No execution log, DDL, or refresh evidence |

## 1. Agree the metric contract first (P0)

### Why

The report’s most consequential problem is not a missing visual. It is that the same business words mean different things across SQL, Power Query, DAX, and the page copy:

- **Customer** sometimes means a `customer_id`, sometimes a fact row.
- **Active** means raw `status = "Active"` in one card and `status_cleaned = "Active"` in another.
- **Churn** means `Cancelled` in the measure, `Cancelled + Churned` in `status_cleaned`, and a qualitative story on the Insights page.
- **Revenue** means an all-row sum in every visual.
- **Tier** means `plan_type` in chart titles but `dim_customers[tier]` in the data dictionary.

No amount of DAX rewriting fixes this until the business agrees what each term means.

### Recommended metric contract

| Concept | Decision required | Why it must be explicit |
|---|---|---|
| Fact grain | Is a row a current subscription, a transaction, a monthly snapshot, or a mixture? | Determines whether summing MRR is meaningful |
| Current MRR | Which statuses and as-of date count? Is it a snapshot or a period total? | Prevents an all-row total being called current revenue |
| Customer | Company, billing account, contract, or subscription? | Determines the correct denominator |
| Active customer | Raw Active, cleaned Active, or at least one active subscription as of a date? | Changes the active count and ARPU denominator |
| Churn | Which statuses, over what period, with what denominator? | The current measure is not a churn rate |
| Cancelled vs Churned | Are they distinct lifecycle stages or duplicate labels? | The report currently uses both inconsistently |
| ARPU | Monthly or annual? Revenue basis? Active or all customers? | The current measure is neither monthly nor annual |
| CAC | Per customer, per acquisition, or allocated per row? | The current average is per row |
| Currency | Is `$` USD, a reporting currency, or a display convention? | No currency table or code exists |

### Completion criteria

- A one-page metric dictionary approved by the business owner.
- Each measure has an owner, definition, formula, grain, and permitted use.
- The dictionary is linked from the report and the repository.
- Every visual uses the approved term or an explicitly different label.

**Status:** not started in the inspected artifacts.

## 2. Resolve the fact grain and current-MRR definition (P0)

### What the evidence shows

The fact has:

- 10,000 rows.
- 1,200 distinct customers.
- 8.33 rows per customer on average.
- 1,198 customers with more than one signup date.
- 24 customer/signup groups with more than one row.

The SQL creates the fact with an eight-column `GROUP BY`, which behaves like a distinct projection. It does not establish whether a row is a current subscription, a historical transaction, a snapshot, or a mixture.

### Recommendation

Choose one of two explicit designs:

**Option A — Transaction/event fact.** Keep one row per subscription event, with start and end dates, and compute MRR as of a date from overlapping active subscriptions. This requires a clear subscription lifecycle and effective-dated plan/price.

**Option B — Monthly snapshot fact.** Create one row per customer per month with opening/closing MRR, status, plan, and usage. This makes current MRR and cohort analysis straightforward but requires a snapshot process.

Do not mix the two in one table and call the sum “MRR.”

### Completion criteria

- A written grain statement.
- A test that the chosen key is unique at that grain.
- A current-MRR query with an as-of date.
- A reconciliation to a second source or independent total.
- A visual that labels the measure by its actual grain.

## 3. Review negative MRR as a financial rule (P0)

### What the evidence shows

The SQL does this:

```sql
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(mrr_amount, '-', '')
WHERE mrr_amount LIKE '-%';
```

This turns negative values into positive values. It does not record the original value or the reason. The imported model has no negative MRR values, but that is a consequence of the transformation, not proof that the transformation was correct.

### Recommendation

1. Preserve the original signed amount in an audit column.
2. Classify negative rows by source reason: refund, credit, reversal, adjustment, data-entry error, or legitimate negative contract.
3. Apply an explicit business rule:
   - Keep as negative revenue where the business treats it as a reduction.
   - Exclude from MRR and report separately where it is a one-off credit.
   - Correct at source where it is a data-entry error.
4. Reconcile the resulting total to a billing or finance baseline.

**Do not** silently convert all negatives to positive revenue. That changes the financial meaning of every total that includes them.

**Status:** the sign removal is recorded; the business rule is unresolved.

## 4. Establish a canonical status taxonomy (P0)

### What the evidence shows

The same customer lifecycle is represented three ways:

| Layer | Values | Consequence |
|---|---|---|
| SQL `status` | `Active`, `Cancelled`, `Churned`, `Downgraded`, `NULL` | Four non-null states plus missing |
| Power Query `status_cleaned` | `Active`, `Churned`, `Unassigned` | Merges Cancelled + Churned; maps Downgraded to Active |
| DAX churn measures | raw `status = "Cancelled"` | Excludes Churned; ignores `status_cleaned` |

The result:

- `Active Customers` = 3,396 raw Active rows.
- `Active Subscriptions` = 5,070 cleaned Active rows.
- `Churned Customers` = 1,692 raw Cancelled rows.
- `status_cleaned = "Churned"` = 3,257 rows.

### Recommendation

- Define each state in business language, including whether `Cancelled` and `Churned` are different stages.
- Decide whether `Downgraded` is active, at risk, or a separate state.
- Decide what null status means: unknown, inactive, not recorded, or not applicable.
- Store the mapping in a table, not an `if` chain scattered across Power Query and DAX.
- Make every measure reference the canonical field or mapping.

### Completion criteria

- A status codebook with an owner.
- One row per source status and its reporting category.
- A test that every non-null source status maps to exactly one reporting category.
- A report that uses one active definition and one churn definition consistently.

## 5. Govern plan, region, and channel mappings (P1)

### What the evidence shows

| Field | Exception | Scale |
|---|---|---:|
| Plan | `Unassigned` | 1,232 rows; $4,728,753; 12.08% of all-row MRR |
| Region | `UNKNOWN` | 1,664 rows; $6,525,129; 16.67% |
| Channel | `Unknown` | 2,096 rows; $8,276,576; 21.14% |
| Status | `NULL` | 1,673 rows; $6,316,094; 16.13% |

### Recommendation

1. Create a **plan mapping table** with source value, canonical plan, effective dates, owner, and status.
2. Create equivalent mapping tables for region/tier and acquisition channel.
3. Reject or quarantine unmapped values before they reach the reporting layer.
4. Keep `Unassigned` and `Unknown` as explicit exception buckets, not silent defaults.
5. Publish an exception count and trend, not just a percentage.
6. Assign an owner and a service-level target for resolving exceptions.

> [!warning] Do not promise 100% data integrity
> The Insights page says the governance initiative will produce “100% data integrity for board-level reporting.” No system can guarantee that, and the project has no validation results. A realistic target is a measured reduction in unmapped records with an agreed tolerance and an auditable exception process.

## 6. Replace ambiguous measures with explicit ones (P1)

### Recommended measure changes

| Current measure | Problem | Recommended direction |
|---|---|---|
| `Total MRR` | All-row sum | Rename to `All-Row MRR Total` until a current-MRR definition exists; then add `Current MRR (as of date)` |
| `Active Customers` | Counts raw Active rows | Rename to `Active Subscription Rows`; add `Distinct Customers with Active Subscription` if that is the intended KPI |
| `Churned Customers` | Counts Cancelled rows only | Rename to `Cancelled Rows`; add a separate `Distinct Churned Customers` under an agreed status definition |
| `Churn Rate %` | Row share, no period | Rename to `Cancelled Row Share`; build `Period Churn Rate` only with a cohort/period denominator |
| `Annual ARPU` | Not annualised | Rename to `All-Row Revenue per Customer`; build true monthly/annual ARPU from period revenue and an active-customer denominator |
| `Customer Count` | Counts fact rows | Rename to `Subscription Row Count`; add `Distinct Customer Count` |
| `Average Customer CAC` | Average per row | Rename to `Average CAC per Subscription Row`; build `CAC per Acquired Customer` from acquisition events |
| `Customers Enterprise %` | Revenue share | Rename to `Enterprise Revenue Share`; add a separate customer-share measure if needed |
| `Active Subscriptions` | Includes Downgraded | Rename to `Active + Downgraded Subscription Rows`, or define an explicit subscription-active rule |

### Guiding rule

A measure name should answer three questions without a tooltip:

1. **Unit:** dollars, rows, customers, or percent?
2. **Population:** which statuses, plans, and dates?
3. **Denominator:** what is it divided by?

If the name cannot answer those, it is not a KPI yet.

## 7. Build a controlled date dimension (P1)

### What the evidence shows

- No standalone `dim_date`.
- Automatic date tables for `signup_date` and `cancellation_date`.
- No YoY measure in the active model.
- The “MRR Growth Trend” is by signup date.
- 371 cancellation dates fall after the latest signup date.

### Recommendation

1. Create a dated `dim_date` with a continuous date spine, fiscal calendar, year/quarter/month/day, and an `IsCurrent` flag.
2. Define the active relationship: probably `fact[revenue_date]` or `fact[snapshot_date]`, not `signup_date`.
3. Add an inactive relationship to `cancellation_date` and use `USERELATIONSHIP` only where a cancellation-date analysis is intended.
4. Separate **signup cohort** analysis from **revenue period** analysis. They answer different questions.
5. Add YoY/month-over-month measures only after the date and grain are correct.

**Do not** add a YoY measure to the current model just because the handover says one exists. The active model has no suitable date table or period revenue grain.

## 8. Historise customer attributes or snapshot them deliberately (P1)

### What the evidence shows

`dim_customers` keeps one row per `customer_id`, selected by the latest `signup_date`. It:

- Returns 1,200 unique customer IDs in the imported model.
- Does not preserve region, tier, or channel history.
- Has no tie-breaker for two rows with the same latest signup date.
- Cannot prove that the latest signup record is the customer’s current master data.
- Relies on customer IDs normalised to `CUST-` plus the last four characters.

### Recommendation

Choose a deliberate design:

**Option A — SCD Type 2 customer dimension.** Add `valid_from`, `valid_to`, `is_current`, and a stable surrogate key. Preserve attribute history. Use a deterministic tie-breaker (for example, `signup_date DESC, transaction_id DESC`).

**Option B — Periodic customer snapshot.** One row per customer per month with the attributes in effect at the snapshot date. This is simpler for point-in-time reporting but requires a snapshot process.

Either option must preserve the original customer identifier and test for collisions before replacing it.

### Completion criteria

- A documented tie-breaker.
- A test that every customer has exactly one current row.
- A test that no two source IDs collapse to the same normalised ID.
- A report that can show “region at signup” versus “region today,” if that distinction matters.

## 9. Make the SQL reproducible and auditable (P1)

### Problems in the current script

- In-place updates to the only staging table.
- No transaction wrapper.
- No idempotency guard.
- Destructive `DROP COLUMN` operations.
- A duplicate CTE partitioned by `transaction_id` with no `ORDER BY`.
- A foreign key added before the referenced dimension table is created.
- No retained query outputs or execution log.
- No explicit numeric type for `mrr_amount`.

### Recommendation

1. Preserve an immutable raw table.
2. Build cleaning steps as views or new tables, not repeated in-place updates.
3. Add a deterministic duplicate rule and a test that proves what was removed.
4. Create the dimension before the fact foreign key.
5. Add transactions and failure handling where the MySQL version supports them.
6. Retain row-count and null-count outputs as artifacts.
7. Add a schema migration or rebuild script with explicit types.
8. Run the script on a clean database and attach the execution log.

**Completion evidence:** a fresh rebuild with reproducible row counts and constraints, not just a script that contains the statements.

## 10. Turn the watchlist into a real exception queue (P2)

### What the evidence shows

The Customer and Products tables filter to:

```text
status_cleaned IN ("Churned", "Unassigned")
```

That population is **4,930 rows across 1,188 customers** — 99% of the customer base. It is not a prioritised list.

### Recommendation

Define the operational question first. For example:

- “Which customers have an active subscription and a high-risk signal before renewal?”
- “Which accounts have an unmapped plan and material MRR?”
- “Which customers have a cancellation date in the next 90 days?”

Then build a queue with:

1. One row per customer.
2. The relevant risk or exception reason.
3. Current MRR or contract value.
4. Renewal date or cancellation date.
5. Owner and next action.
6. A priority rule agreed with Customer Success.

**Do not** use the existing table as a call list. It contains almost every customer and repeats customers across rows.

## 11. Test the 20% usage-decline hypothesis (P2)

### What the evidence shows

The Insights page proposes CRM alerts when active sessions fall by 20% or more and claims a 15% reduction in voluntary churn. The dataset contains **no session, usage, telemetry, or CRM activity data**. The 20% threshold is a management hypothesis, not a calibrated predictor.

### Recommendation

Run a small, controlled pilot before operationalising the threshold:

| Design element | Required decision |
|---|---|
| Population | Which customers are eligible? Mid-tier only, or all? |
| Signal | What exactly is measured: sessions, feature events, seats, logins, or a composite? |
| Threshold | Is 20% a decline from a rolling baseline, previous month, or pre-renewal period? |
| Outcome | Renewal, cancellation, downgrade, or expansion within a defined window |
| Control | Comparable customers not alerted, or a stepped-wedge rollout |
| Baseline | Historical churn rate for the eligible population |
| Decision rule | What result would justify scaling, changing, or stopping the pilot? |
| Guardrails | False positives, customer fatigue, CS capacity |

### What not to claim

- Do not call the 20% threshold a validated churn predictor.
- Do not attach a 15% reduction to the pilot before it runs.
- Do not describe the existing report as a churn-risk model.

**Status:** no telemetry, pilot, or evaluation exists in the artifacts.

## 12. Research the Growth-to-Enterprise boundary before changing price (P2)

### What the evidence shows

Growth has the highest Cancelled-only rate at **18.13%**, compared with Enterprise 16.44% and Starter 16.19%. The difference is modest, and when Cancelled and Churned are combined, the rates are 32.17%–35.71% across plans, with the Unassigned plan bucket highest.

A customer can hold all four plan categories, and plan is a row-level attribute. The model cannot tell whether Growth customers are “stuck” below Enterprise, whether they downgrade, or whether their contract value is growing.

### Recommendation

Before changing price or packaging:

1. Interview Growth customers and Customer Success.
2. Analyse plan transitions at the customer level, not row-level plan counts.
3. Compare feature adoption, seat counts, contract value, and renewal outcomes.
4. Run a win/loss or downgrade review.
5. Test a packaging or migration change with a defined cohort and success metric.

**Do not** use the 18.13% figure as proof of a Growth problem or as a forecast of upgrade revenue.

## 13. Fix the report’s narrative and navigation (P1)

### What to change

| Issue | Recommended action |
|---|---|
| Overview and Customer Insights buttons do not resolve | Replace stale page IDs with current IDs; test every navigation button |
| “Enterprise majority” | Correct to “largest plan at 36.14%” or remove the claim |
| “Cancellations clustered in Growth/Starter” | Remove or replace with the actual counts and modest rate differences |
| “15% reduction in voluntary churn” | Label as a hypothesis or remove until tested |
| “100% data integrity” | Replace with a measurable exception-reduction target |
| “Annual ARPU” | Rename or recalculate; add a definition tooltip |
| “Customer Volume” | Rename to “Subscription Rows by Plan” |
| “Monetization Yield by Account Tier” | Use `plan_type` in the title or use the `tier` field |
| “Revenue by Tier” | Rename to “Revenue by Plan” |
| “Customer ID” column in Products | It is a COUNT aggregation, not an identifier; rename it explicitly and verify what it returns, or replace it with a defined distinct-customer measure |
| “Monthly Revenue” column | Rename to “All-Row MRR” or calculate a real monthly measure |
| Static text with `[Measure]` placeholders | Replace with narrative or bind dynamic values correctly |
| Churn table filter | Explain the 4,930-row denominator in a subtitle or tooltip |

### Report design principle

A reader should be able to answer “what does this number mean?” without opening the DAX editor. Add a definitions page or tooltip panel, and keep the unsupported strategic claims out of the data pages.

## 14. Add validation and monitoring (P2)

### Minimum validation set

| Check | Expected result | Failure action |
|---|---|---|
| Fact row count | Matches the source extract | Block refresh |
| Unique `transaction_id` | 100% | Quarantine duplicates |
| Unique `customer_id` in dimension | 100% | Block relationship |
| Fact customers missing from dimension | 0 | Quarantine |
| Dimension customers missing from fact | 0 or explained | Investigate |
| Negative MRR | 0 or explicitly classified | Review business rule |
| Null MRR | Within agreed tolerance | Flag |
| Null status | Within agreed tolerance | Flag |
| Unmapped plan | Within agreed tolerance | Flag and assign owner |
| Unknown region/channel | Within agreed tolerance | Flag and assign owner |
| Cancellation before signup | 0 | Quarantine |
| Future-dated cancellation | Explained | Investigate |
| Current MRR reconciliation | Matches baseline | Block publication |

### Monitoring

- Store each refresh’s counts.
- Alert on threshold breaches, not just failed refreshes.
- Record who resolved each exception and when.
- Keep a change log for mapping tables and measure definitions.
- Add a data-quality page to the report, with exception counts and trends.

## 15. Sequence the work

### Phase 0 — Stop the bleeding (1–2 weeks)

- Freeze the unsupported Insights claims.
- Add a caveat banner to the report: “All-row model; not current MRR.”
- Fix the navigation links.
- Rename the most misleading measures or add definitions.
- Preserve the current PBIX and SQL as evidence snapshots.

### Phase 1 — Define (2–4 weeks)

- Agree fact grain, current MRR, customer, active, churn, ARPU, CAC, and status taxonomy.
- Approve the plan/region/channel mapping ownership.
- Review negative-MRR treatment with finance.
- Write the metric dictionary.

### Phase 2 — Rebuild the model (4–8 weeks)

- Build the canonical mapping tables.
- Build a controlled date dimension.
- Build the customer history or snapshot design.
- Separate current MRR from all-row transaction value.
- Add validation tests and retained outputs.

### Phase 3 — Rebuild the report (2–4 weeks)

- Replace ambiguous measures.
- Rebuild the pages around the approved metrics.
- Turn the watchlist into a prioritised queue.
- Add definitions, tooltips, and data-quality visibility.
- Remove or qualify the unsupported narrative.

### Phase 4 — Test the business hypotheses (6–12 weeks)

- Run the usage-decline pilot with a control.
- Research the Growth-to-Enterprise boundary.
- Evaluate CAC and retention with cohort data.
- Report results with uncertainty, not a single impact claim.

### Phase 5 — Operationalise (ongoing)

- Schedule refresh and monitor it.
- Add access controls, deployment, and rollback.
- Version the model and mappings.
- Review metrics quarterly with business owners.

## What not to do

- **Do not add more charts before fixing definitions.** A polished chart with the wrong denominator is still wrong.
- **Do not buy a churn-prediction tool** before obtaining telemetry and a validated outcome definition.
- **Do not set a 15% churn-reduction target** from a page that has no baseline or experiment.
- **Do not claim 100% data integrity.** Use explicit tolerances and exception ownership.
- **Do not “fix” the $4.73M by deleting Unassigned rows.** That would hide revenue and bias the plan mix.
- **Do not describe the latest-signup dimension as an SCD Type 2.**
- **Do not publish the current PBIX as production-ready.**

## Definition of done for a decision-ready version

A future version is decision-ready only when it can demonstrate:

- [ ] A documented fact grain and a current-MRR definition.
- [ ] One approved customer definition and one active-customer definition.
- [ ] A churn definition with period and denominator.
- [ ] Reconciled revenue to an independent baseline.
- [ ] A status codebook and mapping tables with owners.
- [ ] A controlled date dimension.
- [ ] Customer attribute history or a deliberate snapshot policy.
- [ ] Measures whose names match their units, populations, and denominators.
- [ ] Validation queries with retained outputs.
- [ ] A report with working navigation and no unsupported impact claims.
- [ ] A refresh, monitoring, and ownership model.

Until then, the project remains a **portfolio artifact with a strong evidence trail**, not a production analytics system.

## Related notes

- [[02 - Business Problem and Scope]]
- [[08 - DAX and KPI Dictionary]]
- [[10 - Business Findings]]
- [[12 - Challenges and Decisions]]
- [[13 - Validation and Evidence Register]]
- [[15 - Future Improvements]]
