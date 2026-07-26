# Credit Risk & Loan Portfolio Analytics (PostgreSQL)

Analysis of a loan portfolio of **601 loans across 500 borrowers**, built entirely in PostgreSQL. The project goes beyond basic reporting — it uses window functions, CTEs, and multi-dimensional segmentation to answer the kinds of questions a credit risk / collections team actually asks: who's riskiest right now, where is pricing inconsistent, and which segments are safe to grow into.

## What this project does

- **Risk segmentation** across 9 dimensions: credit score, loan purpose, employment status, years employed, interest rate band, loan term, income band, state, and delinquency severity
- **Borrower & loan risk ranking** — `DENSE_RANK()` on a composite DTI + inverse-credit-score indicator, partitioned by state, to identify the highest-risk *active* loans for collections prioritization
- **Pricing anomaly detection** — `PERCENT_RANK()` within credit-score peer groups to flag borrowers priced inconsistently relative to same-tier peers (e.g. a top-tier score paying a high rate)
- **Geographic exposure analysis** — states ranked by total and risk-weighted exposure (`exposure × default rate`) using window functions, to support capital-allocation-style decisions
- **Time-based trend analysis** — rolling/moving-average default rate by origination month, plus vintage (cohort) analysis showing default rate by loan-origination cohort
- **Borrower history analysis** — for repeat borrowers, a running count of prior defaults before each new loan, using a windowed running total
- **Executive synthesis** — risk-adjusted segment scoring to flag the worst risk/return segments, and a "safe growth" query identifying low-volume, low-default segments worth expanding into
- **Expected Loss proxy** and portfolio profitability (interest income vs. default losses) modeled at the segment level

## SQL techniques used

CTEs (`WITH`), `DENSE_RANK()`, `PERCENT_RANK()`, `LAG()`, windowed `SUM()`/`AVG()` with custom frames (`ROWS BETWEEN ... PRECEDING`), `PARTITION BY`, conditional aggregation (`CASE` + `SUM`), `HAVING`, `DATE_TRUNC` for monthly/cohort grouping, and materialized analytical tables for downstream BI use.

## Schema

**`loan_applications`** — loan_id, borrower_id, application_date, loan_purpose, loan_amount, term_months, interest_rate, monthly_payment, dti_ratio, loan_status, days_delinquent, defaulted

**`borrower_profiles`** — borrower_id, age, state, education_level, employment_status, years_employed, annual_income, credit_score, home_ownership, dependents, existing_monthly_debt

Joined on `borrower_id`.

## Repo structure

```
sqlnew.sql   -- all analysis queries, in sequence
README.md
```

## Notes

This is a portfolio project built on a static dataset, not a deployed production system — the queries model *decision support* (who to flag, where to reprice, where to grow) rather than measured real-world outcomes. A few earlier diagnostic queries have known rounding issues that are being cleaned up; the advanced/window-function queries (pricing percentile, state ranking, vintage, cohort, MoM anomaly flagging) are correct as written.

## Next steps

- Add borrower demographic segmentation (age, education, income quartiles via `NTILE`, home ownership)
- Add a portfolio-level KPI summary and loan-status funnel
- Power BI dashboard layer on top of the materialized tables
