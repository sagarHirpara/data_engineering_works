-- A. Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?
select
	count(distinct node_id) as unique_node
from
	customer_nodes;

-- 2. What is the number of nodes per region?
select
	r.region_id,
	count(distinct node_id) node
from
	customer_nodes c
	join regions r on r.region_id = c.region_id
group by
	r.region_id;

-- 3. How many customers are allocated to each region?
select
	region_name,
	count(distinct customer_id) no_of_customer
from
	customer_nodes c
	join regions r on r.region_id = c.region_id
group by
	r.region_name;

-- 4. How many days on average are customers reallocated to a different node?
with cte as (
	select
		customer_id,
		node_id,
		start_date,
		lag(node_id) over(
			partition by customer_id
			order by
				start_date
		) as pre_node,
		lag(start_date) over(
			partition by customer_id
			order by
				start_date
		) as pre_date
	from
		customer_nodes
),
cte2 as(
	select
		*,
		case
			when node_id ! = pre_node then datediff(day, pre_date, start_date)
			else 0
		end diff
	from
		cte
	where
		node_id ! = pre_node
)
select
	avg(diff) avg
from
	cte2;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with cte as (
	select
		region_id,
		customer_id,
		node_id,
		start_date,
		lag(node_id) over(
			partition by customer_id
			order by
				start_date
		) as pre_node,
		lag(start_date) over(
			partition by customer_id
			order by
				start_date
		) as pre_date
	from
		customer_nodes
),
cte2 as(
	select
		*,
		case
			when node_id ! = pre_node then datediff(day, pre_date, start_date)
			else 0
		end diff
	from
		cte
	where
		node_id ! = pre_node
)
select
	distinct region_name,
	PERCENTILE_CONT(0.5) within group(
		order by
			diff
	) over(partition by c.region_id) median,
	PERCENTILE_CONT(0.8) within group(
		order by
			diff
	) over(partition by c.region_id) as '80th',
	PERCENTILE_CONT(0.95) within group(
		order by
			diff
	) over(partition by c.region_id) '95th'
from
	cte2 c
	join regions on c.region_id = regions.region_id;

--  B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?
select
	txn_type,
	count(*) total_count,
	sum(txn_amount) total_amount
from
	customer_transactions
group by
	txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
select
	count(*) / count(distinct customer_id) avg_deosite_count,
	sum(txn_amount) / count(distinct customer_id) avg_dpo_amount
from
	customer_transactions
where
	txn_type = 'deposit';

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with cte as (
	select
		customer_id,
		cast(month(txn_date) as varchar) + '-' + cast(year(txn_date) as varchar) as date,
		sum(
			case
				when txn_type = 'deposit' then 1
				else 0
			end
		) total_deposite,
		sum(
			case
				when txn_type = 'purchase' then 1
				else 0
			end
		) total_purchase,
		sum(
			case
				when txn_type = 'withdrawal' then 1
				else 0
			end
		) total_withdrawal
	from
		customer_transactions
	group by
		cast(month(txn_date) as varchar) + '-' + cast(year(txn_date) as varchar),
		customer_id
)
select
	date,
	count(distinct customer_id) total_customer
from
	cte
where
	total_deposite > 1
	and (
		total_purchase >= 1
		or total_withdrawal >= 1
	)
group by
	date;

-- 4. What is the closing balance for each customer at the end of the month?
with cte as(
	select
		customer_id,
		cast(month(txn_date) as int) as month,
		sum(
			case
				when txn_type = 'deposit' then txn_amount
				else - txn_amount
			end
		) as txn_amount
	from
		customer_transactions
	group by
		customer_id,
		month(txn_date)
),
cte2 as(
	select
		customer_id,
		month,
		txn_amount + coalesce(
			lag(txn_amount) over(
				partition by customer_id
				order by
					month
			),
			0
		) as txn_amount,
		lag(month) over(
			partition by customer_id
			order by
				month
		) as pre_month,
		lead(month) over(
			partition by customer_id
			order by
				month
		) as next_month
	from
		cte
),
txt as(
	select
		customer_id,
		month,
		txn_amount,
		coalesce(pre_month, 0) as pre_month,
		coalesce(next_month, 5) as next_month
	from
		cte2
	union all
	select
		customer_id,
		(month + 1) as month,
		txn_amount,
		pre_month,
		next_month
	from
		txt
	where
		month < next_month -1
)
select
	customer_id,
	month,
	txn_amount
from
	txt
order by
	customer_id,
	month;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
with cte as(
	select
		customer_id,
		cast(month(txn_date) as int) as month,
		sum(
			case
				when txn_type = 'deposit' then txn_amount
				else - txn_amount
			end
		) as txn_amount
	from
		customer_transactions
	group by
		customer_id,
		month(txn_date)
),
cte2 as(
	select
		customer_id,
		month,
		txn_amount + coalesce(
			lag(txn_amount) over(
				partition by customer_id
				order by
					month
			),
			0
		) as txn_amount,
		lag(month) over(
			partition by customer_id
			order by
				month
		) as pre_month,
		lead(month) over(
			partition by customer_id
			order by
				month
		) as next_month
	from
		cte
),
txt as(
	select
		customer_id,
		month,
		txn_amount,
		coalesce(pre_month, 0) as pre_month,
		coalesce(next_month, 5) as next_month
	from
		cte2
	union all
	select
		customer_id,
		(month + 1) as month,
		txn_amount,
		pre_month,
		next_month
	from
		txt
	where
		month < next_month -1
),
cte4 as (
	select
		customer_id,
		month,
		txn_amount,
		coalesce(
			lag(txn_amount) over(
				partition by customer_id
				order by
					month
			),
			txn_amount
		) prv_amount
	from
		txt
),
cte5 as (
	select
		*,
		case
			when txn_amount < prv_amount then cast(
				- abs(
					((prv_amount - txn_amount) * 100) / abs(
						coalesce(
							nullif(abs(prv_amount), 0),
							(prv_amount - txn_amount)
						)
					)
				) as decimal(10, 2)
			)
			else cast(
				abs(
					((prv_amount - txn_amount) * 100) / abs(coalesce(nullif(abs(prv_amount), 0), 1))
				) as decimal(10, 2)
			)
		end percentag
	from
		cte4
	where
		month ! = 1
),
cte6 as(
	select
		*
	from
		cte5 a
	where
		3 = (
			select
				count(*)
			from
				cte5
			where
				customer_id = a.customer_id
				and percentag > 5
		)
)
select
	(count(*) * 100) / (
		select
			count(distinct customer_id)
		from
			cte4
	) percentage
from
	cte6;

-- c:
/*
 To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
 
 Option 1: data is allocated based off the amount of money at the end of the previous month
 Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
 Option 3: data is updated real-time
 For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
 
 1. running customer balance column that includes the impact each transaction
 2. customer balance at the end of each month
 3. minimum, average and maximum values of the running balance for each customer
 Using all of the data available - how much data would have been required for each option on a monthly basis?
 */
select
	*
from
	customer_transactions -- 1. running customer balance column that includes the impact each transaction
select
	customer_id,
	txn_date,
	txn_type,
	txn_amount,
	sum(
		case
			when txn_type = 'deposit' then txn_amount
			else - txn_amount
		end
	) over(
		partition by customer_id
		order by
			txn_date
	) as running_balance
from
	customer_transactions -- 2. customer balance at the end of each month
	with cte as(
		select
			customer_id,
			cast(month(txn_date) as int) as month,
			sum(
				case
					when txn_type = 'deposit' then txn_amount
					else - txn_amount
				end
			) as txn_amount
		from
			customer_transactions
		group by
			customer_id,
			month(txn_date)
	),
	cte2 as(
		select
			customer_id,
			month,
			txn_amount + coalesce(
				lag(txn_amount) over(
					partition by customer_id
					order by
						month
				),
				0
			) as txn_amount,
			lag(month) over(
				partition by customer_id
				order by
					month
			) as pre_month,
			lead(month) over(
				partition by customer_id
				order by
					month
			) as next_month
		from
			cte
	),
	txt as(
		select
			customer_id,
			month,
			txn_amount,
			coalesce(pre_month, 0) as pre_month,
			coalesce(next_month, 5) as next_month
		from
			cte2
		union all
		select
			customer_id,
			(month + 1) as month,
			txn_amount,
			pre_month,
			next_month
		from
			txt
		where
			month < next_month -1
	)
select
	customer_id,
	month,
	txn_amount
from
	txt
order by
	customer_id,
	month;

-- 3. minimum, average and maximum values of the running balance for each customer
select
	customer_id,
	txn_date,
	txn_type,
	txn_amount,
	min(
		case
			when txn_type = 'deposit' then txn_amount
			else - txn_amount
		end
	) over(
		partition by customer_id
		order by
			txn_date
	) as min_amount,
	avg(
		case
			when txn_type = 'deposit' then txn_amount
			else - txn_amount
		end
	) over(
		partition by customer_id
		order by
			txn_date
	) as avg_amount,
	max(
		case
			when txn_type = 'deposit' then txn_amount
			else - txn_amount
		end
	) over(
		partition by customer_id
		order by
			txn_date
	) as min_amount
from
	customer_transactions
order by
	customer_id;

-- D.

WITH cte AS (
	SELECT
		customer_id,
		txn_date,
		txn_amount,
		txn_type,
		COALESCE(
			LEAD(txn_date) OVER (
				PARTITION BY customer_id
				ORDER BY
					txn_date
			),
			'04-30-2020'
		) [ next_txn ],
		SUM(
			CASE
				WHEN txn_type = 'deposit' THEN txn_amount
				ELSE - txn_amount
			END
		) OVER (
			PARTITION BY customer_id
			ORDER BY
				txn_date
		) AS [ running_balance ]
	FROM
		customer_transactions
),
cte2 AS (
	SELECT
		*,
		running_balance * (0.06 / 365) * DATEDIFF(DAY, txn_date, next_txn) [ interest ]
	FROM
		cte
)
SELECT
	DATEPART(MONTH, txn_date) [ month ],
	SUM(interest) [ required_data ]
FROM
	cte2
GROUP BY
	DATEPART(MONTH, txn_date)
ORDER BY
	Month;

GO
