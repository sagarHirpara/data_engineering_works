select
	*
from
	subscriptions
where
	customer_id < 9;

/* Based off the 8 sample customers provided in the sample from the subscriptions table, 
 write a brief description about each customer�s onboarding journey. */
/* customer 1 started the first try the trial subscription of foodie-fi and customer use the trial plan till 1 week and 
 after then he buy a basic monthaly plan with price 9.90 with limited access, can stream video for 1 month. */
/* customer 2 started the first try the trial subscription of foodie-fi on 2020-09-20 and customer use the trial plan till 1 week and 
 after then he buy a pro annual plan with price 199 with fully access, with no watch limit and can download videos offline and can view */
/* customer 3 started the first try the trial subscription of foodie-fi on 2020-01-13 and customer use the trial plan till 1 week and 
 after then he buy a basic monthaly plan with price 9.90 with limited access, can stream video for 1 month. */
/* customer 4 started the first try the trial subscription of foodie-fi on 2020-01-17 and customer use the trial plan till 1 week and 
 after then he buy a basic monthaly plan with price 9.90 with limited access, can stream video for 1 month.
 after complete of the monthaly plan after 3 month, he cancel the food service on 2020-04-21*/
/* customer 5 started the first try the trial subscription of foodie-fi on 2020-08-03 and customer use the trial plan till 1 week and 
 after then he buy a basic monthaly plan with price 9.90 with limited access, can stream video for 1 month. */
/* customer 6 started the first try the trial subscription of foodie-fi on 2020-12-23 and customer use the trial plan till 1 week and 
 after then he buy a basic monthaly plan with price 9.90 with limited access, can stream video for 1 month.
 after complete of the monthaly plan, around 1 month, he cancel the food service on 2021-02-26*/
/* customer 7 started the first try the trial subscription of foodie-fi on 2020-02-05 and customer use the trial plan till 1 week and 
 after then he buy a basic monthaly plan with price 9.90 with limited access, can stream video for 1 month.
 after complete of the monthaly plan, around 4 month, he buy pro monthaly plan on 2020-05-22*/
/* customer 8 started the first try the trial subscription of foodie-fi on 2020-06-11 and customer use the trial plan till 1 week and 
 after then he buy a basic monthaly plan with price 9.90 with limited access, can stream video for 1 month.
 after complete of the monthaly plan, around 1 month, he buy pro monthaly plan on 2020-08-03*/
---  B. Data Analysis Questions
-- B1. How many customers has Foodie-Fi ever had?
select
	count(distinct customer_id) as total_customer
from
	subscriptions;

-- B2. What is the monthly distribution of trial plan start_date values for our dataset
-- use the start of the month as the group by value
select
	DATEPART(month, start_date) as month,
	datepart(year, start_date) as year,
	count(*) as no_of_trial_distribustion
from
	subscriptions 
where
	plan_id = 0
group by
	DATEPART(month, start_date),
	datepart(year, start_date)
order by
	month;

-- b3. What plan start_date values occur after the year 2020 for our dataset?
-- Show the breakdown by count of events for each plan_name
select
	plan_name,
	count(*)
from
	subscriptions s
	join plans p on p.plan_id = s.plan_id
where
	datepart(year, start_date) > 2020
group by
	plan_name;

-- b4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select
	count(*) as churn_count,
	cast(
		(count(*) * 100) / (
			select
				count(distinct customer_id)
			from
				subscriptions
		) as decimal(5, 2)
	) as churned_percentage
from
	dbo.subscriptions
where
	plan_id = 4;

-- b5. How many customers have churned straight after their initial free trial
-- what percentage is this rounded to the nearest whole number?
with cte as (
	select
		*,
		ROW_NUMBER() over(
			partition by customer_id
			order by
				plan_id
		) row_num
	from
		subscriptions
)
select
	count(*) churned_count,
	round(
		(count(*) * 100) / (
			select
				count(distinct customer_id)
			from
				subscriptions
		),
		0
	) as curned_percentage
from
	cte
where
	plan_id = 4
	and row_num = 2;

-- b6. What is the number and percentage of customer plans after their initial free trial?
-- total percentage of customer wo have planed after intial planed
with cte as (
	select
		customer_id
	from
		subscriptions
	where
		plan_id <> 4
	group by
		customer_id
	having
		count(*) > 1
)
select
	count(*) as customer,
	(count(*) * 100) / (
		select
			count(distinct customer_id)
		from
			subscriptions
	) as percentage
from
	cte -- percentage of customer according next plan accuried
	with cte as (
		select
			*,
			LEAD(plan_id) over(
				partition by customer_id
				order by
					plan_id
			) as next_plan
		from
			subscriptions
	)
select
	next_plan,
	count(*) next_plan_customer,
	(count(*) * 100) / (
		select
			count(distinct customer_id)
		from
			subscriptions
	) as percentage
from
	cte
where
	next_plan is not null
	and plan_id = 0
group by
	next_plan;

-- b7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH next_plan AS(
	SELECT
		customer_id,
		plan_id,
		start_date,
		LEAD(start_date, 1) OVER(
			PARTITION BY customer_id
			ORDER BY
				start_date
		) as next_date
	FROM
		subscriptions
	WHERE
		start_date <= '2020-12-31'
),
customer_breakdown AS (
	SELECT
		plan_id,
		COUNT(DISTINCT customer_id) AS customers
	FROM
		next_plan
	WHERE
		(
			next_date IS NOT NULL
			AND (
				start_date < '2020-12-31'
				AND next_date > '2020-12-31'
			)
		)
		OR (
			next_date IS NULL
			AND start_date < '2020-12-31'
		)
	GROUP BY
		plan_id
)
SELECT
	plan_id,
	customers,
	ROUND(
		100 * customers / (
			SELECT
				COUNT(DISTINCT customer_id)
			FROM
				subscriptions
		),
		1
	) AS percentage
FROM
	customer_breakdown
GROUP BY
	plan_id,
	customers
ORDER BY
	plan_id;

-- b8. How many customers have upgraded to an annual plan in 2020?
select
	COUNT(DISTINCT customer_id) AS unique_customer
from
	subscriptions
where
	(
		plan_id = 3
		and start_date between '2020-01-01' and '2020-12-31'
	);

-- b9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with trail_plan as (
	select
		customer_id,
		start_date as trial_date
	from
		subscriptions
	where
		plan_id = 0
),
annual_plan as (
	select
		customer_id,
		start_date as annual_date
	from
		subscriptions
	where
		plan_id = 3
)
select
	avg(datediff(day, trial_date, annual_date)) * 1.0 avg_days_for_annual_sub
from
	annual_plan a
	join trail_plan t on t.customer_id = a.customer_id;

-- b10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with trail_plan as (
	select
		customer_id,
		start_date as trial_date
	from
		subscriptions
	where
		plan_id = 0
),
annual_plan as (
	select
		customer_id,
		start_date as annual_date
	from
		subscriptions
	where
		plan_id = 3
),
date_diff as (
	select
		t.customer_id,
		datediff(day, trial_date, annual_date) as days
	from
		annual_plan a
		join trail_plan t on t.customer_id = a.customer_id
),
bucket as (
	select
		cast(((days -1) / 30) * 30 as varchar(4)) + ' - ' + cast((((days -1) / 30) + 1) * 30 as varchar) + ' days' as interval
	from
		date_diff
)
select
	interval,
	count(*) no_of_customer
from
	bucket
group by
	interval;

-- b11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with cte as (
	select
		*,
		lead(plan_id) over(
			partition by customer_id
			order by
				start_date
		) as next_plan
	from
		subscriptions
	where
		start_date < '2020-12-31'
)
select
	count(*) as downgraded_customer
from
	cte
where
	next_plan = 1
	and plan_id = 2;

-- C. Challenge Payment Question
with next_date as(
	SELECT
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date payment_date,
		s.start_date,
		LEAD(s.start_date, 1) OVER(
			PARTITION BY s.customer_id
			ORDER BY
				s.start_date,
				s.plan_id
		) next_date,
		p.price amount
	FROM
		subscriptions s
		left join plans p on p.plan_id = s.plan_id
),
remove_trial_churn as(
	SELECT
		customer_id,
		plan_id,
		plan_name,
		payment_date,
		start_date,
		case
			when next_date is null
			or next_date > '2020-12-31' then cast('2020-12-31' as date)
			else next_date
		end as next_date,
		amount
	from
		next_date
	where
		plan_name not in ('churn', 'trial')
),
cte as(
	select
		customer_id,
		plan_id,
		plan_name,
		payment_date,
		start_date,
		next_date,
		dateadd(month, -1, next_date) next_date1,
		amount
	from
		remove_trial_churn
),
payment_dat as (
	SELECT
		customer_id,
		plan_id,
		plan_name,
		start_Date,
		payment_date,
		next_date,
		next_date1,
		amount
	FROM
		cte a
	union all
	SELECT
		customer_id,
		plan_id,
		plan_name,
		start_Date,
		dateadd(M, 1, payment_date) payment_date,
		next_date,
		next_date1,
		amount
	FROM
		payment_dat b
	where
		payment_date < next_date1
		and plan_id ! = 3
)
select
	customer_id,
	plan_id,
	plan_name,
	payment_date,
	amount,
	rank() over(
		partition by customer_id
		order by
			customer_id,
			plan_id,
			payment_date
	) as payment_order
from
	payment_dat
where
	YEAR(payment_date) = 2020
ORDER BY
	customer_id,
	plan_id,
	payment_date;

-- D. . Outside The Box Questions
-- 1. How would you calculate the rate of growth for Foodie-Fi?
with cte as (
	select
		month(start_date) as mon,
		year(start_date) as yea,
		count(*) no_of_trials,
		lag(count(*)) over(
			order by
				month(start_date),
				year(start_date)
		) as previous_num
	from
		subscriptions
	where
		plan_id = 0
	group by
		month(start_date),
		year(start_date)
)
select
	mon,
	yea,
	no_of_trials,
	((no_of_trials - previous_num) * 100) / previous_num
from
	cte;

-- 2. What key metrics would you recommend Foodie-Fi management
-- to track over time to assess performance of their overall business?
/* The key metrics to track to assess performance over time include:
 
 1. number of new customers for each month in a year
 2. number of churns after trial for each month
 3. number of upgrades from basic monthly to pro monthly or pro annual plans
 4. revenue from each month for each year
 5. number of customers for each month */
-- 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
/* To improve customer retention I have analyze:
 
 1. customers who churned after trial
 2. customers who downgraded
 3. customers who churned after subscribing to any of the plans after trial
 4. customers who upgraded their subscriptions
 5. customers who upgraded from trial to pro annual 
 
 by grouping this all part and after analyze that we can improve customer retention. 
 */
-- 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription,
--what questions would you include in the survey?
/* 
 1. Why did you sign up for the service?
 2. Was the service what you expected?
 3. Have you tried a similar service? How does our service compare?
 4. How can we improve?
 
 */
-- 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate?
-- How would you validate the effectiveness of your ideas?
/*
 1. offering discounts
 2. offering an option to pause subscriptions
 3. offering special packages engaging them */
