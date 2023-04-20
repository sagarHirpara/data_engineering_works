-- select * from [dbo].[product_details];
-- select * from [dbo].[product_hierarchy];
-- select * from [dbo].[product_prices];
-- select * from [dbo].[sales];
-- A. High Level Sales Analysis
-- 1. What was the total quantity sold for all products?
select
	prod_id,
	sum(qty) total_quantity
from
	sales
group by
	prod_id;

-- 2. What is the total generated revenue for all products before discounts?
select
	prod_id,
	sum(qty * price) total_revenue
from
	sales
group by
	prod_id;

-- 3. What was the total discount amount for all products?
select
	prod_id,
	sum(discount) total_discount
from
	sales
group by
	prod_id;

-- Transaction Analysis
-- 1. How many unique transactions were there?
select
	count(distinct txn_id) unique_transaction
from
	[ dbo ].[ sales ];

-- 2. What is the average unique products purchased in each transaction?
SELECT
	COUNT(prod_id) / COUNT(distinct txn_id) AS avg_number_of_product_in_order
FROM
	sales -- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
	with cte as(
		select
			txn_id,
			sum(
				cast((qty * price) * (100 - discount) / 100 as numeric(10, 2))
			) as revenue
		from
			sales
		group by
			txn_id
	)
select
	top 1 PERCENTILE_CONT(0.25) within group(
		order by
			revenue
	) over() as "25th",
	PERCENTILE_CONT(0.5) within group(
		order by
			revenue
	) over() as median,
	PERCENTILE_CONT(0.75) within group(
		order by
			revenue
	) over() as "75th"
from
	cte;

-- 4. What is the average discount value per transaction?
with cte as(
	select
		sum(cast((qty * price) * discount / 100 as numeric(10, 2))) discount
	from
		sales
	group by
		txn_id
)
select
	avg(discount)
from
	cte;

-- 5. What is the percentage split of all transactions for members vs non-members?
with cte as (
	select
		txn_id,
		member
	from
		sales
	group by
		txn_id,
		member
)
select
	cast(
		sum(
			case
				when member = 't' then 1
				else 0
			end
		) * 100.0 / count(*) as numeric(10, 2)
	) as member_per,
	cast(
		sum(
			case
				when member = 'f' then 1
				else 0
			end
		) * 100.0 / count(*) as numeric(10, 2)
	) as non_member_per
from
	cte;

-- 6. What is the average revenue for member transactions and non-member transactions?
with cte as (
	select
		txn_id,
		member,
		sum(
			cast((qty * price) * (100 - discount) / 100 as numeric(10, 2))
		) as revenue
	from
		sales
	group by
		txn_id,
		member
)
SELECT
	CASE
		WHEN member = 't' THEN 'Member'
		ELSE 'Non-Member'
	END AS membership_status,
	round(avg(revenue), 2) AS avg_revenue
from
	cte
GROUP BY
	Member;

-- Product Analysis
-- 1. What are the top 3 products by total revenue before discount?
select
	top 3 prod_id,
	sum(qty * price) as revenue
from
	sales
group by
	prod_id
order by
	sum(qty * price) desc;

-- 2. What is the total quantity, revenue and discount for each segment?
with cte as (
	select
		txn_id,
		prod_id,
		qty,
		pd.price,
		discount,
		segment_id,
		segment_name
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
)
select
	distinct segment_id,
	sum(qty) over(partition by segment_id) quantity,
	sum(qty * price) over(partition by segment_id) revenue,
	sum((qty * price) * discount / 100) over(partition by segment_id) discount
from
	cte;

-- 3. What is the top selling product for each segment?
with cte as (
	select
		segment_id,
		product_name,
		sum(qty) as quntity
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	group by
		segment_id,
		product_name
),
cte2 as(
	select
		*,
		rank() over(
			partition by segment_id
			order by
				quntity desc
		) rank
	from
		cte
)
select
	segment_id,
	product_name
from
	cte2
where
	rank = 1;

-- 4. What is the total quantity, revenue and discount for each category?
with cte as (
	select
		txn_id,
		prod_id,
		qty,
		pd.price,
		discount,
		category_id
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
)
select
	distinct category_id,
	sum(qty) over(partition by category_id) quantity,
	sum(qty * price) over(partition by category_id) revenue,
	sum((qty * price) * discount / 100) over(partition by category_id) discount
from
	cte;

-- 5. What is the top selling product for each category?
with cte as (
	select
		category_id,
		product_name,
		sum(qty) as quntity
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	group by
		category_id,
		product_name
),
cte2 as(
	select
		*,
		rank() over(
			partition by category_id
			order by
				quntity desc
		) rank
	from
		cte
)
select
	category_id,
	product_name
from
	cte2
where
	rank = 1;

-- 6. What is the percentage split of revenue by product for each segment?
with cte as (
	select
		segment_name,
		product_name,
		cast((qty * pd.price) * (100 - discount) / 100 as numeric(10, 2)) revenue
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
)
select
	segment_name,
	product_name,
	sum(revenue) * 100 / (
		select
			sum(revenue)
		from
			cte
		where
			segment_name = c.segment_name
	) percentage
from
	cte c
group by
	segment_name,
	product_name;

-- 7. What is the percentage split of revenue by segment for each category?
with cte as (
	select
		category_name,
		segment_name,
		cast((qty * pd.price) * (100 - discount) / 100 as numeric(10, 2)) revenue
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
)
select
	category_name,
	segment_name,
	sum(revenue) * 100 / (
		select
			sum(revenue)
		from
			cte
		where
			category_name = c.category_name
	) percentage
from
	cte c
group by
	category_name,
	segment_name;

-- 8. What is the percentage split of total revenue by category?
with cte as (
	select
		category_name,
		cast((qty * pd.price) * (100 - discount) / 100 as numeric(10, 2)) revenue
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
)
select
	category_name,
	sum(revenue) * 100 / (
		select
			sum(revenue)
		from
			cte
	) percentage
from
	cte c
group by
	category_name;

-- 9. What is the total transaction �penetration� for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
select
	product_name,
	n_sold,
	cast(n_sold * 100.00 / total_transactions as numeric(10, 2)) penetration
from
	(
		SELECT
			pd.product_name,
			count(DISTINCT txn_id) AS n_sold,
			(
				SELECT
					count(DISTINCT txn_id)
				FROM
					sales
			) AS total_transactions
		FROM
			sales s
			JOIN product_details pd ON pd.product_id = s.prod_id
		GROUP BY
			pd.product_name
	) as tmp;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
with cte as (
	select
		txn_id,
		product_name
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
)
select
	top 1 a.product_name,
	b.product_name,
	c.product_name,
	count(*) as count
from
	cte a
	join cte b on a.txn_id = b.txn_id
	and a.product_name < b.product_name
	join cte c on b.txn_id = c.txn_id
	and b.product_name < c.product_name
group by
	a.product_name,
	b.product_name,
	c.product_name
order by
	count(*) desc -- reporting questions
	create procedure month_data @ month int as begin -- 1.
select
	top 3 prod_id,
	sum(qty * price) as revenue
from
	sales
where
	datepart(month, start_txn_time) = @ month
group by
	prod_id
order by
	sum(qty * price) desc;

select
	*,
	datepart(month, start_txn_time)
from
	sales;

-- 2.
with cte as (
	select
		txn_id,
		prod_id,
		qty,
		pd.price,
		discount,
		segment_id,
		segment_name
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	where
		datepart(month, start_txn_time) = @ month
)
select
	distinct segment_id,
	sum(qty) over(partition by segment_id) quantity,
	sum(qty * price) over(partition by segment_id) revenue,
	sum((qty * price) * discount / 100) over(partition by segment_id) discount
from
	cte;

-- 3.
with cte as (
	select
		segment_id,
		product_name,
		sum(qty) as quntity
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	where
		datepart(month, start_txn_time) = @ month
	group by
		segment_id,
		product_name
),
cte2 as(
	select
		*,
		rank() over(
			partition by segment_id
			order by
				quntity desc
		) rank
	from
		cte
)
select
	segment_id,
	product_name
from
	cte2
where
	rank = 1;

-- 4.
with cte as (
	select
		txn_id,
		prod_id,
		qty,
		pd.price,
		discount,
		category_id
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	where
		datepart(month, start_txn_time) = @ month
)
select
	distinct category_id,
	sum(qty) over(partition by category_id) quantity,
	sum(qty * price) over(partition by category_id) revenue,
	sum((qty * price) * discount / 100) over(partition by category_id) discount
from
	cte;

-- 5.
with cte as (
	select
		category_id,
		product_name,
		sum(qty) as quntity
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	where
		datepart(month, start_txn_time) = @ month
	group by
		category_id,
		product_name
),
cte2 as(
	select
		*,
		rank() over(
			partition by category_id
			order by
				quntity desc
		) rank
	from
		cte
)
select
	category_id,
	product_name
from
	cte2
where
	rank = 1;

--6.
with cte as (
	select
		segment_name,
		product_name,
		cast((qty * pd.price) * (100 - discount) / 100 as numeric(10, 2)) revenue
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	where
		datepart(month, start_txn_time) = @ month
)
select
	segment_name,
	product_name,
	sum(revenue) * 100 / (
		select
			sum(revenue)
		from
			cte
		where
			segment_name = c.segment_name
	) percentage
from
	cte c
group by
	segment_name,
	product_name;

-- 7.
with cte as (
	select
		category_name,
		segment_name,
		cast((qty * pd.price) * (100 - discount) / 100 as numeric(10, 2)) revenue
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	where
		datepart(month, start_txn_time) = @ month
)
select
	category_name,
	segment_name,
	sum(revenue) * 100 / (
		select
			sum(revenue)
		from
			cte
		where
			category_name = c.category_name
	) percentage
from
	cte c
group by
	category_name,
	segment_name;

-- 8.
with cte as (
	select
		category_name,
		cast((qty * pd.price) * (100 - discount) / 100 as numeric(10, 2)) revenue
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	where
		datepart(month, start_txn_time) = @ month
)
select
	category_name,
	sum(revenue) * 100 / (
		select
			sum(revenue)
		from
			cte
	) percentage
from
	cte c
group by
	category_name;

-- 9.
select
	product_name,
	n_sold,
	cast(n_sold * 100.00 / total_transactions as numeric(10, 2)) penetration
from
	(
		SELECT
			pd.product_name,
			count(DISTINCT txn_id) AS n_sold,
			(
				SELECT
					count(DISTINCT txn_id)
				FROM
					sales
			) AS total_transactions
		FROM
			sales s
			JOIN product_details pd ON pd.product_id = s.prod_id
		where
			datepart(month, start_txn_time) = @ month
		GROUP BY
			pd.product_name
	) as tmp;

-- 10.
with cte as (
	select
		txn_id,
		product_name
	from
		sales s
		join product_details pd on pd.product_id = s.prod_id
	where
		datepart(month, start_txn_time) = @ month
)
select
	top 1 a.product_name,
	b.product_name,
	c.product_name,
	count(*) as count
from
	cte a
	join cte b on a.txn_id = b.txn_id
	and a.product_name < b.product_name
	join cte c on b.txn_id = c.txn_id
	and b.product_name < c.product_name
group by
	a.product_name,
	b.product_name,
	c.product_name
order by
	count(*) desc
end;

exec month_data @ month = 2;

-- bonus questions
/*
 Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
 
 Hint: you may want to consider using a recursive CTE to solve this problem!
 */
select
	pp.product_id,
	pp.price as price,
	ph.level_text + ' ' + case
		when ph.parent_id = 3 then 'jeans'
		when ph.parent_id = 4 then 'jacket'
		when ph.parent_id = 5 then 'Shirt'
		when ph.parent_id = 6 then 'Socks'
	end + ' -' + case
		when ph.parent_id = 1
		or ph.parent_id = 3
		or ph.parent_id = 4 then ' Womens'
		else ' Mens'
	end as product_name,
	case
		when ph.parent_id = 5
		or ph.parent_id = 6 then 2
		else 1
	end as category_id,
	ph.parent_id as segment_id,
	ph.id as style_id,
	case
		when ph.parent_id = 5
		or ph.parent_id = 6 then 'Mens'
		else 'Womens'
	end as category_name,
	case
		when ph.parent_id = 3 then 'Jeans'
		when ph.parent_id = 4 then 'Jacket'
		when ph.parent_id = 5 then 'Shirt'
		when ph.parent_id = 6 then 'Socks'
	end as segment_name,
	level_text as style_name
from
	[ dbo ].[ product_prices ] pp
	join product_hierarchy ph on ph.id = pp.id
