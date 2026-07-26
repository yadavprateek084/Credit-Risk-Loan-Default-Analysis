DROP TABLE IF EXISTS loan_applications;

CREATE TABLE loan_applications (
    loan_id VARCHAR(20) PRIMARY KEY,
    borrower_id VARCHAR(20) NOT NULL,
    application_date DATE,
    loan_purpose VARCHAR(100),
    loan_amount NUMERIC(12,2),
    term_months INTEGER,
    interest_rate NUMERIC(5,2),
    monthly_payment NUMERIC(12,2),
    dti_ratio NUMERIC(5,2),
    loan_status VARCHAR(20),
    days_delinquent INTEGER,
    defaulted integer
);

DROP TABLE IF EXISTS borrower_profiles

create table borrower_profiles (
	borrower_id varchar(20),
	age integer,
	state varchar(10),
	education_level varchar(20),
	employment_status varchar(20),
	years_employed integer,
	annual_income integer,
	credit_score integer,
	home_ownership varchar(20),
	dependents integer,
	existing_monthly_debt integer
)

select * from borrower_profiles


select *
from loan_applications 


-- Q1A .total default rate
with cte as (select sum(defaulted) as ds,
	   count(*) as total
from loan_applications)
select concat(ds*100/total,' ','%') as defa
from cte

-- or

select sum(defaulted) as ds,
	   count(*) as total,
	   round(sum(defaulted)*100/
	   count(*),2) as default_rate
from loan_applications

-- Q2B. credit score categorisation , 

select
CASE
    WHEN bp.credit_score < 520 THEN 'very poor'
    WHEN bp.credit_score BETWEEN 520 AND 599 THEN '520-599'
    WHEN bp.credit_score BETWEEN 600 AND 649 THEN '600-649'
    WHEN bp.credit_score BETWEEN 650 AND 699 THEN '650-699'
    WHEN bp.credit_score BETWEEN 700 AND 749 THEN '750-749'
    ELSE '750+'
END AS credit_score_bucket , 
sum(la.defaulted) as ds,
	   count(*) as total,
	   concat(sum(defaulted)*100/
	   count(*),'%') as default_rate
from borrower_profiles bp
right join loan_applications la
on bp.borrower_id = la.borrower_id
group by credit_score_bucket 
order by default_rate desc


-- Q3A. WHICH LOAN PURPOSES HAVE THE HIGHEST DEFAULT RATES?
select loan_purpose,
	sum(defaulted) as total_default,
	count(*) as total_loans,
	concat(sum(defaulted)*100/count(*),' ','%') as default_rate
from loan_applications
group by 1
order by 4 desc


-- Q3B. DOES THE AVERAGE LOAN AMOUNT DIFFER SIGNIFICANTLY BETWEEN DEFAULTED AND NON-DEFAULTED LOANS
create table average_loan_amt as (
select defaulted ,
	count(*) as total_loans,
	round(avg(loan_amount),2) as avg_loan_amt,
	min(loan_amount),
	max(loan_amount)
from loan_applications
group by 1
)


-- Q4A. HOW DO EMPLOYMENT STATUS AFFECT DEFAULT RISK? 
create table default_by_employment as
(
select bp.employment_status ,
    sum(la.defaulted) as total_default,
	count(*) as total_loans,
	concat(sum(la.defaulted)*100/count(*),' ','%') as default_rate
from borrower_profiles bp
right join loan_applications la
on bp.borrower_id = la.borrower_id
group by 1
order by default_rate desc
)
select * from default_by_employment


--Q4B. HOW DO YEARS EMPLOYED AFFECT DEFAULT RISK? --

create table default_by_year_employed as
(
select 
CASE
    when bp.years_employed < 2 then '<2 years'
	when bp.years_employed between 2 and 5 then '2-5 years'
	when bp.years_employed between 6 and 10 then '6-10 years'
	else '10+ years'
END AS years_employed_bucket,
	sum(la.defaulted) as total_default,
	count(*) as total_loans,
	concat(sum(la.defaulted)*100/count(*),' ','%') as default_rate
from borrower_profiles bp
right join loan_applications la
on bp.borrower_id = la.borrower_id
group by years_employed_bucket
order by default_rate desc
)

select * from default_by_year_employed


-- -Q4C. ARE BORROWERS WITH LESS THAN 2 YEARS OF EMPLOYMENT MORE LIKELY TO DEFAULT?

create table default_less_than_2_Yr_emp as (
select 
CASE
    when bp.years_employed < 2 then '<2 years'
	else '2+ years'
END AS years_employed_bucket,
	sum(la.defaulted) as total_default,
	count(*) as total_loans,
	concat(sum(la.defaulted)*100/count(*),' ','%') as default_rate
from borrower_profiles bp
right join loan_applications la
on bp.borrower_id = la.borrower_id
where bp.years_employed < 2
group by years_employed_bucket
)

--Q5. How does default rate change across loan interest buckets?

create table default_rate_interest_buckets as (
select 
CASE
    WHEN interest_rate < 7 THEN '<7'
    WHEN interest_rate BETWEEN 7 AND 9 THEN '7-9'
    WHEN interest_rate BETWEEN 10 AND 12 THEN '10-12'
    WHEN interest_rate BETWEEN 13 AND 15 THEN '13-15'
    WHEN interest_rate BETWEEN 16 AND 17 THEN '16-17'
    ELSE '18+'
END as interest_rate_bucket,
	sum(defaulted) as total_default,
	count(*) as total_loans,
	concat(sum(defaulted)*100/count(*),' ','%') as default_rate
from loan_applications
group by interest_rate_bucket
order by default_rate desc
)

--Q6 How does default rate change across loan term buckets (short/medium/long) and does term interact with loan purpose?

create table default_loan_term_bucket as (
select 
CASE
    WHEN term_months < 12 THEN '< 12'
    WHEN term_months BETWEEN 12 AND 24 THEN '12-24'
    WHEN term_months BETWEEN 25 AND 36 THEN '25-36'
    WHEN term_months BETWEEN 37 AND 48 THEN '37-48'
    WHEN term_months BETWEEN 49 AND 60 THEN '49-60'
END as term_months_bucket,
	sum(defaulted) as total_default,
	count(*) as total_loans,
	concat(sum(defaulted)*100/count(*),' ','%') as default_rate
from loan_applications
group by term_months_bucket
order by default_rate desc
)

-- Q7 Within each credit score bucket,what's the average DTI and existing monthly debt 
--    are "good score, high DTI" borrowers hiding as a risky pocket the score alone wouldn't catch?

create table credit_score_vs_dti as (
select
  case
	WHEN bp.credit_score < 520 THEN '<520'
    WHEN bp.credit_score BETWEEN 520 AND 599 THEN '520-599'
    WHEN bp.credit_score BETWEEN 600 AND 649 THEN '600-649'
    WHEN bp.credit_score BETWEEN 650 AND 699 THEN '650-699'
    WHEN bp.credit_score BETWEEN 700 AND 749 THEN '750-749'
    ELSE '750+'
END AS credit_score_bucket , 
round(avg(dti_ratio),2) as avg_dti_ratio,
round(avg(monthly_payment),2) as avg_monthly_debt
from loan_applications la
left join borrower_profiles bp
on la.borrower_id = bp.borrower_id
group by credit_score_bucket
order by credit_score_bucket desc
)

-- Q8 Rank borrowers within each state by a composite risk indicator (e.g. DTI + inverse credit score)
--    using RANK() or DENSE_RANK() — who are the top20 riskiest active (Current) loans right now?

create table riskiest_active_loan_by_state as (
with cte as 
(
select state,bp.borrower_id, ((1000-credit_score)+dti_ratio) as risk_indicator ,
dense_rank()over(partition by state order by ((1000-credit_score)+dti_ratio) desc) as ranking
from loan_applications la
left join borrower_profiles bp
on la.borrower_id = bp.borrower_id
where loan_status = 'Current'
order by state,risk_indicator desc
)

select *
from cte
where ranking<4
)

--Q9 top20 riskiest active (Current) loans right now?

create table top20_risk_loans as 
(select state,bp.borrower_id, ((1000-credit_score)+dti_ratio) as risk_indicator 
from loan_applications la
left join borrower_profiles bp
on la.borrower_id = bp.borrower_id
where loan_status = 'Current'
order by risk_indicator desc
limit 20)


--Q10 What's the delinquency severity distribution( days_delinquent buckets: current, 1-30, 31-60, 60-90, 90+)
--    and how does it map to eventual default?

create table delinquency_severity_distribution as (
select
  case
	WHEN days_delinquent = 0 then '0'
	WHEN days_delinquent between 1 and 60 THEN '1-60'
    WHEN days_delinquent BETWEEN 61 AND 120 THEN '61-120'
    WHEN days_delinquent BETWEEN 121 AND 180 THEN '121-180'
END AS days_delinquent_bucket , 
	sum(defaulted) as total_default,
	count(*) as total_loans,
	concat(sum(defaulted)*100/count(*),' ','%') as default_rate
from loan_applications 
group by days_delinquent_bucket
order by days_delinquent_bucket desc
)


--Q11 Rank states by total exposure (sum of outstanding loan_amount on non-Paid-Off loans) 
--     using a window function, and flag the top 5 by risk-weighted exposure (exposure × default rate).

create table state_by_total_exposure  as (
with cte as
(
select state , sum(loan_amount) as exposure ,
		sum(defaulted) as total_default,
		count(*) as total_loans,
		(sum(defaulted)*100/count(*)) as default_rate		
from loan_applications la
left join borrower_profiles bp
on la.borrower_id = bp.borrower_id
where loan_status != 'Paid Off'
group by 1
order by default_rate desc
)

select *,round((exposure*default_rate::numeric/100)) as risk_weighted_exposure,
		dense_rank()over(order by (exposure*default_rate) desc) as rank
from cte
limit 5
)

-- Q12. What's the relationship between annual_income band and both DTI and default rate simultaneously?

create table income_band_DTI_default_rate as (
select 
	CASE
    WHEN annual_income BETWEEN 0 AND 49999 THEN '0-50K'
    WHEN annual_income BETWEEN 50000 AND 74999 THEN '50K-75K'
    WHEN annual_income BETWEEN 75000 AND 99999 THEN '75K-100K'
    WHEN annual_income BETWEEN 100000 AND 124999 THEN '100K-125K'
    ELSE '125K+'
END AS income_bucket,
	round(avg(dti_ratio),2) as avg_dti,
	sum(defaulted) as total_default,
	count(*) as total_loans,
	concat((sum(defaulted)*100/count(*)),' ','%') as default_rate
from loan_applications la
left join borrower_profiles bp
on la.borrower_id = bp.borrower_id
group by income_bucket
order by default_rate desc
)


--Q13 Estimate a simple Expected Loss proxy per loan segment:

create table expected_loss_per_loan as (

with cte as (select CASE
    WHEN credit_score < 300 then '< 300'
    WHEN credit_score BETWEEN 300 AND 579 THEN '300-579'
    WHEN credit_score BETWEEN 580 AND 669 THEN '580-669'
    WHEN credit_score BETWEEN 670 AND 739 THEN '670-739'
    WHEN credit_score BETWEEN 740 AND 799 THEN '740-799'
    WHEN credit_score >= 800 THEN '800+'
END AS credit_score_bucket,loan_purpose,
	round(avg(loan_amount),2) as avg_loan_amt,
	sum(defaulted) as total_default,
	count(*) as total_loans,
    (sum(defaulted)*100/count(*)) as default_rate_pct
from loan_applications la
left join borrower_profiles bp
on la.borrower_id = bp.borrower_id
group by 1,loan_purpose
order by 1 desc
)

select *,ROUND((default_rate_pct / 100.0) * avg_loan_amt, 2) AS expected_loss
from cte
)

-- Q14 Compare total interest income collected on Paid-Off loans vs total principal lost on Defaulted loans
-- —   is the portfolio net profitable, and by how much?

create table income_collected_paidoff_vs_loss as (

with cte as (select 
	sum(case 
		when loan_status = 'Paid Off' then round((interest_rate * loan_amount * term_months/12)) 
		else 0
		end)
		as amt_paid_off,
	sum(case
		when loan_status = 'Default' then round(loan_amount )
		else 0
		end)
		as amt_loss_default
from loan_applications la)

select *,round((amt_paid_off - amt_loss_default )) as net_profit ,
		round(( 100 * amt_loss_default / amt_paid_off ),2) as net_profit_pct
from cte
)


-- Q15 Using a moving average, does the default rate of loans originated 
--     in a given month trend up or down over time?

create table default_rate_moving_avg_month_trend as (

with cte as (
select DATE_TRUNC('month', application_date) loan_month,
	sum(defaulted) as total_default,
	count(*) as total_loans,
    (sum(defaulted)*100/count(*)) as default_rate_pct
from loan_applications
group by 1)

select loan_month,round(AVG(default_rate_pct) OVER (
    ORDER BY loan_month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
)) as moving_avg,total_default,total_loans,default_rate_pct
	
from cte
order by 1
)

-- Q16 Group loans by origination month (vintage) and show what percentage of each cohort has defaulted so far.

create table default_by_origin_month as (

WITH cohort AS (
    SELECT
        DATE_TRUNC('month', application_date) AS origin_month,
        COUNT(*) AS total_loans,
        SUM(defaulted) AS total_defaults,
        ROUND(100.0 * SUM(defaulted) / COUNT(*), 2) AS default_rate_pct
    FROM loan_applications
    GROUP BY 1
)

SELECT
    origin_month,
    total_loans,
    total_defaults,
    default_rate_pct
FROM cohort
ORDER BY origin_month
)


-- Q17 For each borrower who has taken more than one loan, display their loans in chronological order 
--     and, before each loan, show how many previous loans had defaulted.

create table borrower_more_than_one_loan as (

WITH loan_history AS (
    SELECT
        borrower_id,
        loan_id,
        application_date,
        loan_status,
        defaulted,
        COUNT(*) OVER (
            PARTITION BY borrower_id
        ) AS total_loans,
        COALESCE(
            SUM(defaulted) OVER (
                PARTITION BY borrower_id
                ORDER BY application_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),
            0
        ) AS prior_defaults
    FROM loan_applications
)

SELECT
    borrower_id,
    loan_id,
    application_date,
    loan_status,
    prior_defaults
FROM loan_history
WHERE total_loans > 1
ORDER BY borrower_id, application_date
)


--Q18. What percentile does each loan's interest_rate fall into relative to borrowers in the same credit-score bucket? 
--     Flag cases such as a top-tier borrower receiving an unusually high rate.

create table interest_rate_percentile as (

WITH loan_pricing AS (
    SELECT
        la.loan_id,
        la.borrower_id,
        la.interest_rate,
        bp.credit_score,

        CASE
            WHEN bp.credit_score < 300 THEN '<300'
            WHEN bp.credit_score BETWEEN 300 AND 579 THEN '300-579'
            WHEN bp.credit_score BETWEEN 580 AND 669 THEN '580-669'
            WHEN bp.credit_score BETWEEN 670 AND 739 THEN '670-739'
            WHEN bp.credit_score BETWEEN 740 AND 799 THEN '740-799'
            ELSE '800+'
        END AS credit_score_bucket

    FROM loan_applications la
    LEFT JOIN borrower_profiles bp
        ON la.borrower_id = bp.borrower_id
),

pricing_rank AS (
    SELECT
        *,
        ROUND(
            PERCENT_RANK() OVER (
                PARTITION BY credit_score_bucket
                ORDER BY interest_rate
            )::numeric * 100,
            2
        ) AS interest_rate_percentile

    FROM loan_pricing
)

SELECT
    *,
    CASE
        WHEN credit_score >= 740
             AND interest_rate_percentile >= 90
        THEN 'Pricing Review'
        ELSE 'Normal'
    END AS pricing_flag

FROM pricing_rank
ORDER BY interest_rate_percentile DESC
)

-- q19. Rank loan purposes within each state by default rate and return only the riskiest purpose in each state.

create table riskiest_loan_purpose_each_state as (

WITH purpose_default AS (
    SELECT
        bp.state,
        la.loan_purpose,
        COUNT(*) AS total_loans,
        SUM(la.defaulted) AS total_defaults,
        ROUND(
            100.0 * SUM(la.defaulted) / COUNT(*),
            2
        ) AS default_rate_pct

    FROM loan_applications la
    LEFT JOIN borrower_profiles bp
        ON la.borrower_id = bp.borrower_id

    GROUP BY
        bp.state,
        la.loan_purpose
),

ranked_purpose AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY state
            ORDER BY default_rate_pct DESC
        ) AS risk_rank

    FROM purpose_default
)

SELECT *
FROM ranked_purpose
WHERE risk_rank = 1
ORDER BY state
)

-- Q20. Calculate each state's monthly default rate, compare it with the previous month using LAG(),
--      and flag unusually large jumps.

WITH monthly_default AS (
    SELECT
        bp.state,
        DATE_TRUNC('month', la.application_date) AS loan_month,
        COUNT(*) AS total_loans,
        SUM(la.defaulted) AS total_defaults,
        ROUND(
            100.0 * SUM(la.defaulted) / COUNT(*),
            2
        ) AS default_rate_pct

    FROM loan_applications la
    LEFT JOIN borrower_profiles bp
        ON la.borrower_id = bp.borrower_id

    GROUP BY
        bp.state,
        DATE_TRUNC('month', la.application_date)
),

previous_month AS (
    SELECT
        *,
        LAG(default_rate_pct) OVER (
            PARTITION BY state
            ORDER BY loan_month
        ) AS previous_month_default_rate

    FROM monthly_default
),

mom_change AS (
    SELECT
        *,
        ROUND(
            default_rate_pct - previous_month_default_rate,
            2
        ) AS mom_change_points

    FROM previous_month
)

SELECT
    *,
    CASE
        WHEN mom_change_points > 5
        THEN 'Risk Alert'
        ELSE 'Normal'
    END AS risk_flag

FROM mom_change
ORDER BY state, loan_month


--Q21. Which 3 loan segments have high default rates relative to interest income earned?

WITH segment_performance AS (
    SELECT
        CASE
            WHEN bp.credit_score BETWEEN 300 AND 579 THEN 'Poor'
            WHEN bp.credit_score BETWEEN 580 AND 669 THEN 'Fair'
            WHEN bp.credit_score BETWEEN 670 AND 739 THEN 'Good'
            WHEN bp.credit_score BETWEEN 740 AND 799 THEN 'Very Good'
            ELSE 'Excellent'
        END AS credit_score_bucket,

        la.loan_purpose,

        COUNT(*) AS total_loans,

        ROUND(
            100.0 * SUM(la.defaulted) / COUNT(*),
            2
        ) AS default_rate_pct,

        ROUND(
            AVG(la.interest_rate),
            2
        ) AS avg_interest_rate,

        ROUND(
            AVG(la.loan_amount),
            2
        ) AS avg_loan_amount

    FROM loan_applications la
    LEFT JOIN borrower_profiles bp
        ON la.borrower_id = bp.borrower_id

    GROUP BY 1, 2
)

SELECT *,
       ROUND(
           default_rate_pct / NULLIF(avg_interest_rate, 0),
           2
       ) AS risk_return_ratio
FROM segment_performance
ORDER BY risk_return_ratio DESC
LIMIT 3;


--Q22. Where are we currently lending relatively little, despite historical performance suggesting the segment is safe?"

WITH segments AS (
    SELECT
        CASE
            WHEN bp.credit_score BETWEEN 300 AND 579 THEN 'Poor'
            WHEN bp.credit_score BETWEEN 580 AND 669 THEN 'Fair'
            WHEN bp.credit_score BETWEEN 670 AND 739 THEN 'Good'
            WHEN bp.credit_score BETWEEN 740 AND 799 THEN 'Very Good'
            ELSE 'Excellent'
        END AS credit_score_bucket,

        CASE
            WHEN bp.annual_income < 50000 THEN '<50K'
            WHEN bp.annual_income < 75000 THEN '50K-75K'
            WHEN bp.annual_income < 100000 THEN '75K-100K'
            WHEN bp.annual_income < 125000 THEN '100K-125K'
            ELSE '125K+'
        END AS income_bucket,

        la.loan_purpose,

        COUNT(*) AS total_loans,
        SUM(la.defaulted) AS total_defaults,

        ROUND(
            100.0 * SUM(la.defaulted) / COUNT(*),
            2
        ) AS default_rate_pct

    FROM loan_applications la
    LEFT JOIN borrower_profiles bp
        ON la.borrower_id = bp.borrower_id

    GROUP BY 1, 2, 3
)

SELECT *
FROM segments
WHERE total_loans < 100
  AND default_rate_pct < 5
ORDER BY default_rate_pct, total_loans;


--Q23. If the company tightened the credit-score cutoff by X points,
--     how many defaults would have been avoided versus how many good loans would have been rejected?

create table loan_avoided_default_good_rejected as (

SELECT
    COUNT(*) AS loans_that_would_be_rejected,

    SUM(
        CASE
            WHEN defaulted = 1 THEN 1
            ELSE 0
        END
    ) AS defaults_avoided,

    SUM(
        CASE
            WHEN loan_status = 'Paid Off' THEN 1
            ELSE 0
        END
    ) AS good_loans_rejected

FROM loan_applications la
LEFT JOIN borrower_profiles bp
    ON la.borrower_id = bp.borrower_id

WHERE bp.credit_score >= 600
  AND bp.credit_score < 650

)


