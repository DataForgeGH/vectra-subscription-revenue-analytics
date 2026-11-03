# Vectra Subscription Revenue Analytics

**Turning raw subscription data into business insights using SQL and Power BI.**

## Project Overview

Vectra Global Technologies is a fictional B2B SaaS company used as the business context for this analytics project.

The project explores how subscription data can help a business understand its revenue performance, customer activity, subscription plans, and data-quality challenges.

Using **MySQL and Power BI**, I worked through a data analytics workflow from inspecting and cleaning raw records to building a report designed to communicate findings and support business decisions.

## Business Problem

Subscription businesses need more than revenue figures to understand their performance. They need to know where revenue comes from, how customers interact with different plans, and whether incomplete or inconsistent data is affecting the reliability of their reporting.

This project focuses on four key areas:

- **Revenue Performance:** Understanding revenue distribution across subscription plans.
- **Customer & Retention Analytics:** Exploring customer activity and churn-related patterns.
- **Product & Subscription Performance:** Comparing subscription plans and their contribution to revenue.
- **Data Quality:** Identifying missing and inconsistent information that could affect business reporting.

## Tools & Technologies

| Tool | Purpose |
|---|---|
| MySQL | Data inspection, cleaning, and relational modelling |
| Power BI | Data modelling, KPI development, and dashboard design |
| Power Query | Data transformation |
| DAX | Calculated measures and business metrics |
| Git & GitHub | Version control and project documentation |

## Project Workflow

The project followed an end-to-end analytics workflow:

1. **Data Inspection:** Explored the raw subscription data and identified inconsistencies.
2. **SQL Data Cleaning:** Worked on standardising customer identifiers, dates, monetary values, subscription plans, and other fields.
3. **Data Modelling:** Structured the data into customer and subscription tables for reporting.
4. **Power BI Development:** Connected the data model, applied Power Query transformations, and developed DAX measures.
5. **Dashboard Development:** Designed a four-page report to present revenue, customer, subscription, and strategic insights.

## Power BI Dashboard

![Power BI Executive Revenue Pulse dashboard](Screenshot%202026-11-03%20025518.png)

The report is organised into four pages, each focusing on a different business perspective.

### 1. Overview — Executive Revenue Pulse

Provides a high-level view of subscription revenue, customer activity, plan distribution, and key performance indicators.

### 2. Customer & Retention Analytics

Explores customer activity, acquisition channels, regional status patterns, and customer records requiring attention.

### 3. Product & Subscription Performance

Examines revenue distribution across subscription plans and compares key subscription performance indicators.

### 4. Strategic Insights & Recommendations

Translates the analysis into business observations and proposed actions around revenue concentration, customer retention, and data quality.

## Selected Findings

The report's inspected model snapshot surfaced several areas worth investigating:

- **Revenue concentration:** The Enterprise plan represented approximately 36.14% of reported total MRR, making it the largest plan contributor.
- **Unassigned subscription plans:** Approximately $4.73 million, or 12.08% of the reported MRR total, was associated with records without an assigned plan type.
- **Incomplete customer attributes:** Some records contained unknown regional and acquisition-channel information.
- **Customer-status inconsistencies:** Different status values, including `Cancelled` and `Churned`, required careful interpretation before drawing retention conclusions.

These findings highlight why data quality and clear metric definitions matter when translating subscription records into business insights.

*Note: The reported MRR figure is an all-row sum in the available model snapshot, not a verified point-in-time recurring revenue balance. The findings should therefore be interpreted within the limitations of the dataset and measures.*

## Key Challenges

Some of the most important work involved resolving inconsistencies rather than simply building visuals.

- Standardising inconsistent date formats and customer identifiers.
- Handling missing subscription and customer attributes.
- Investigating conflicting customer attributes when preparing the customer dimension.
- Working with inconsistent subscription-status values.
- Distinguishing revenue-based measures from actual customer-count metrics.

These challenges influenced how the data was prepared and how the report's findings should be interpreted.

## Limitations & Future Improvements

The project is a portfolio analysis, not a production reporting system. Some areas require further validation and refinement:

- Review customer-dimension logic and historical attribute changes.
- Validate the treatment of negative MRR values.
- Refine churn, active-customer, and ARPU definitions to align with clear business rules.
- Introduce more rigorous data-quality and reconciliation checks.
- Improve time-based analysis using a dedicated date dimension and clearly defined reporting periods.

Being transparent about these limitations is part of the analytical process: a dashboard is only as reliable as the data and definitions behind it.

## Repository Structure

```text
vectra-subscription-revenue-analytics/
│
├── README.md
├── sql/
│   └── vectra_subscription_analytics.sql
│
├── powerbi/
│   └── vectra_analytics.pbix
│
└── docs/
    └── project_documentation.md
```

*The structure above represents the intended repository organisation; include only files that are actually committed.*

## Project Takeaway

This project demonstrates my ability to approach a business problem through data: inspect raw information, clean and structure it with SQL, develop analytical measures, build a Power BI report, and communicate findings that can inform business decisions.

**The objective was not simply to create a dashboard, but to understand the data behind it and recognise what the business can — and cannot — conclude from it.**
