---
title: "15 - Future Improvements"
tags:
  - vectra
  - note/roadmap
  - note/improvements
project_status: "Portfolio project — evidence-qualified; not production-ready"
date: 2026-11-03
---

# Future Improvements

> [!warning] This is a backlog, not a delivery record
> Every item here is `RECOMMENDED` and **not implemented** in the inspected SQL or PBIX. Effort and sequencing are indicative. The correct order is definition first, model second, report third, experiments fourth, production last.

## Improvement principles

1. **Fix definitions before formulas.** A correct DAX expression for the wrong population is still the wrong KPI.
2. **Preserve evidence.** Raw data, query outputs, mapping tables, and validation results should be retained.
3. **Prefer explicit exceptions over silent defaults.** `Unassigned`, `Unknown`, and `UNKNOWN` should be visible and owned.
4. **One metric, one name, one definition.** A measure should state its unit, population, and denominator.
5. **Do not operationalise an unvalidated hypothesis.** The 20% usage-decline threshold needs a controlled test, not a production alert.
6. **Do not call a portfolio artifact production-ready.** Production readiness is an operational property, not a visual style.

## Prioritised backlog

| Priority | Workstream | Item | Effort | Depends on | Success measure |
|---:|---|---|---|---|---|
| P0 | Measurement | Approve a metric contract | Medium | Business owner | Signed definitions for grain, MRR, customer, active, churn, ARPU, CAC |
| P0 | Finance | Review negative-MRR treatment | Medium | Source reason codes | Every negative classified; policy approved |
| P0 | Data quality | Preserve raw data and retain SQL outputs | Low | Workspace access | Immutable raw table + execution log + row counts |
| P0 | Reporting | Freeze unsupported Insights claims | Low | None | No unsupported impact figure in the report |
| P1 | Data model | Define fact grain and current-MRR rule | High | Metric contract | One documented grain; current-MRR query reconciles |
| P1 | Data model | Build a controlled date dimension | Medium | Grain decision | Continuous date table; active relationship; YoY tested |
| P1 | Customer | Historise or snapshot customer attributes | High | Metric contract | One current row per customer; tie-breaker; history queryable |
| P1 | Identity | Preserve source IDs and test collisions | Medium | Raw data | Zero unexplained many-to-one mappings |
| P1 | SQL | Rebuild duplicate logic and make the script rerunnable | Medium | Business key | Clean rebuild with deterministic dedupe |
| P1 | Measurement | Rename or recalculate ambiguous measures | Medium | Metric contract | No measure name contradicts its calculation |
| P1 | Report | Fix navigation, labels, and definitions | Low | Page IDs | Every button tested; every label matches its field |
| P1 | Data quality | Build plan/region/channel mapping tables | High | Owners | Exception rate measured and trending down |
| P2 | Reporting | Turn the watchlist into a prioritised queue | Medium | Customer definition | One row per customer; priority rule agreed |
| P2 | Validation | Add automated data-quality tests | Medium | Model rebuild | Every refresh runs the test suite |
| P2 | Experiment | Pilot the 20% usage-decline hypothesis | High | Telemetry + CS capacity | Pre-registered outcome and control group |
| P2 | Analysis | Research the Growth-to-Enterprise boundary | Medium | Customer history | Evidence-based packaging decision |
| P3 | Operations | Add refresh, monitoring, and access control | High | Production requirements | SLA, alerting, owner, rollback tested |
| P3 | Publication | Create a real Git history and remote | Low | User decision | Commit history and remote visible |

## Workstream 1 — Measurement contract

### Deliverables

- A one-page metric dictionary.
- An owner for each metric.
- A definition of the fact grain.
- A definition of current MRR, including as-of date and status treatment.
- Customer, active-customer, and churn definitions.
- ARPU and CAC definitions with numerator, denominator, and period.
- A currency and unit convention.
- A status codebook.

### Acceptance criteria

- Every measure in the model maps to one dictionary entry.
- Every visual uses an approved metric or an explicitly different label.
- The definitions are linked from the report and the README.
- A reviewer can explain the difference between `Active Customers` and `Active Subscriptions` without opening DAX.

### Open questions to resolve

| Question | Why it blocks progress |
|---|---|
| Is a row a subscription, transaction, or snapshot? | Determines whether MRR can be summed |
| Is `Cancelled` different from `Churned`? | Changes churn numerator |
| Is `Downgraded` active, at risk, or separate? | Changes active population |
| Does null status mean unknown or inactive? | Changes denominators |
| Is ARPU monthly or annual? | Changes formula and label |
| Is CAC per customer or per acquisition? | Changes unit economics |
| Is `$` USD? | Changes any financial comparison |

## Workstream 2 — Data foundation

### 2.1 Raw and staging layers

- Keep an immutable raw table or source extract.
- Build cleaning steps as new tables/views, not repeated in-place updates.
- Add a load timestamp and source file identifier.
- Preserve original customer ID, plan string, status string, MRR string, and date string in an audit table.
- Add a schema version and a change log.

### 2.2 SQL rebuild

- Create `dim_customers` before adding the fact foreign key.
- Use explicit column types, especially for `mrr_amount`.
- Add transactions and failure handling where supported.
- Make the script idempotent or clearly one-shot.
- Retain the pre-clean and post-clean row counts.
- Retain the parse-failure rows for dates and numerics.
- Add a deterministic duplicate rule based on the agreed business key.
- Test the rebuild on a clean database.

### 2.3 Data-quality outputs

Create a persisted quality table with:

| Column | Purpose |
|---|---|
| `run_id` | Identify the refresh |
| `check_name` | Test name |
| `expected` | Expected result or threshold |
| `actual` | Observed result |
| `status` | Pass / warn / fail |
| `row_count` | Scale of the issue |
| `mrr_affected` | Financial exposure where relevant |
| `owner` | Resolution owner |
| `resolved_at` | Closure timestamp |

This converts data quality from a one-off narrative into an operational process.

## Workstream 3 — Dimensional model

### 3.1 Fact grain

Choose one:

**Transaction/event fact**

- One row per subscription event.
- Start and end dates.
- Effective-dated plan and price.
- Status effective date.
- Current MRR computed as of a date from active intervals.

**Monthly snapshot fact**

- One row per customer per month.
- Opening MRR, closing MRR, status, plan, seats, usage.
- Snapshot date.
- Current MRR is the latest completed month.

Do not mix the two in one table.

### 3.2 Date dimension

- Continuous date spine.
- Fiscal and calendar hierarchies.
- `IsCurrent`, `IsCompleteMonth`, `FiscalYear`.
- Active relationship to the revenue/snapshot date.
- Inactive relationship to cancellation date.
- Explicit `USERELATIONSHIP` measures for cancellation analysis.
- YoY and month-over-month measures tested against a known baseline.

### 3.3 Customer dimension

- Surrogate key.
- Original source ID.
- SCD Type 2 validity dates or monthly snapshot.
- `is_current` flag.
- Deterministic tie-breaker.
- Attribute owners for region, tier, and channel.
- A test that every customer has exactly one current row.

### 3.4 Plan and status dimensions

- Plan mapping table: source value, canonical plan, effective dates, owner.
- Status codebook: source value, reporting category, definition, active/churn treatment.
- Unknown/Unassigned categories as explicit members.
- Referential integrity tests.
- No ad-hoc `if` mapping in multiple layers.

## Workstream 4 — Measure remediation

### Current-to-target map

| Current | Proposed target | Formula direction |
|---|---|---|
| `Total MRR` | `All-Row MRR Total` and `Current MRR (as of date)` | Separate all-row and current measures; do not reuse one name |
| `Active Customers` | `Active Subscription Rows` and `Distinct Customers with Active Subscription` | Count rows and distinct customers separately |
| `Churned Customers` | `Cancelled Rows` and `Distinct Churned Customers` | Define status inclusion explicitly |
| `Churn Rate %` | `Cancelled Row Share` and `Period Churn Rate` | Period churn needs cohort denominator |
| `Annual ARPU` | `All-Row Revenue per Customer` and `Monthly/Annual ARPU` | True ARPU needs period revenue and active customers |
| `Customer Count` | `Subscription Row Count` and `Distinct Customer Count` | Separate units |
| `Average Customer CAC` | `Average CAC per Subscription Row` and `CAC per Acquired Customer` | Acquisition events required |
| `Customers Enterprise %` | `Enterprise Revenue Share` and `Enterprise Customer Share` | Separate revenue and customer shares |

### Acceptance criteria

- Every measure has a description in the model.
- Every measure has a format string consistent with its unit.
- No measure name uses “customer” unless it returns a distinct customer count.
- No measure name uses “annual” unless it is annualised.
- No churn measure uses “rate” without a period and denominator.
- A measure-level test file contains expected values for known filter contexts.

## Workstream 5 — Report redesign

### 5.1 Page structure

A stronger report might use:

1. **Executive summary** — current MRR, active customers, churn, data-quality confidence, each with definitions.
2. **Revenue** — current MRR by plan/region, movement bridge (new, expansion, contraction, churn), not an all-row share.
3. **Customers** — distinct customers, new/churned/retained, cohort retention.
4. **Product/plan** — plan migration, revenue and retention by plan.
5. **Data quality** — exception counts, owners, trends.
6. **Definitions** — metric dictionary and status codebook.

This is a direction, not a requirement to add pages. Fewer, better-defined pages are preferable.

### 5.2 Report fixes

- Replace stale navigation IDs and test every button.
- Make Overview the default page.
- Remove or qualify the unsupported Insights claims.
- Replace static bracketed measure placeholders with text or bound values.
- Rename `Customer ID` in the Products table to an explicit count label, verify whether it returns rows or customers, and replace it with a defined measure.
- Rename `Monthly Revenue` to the actual measure.
- Add subtitles explaining table filters and denominators.
- Add tooltips with metric definitions.
- Make the watchlist one row per customer and prioritised.
- Add a data-quality page with exception counts and trends.

### 5.3 Visual QA

- Capture full-page screenshots after a real desktop review.
- Test at 100%, 125%, and 150% scaling.
- Check color contrast and label fit.
- Test every slicer, cross-filter, drill, and navigation button.
- Test with empty selections and extreme filters.
- Record the test date and reviewer.

## Workstream 6 — Validation and reconciliation

### Test suite

| Test | Expected | Severity |
|---|---|---|
| Fact row count vs source | Exact or explained | Critical |
| Unique transaction key | 100% | Critical |
| Unique customer key in dimension | 100% | Critical |
| Referential integrity | 0 orphans | Critical |
| Current MRR vs finance baseline | Within agreed tolerance | Critical |
| Negative MRR | 0 or classified | High |
| Null MRR | Within tolerance | High |
| Null status | Within tolerance | High |
| Unmapped plan | Within tolerance | High |
| Unknown region/channel | Within tolerance | High |
| Cancellation before signup | 0 | High |
| Future cancellation | Explained | Medium |
| Duplicate business combinations | 0 or explained | Medium |
| Date parse failures | 0 or quarantined | Medium |

### Reconciliation

At minimum:

1. Source extract row count → staging row count.
2. Staging row count → fact row count.
3. Fact MRR → finance or billing total.
4. Dimension customer count → source customer count.
5. Current MRR → an independent as-of-date calculation.

Retain the outputs. A test without a retained result is only a intention.

## Workstream 7 — Analysis and experiments

### 7.1 Retention pilot

Before deploying CRM alerts:

- Define the eligible population.
- Define the usage signal and baseline.
- Pre-register the 20% threshold or test several thresholds.
- Define the outcome window.
- Use a control group or stepped-wedge rollout.
- Track false positives and Customer Success capacity.
- Publish the result with uncertainty.

### 7.2 Plan migration

- Build a customer-level plan transition history.
- Distinguish upgrade, downgrade, cross-sell, and churn.
- Compare revenue and retention by transition path.
- Interview Growth customers and CSMs.
- Test packaging changes with a defined cohort.

### 7.3 Unit economics

- Define acquisition events.
- Allocate CAC to cohorts.
- Calculate gross margin and payback.
- Add retention and expansion.
- Do not compute LTV from a single all-row revenue total.

## 30 / 60 / 90-day plan

### First 30 days

- Freeze unsupported narrative claims.
- Fix navigation.
- Add a report caveat.
- Preserve raw data and current artifacts.
- Draft the metric contract.
- Review negative-MRR treatment with finance.
- Inventory plan/region/channel source values.

### Days 31–60

- Approve the status codebook.
- Build mapping tables.
- Define fact grain and current-MRR rule.
- Rebuild the SQL in a clean environment.
- Add validation queries and retain outputs.
- Rename the most misleading measures.

### Days 61–90

- Build the date dimension.
- Build the customer history or snapshot.
- Rebuild the core report pages on approved metrics.
- Launch the retention pilot design.
- Add refresh monitoring and ownership.
- Review results with stakeholders.

## Risks to manage

| Risk | Mitigation |
|---|---|
| Definition debates stall delivery | Time-box workshops; assign a decision owner |
| Mapping tables become stale | Owner, review cadence, and alerting |
| “Current MRR” is defined differently by finance and product | One approved definition with a reconciliation |
| Customer history is too large to rebuild | Start with monthly snapshots; iterate |
| Churn pilot lacks data | Do not launch; instrument telemetry first |
| Report scope expands | Fix definitions and core pages before adding visuals |
| Stakeholders want the 15% claim | Present it as a hypothesis with a test plan, not a forecast |
| Production work is underestimated | Treat operations as a separate phase with an owner |

## Definition of done

- [ ] Metric contract approved.
- [ ] Fact grain documented and tested.
- [ ] Current MRR reconciles.
- [ ] Negative-MRR policy approved.
- [ ] Status codebook approved.
- [ ] Customer dimension historised or snapshotted.
- [ ] Source IDs preserved and collision-tested.
- [ ] Duplicate logic deterministic.
- [ ] Date dimension controlled.
- [ ] Measures named for their units and populations.
- [ ] Report navigation and labels verified.
- [ ] Unsupported claims removed or qualified.
- [ ] Validation outputs retained.
- [ ] Refresh monitored.
- [ ] Ownership assigned.
- [ ] Git history and remote established, if publication is intended.

Until these are true, the project remains a **well-documented portfolio exercise**, not a production revenue analytics system.

## Related notes

- [[11 - Strategic Recommendations]]
- [[12 - Challenges and Decisions]]
- [[13 - Validation and Evidence Register]]
- [[14 - Known Limitations]]
- [[16 - Artifact Inventory]]
