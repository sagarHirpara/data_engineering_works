-- A. Enterprise Relationship Diagram
-- 1. Using the following DDL schema details to create an ERD for all the Clique Bait datasets.
/*
 
 TABLE event_identifier{
 "event_type" INTEGER
 "event_name" VARCHAR(13)
 }
 
 TABLE campaign_identifier {
 "campaign_id" INTEGER
 "products" VARCHAR(3)
 "campaign_name" VARCHAR(33)
 "start_date" TIMESTAMP
 "end_date" TIMESTAMP
 }
 
 TABLE page_hierarchy {
 "page_id" INTEGER
 "page_name" VARCHAR(14)
 "product_category" VARCHAR(9)
 "product_id" INTEGER
 }
 
 TABLE users {
 "user_id" INTEGER
 "cookie_id" VARCHAR(6)
 "start_date" TIMESTAMP
 }
 
 TABLE events {
 "visit_id" VARCHAR(6)
 "cookie_id" VARCHAR(6)
 "page_id" INTEGER
 "event_type" INTEGER
 "sequence_number" INTEGER
 "event_time" TIMESTAMP
 }
 
 Ref: events.page_id > page_hierarchy.page_id // many-to-one
 
 Ref: events.event_type > event_identifier.event_type
 
 Ref: events.cookie_id > users.cookie_id
 
 */
-- B. Digital Analysis
-- 1. How many users are there?
select
	count(distinct user_id) total_users
from
	users;

-- 2. How many cookies does each user have on average?
with cte as (
	select
		user_id,
		count(user_id) as count
	from
		users
	group by
		user_id
)
select
	sum(count) * 1.0 / count(*) as average_cookie
from
	cte;

-- 3. What is the unique number of visits by all users per month?
SELECT
	DATEPART(MONTH, event_time) Month,
	COUNT(DISTINCT visit_id) unq_visits
FROM
	events
GROUP BY
	DATEPART(MONTH, event_time)
ORDER BY
	DATEPART(MONTH, event_time);

GO -- 4. What is the number of events for each event type?
select
	event_name,
	count(*) as event_count
from
	events e
	join event_identifier ei on e.event_type = ei.event_type
group by
	event_name;

-- 5. What is the percentage of visits which have a purchase event?
with cte as (
	select
		count(distinct visit_id) as total_visit
	from
		events
),
cte2 as(
	select
		count(distinct visit_id) as puchase_count
	from
		events e
		join event_identifier ei on e.event_type = ei.event_type
	where
		event_name = 'Purchase'
)
select
	puchase_count * 100.0 / total_visit purchase_percentage
from
	cte2,
	cte 
-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
	with cte as (
		select
			count(distinct visit_id) as total_visit
		from
			events
	),
	cte2 as(
		select
			count(distinct visit_id) as checkout_purchase_count
		from
			events e
			join event_identifier ei on e.event_type = ei.event_type
			join page_hierarchy ph on ph.page_id = e.page_id
		where
			event_name = 'Purchase'
			and page_name = 'Checkout'
	)
select
	checkout_purchase_count * 100.0 / total_visit purchase_percentage
from
	cte2,
	cte 

-- 7. What are the top 3 pages by number of views?

select
	top 3 page_name,
	count(*) as page_visit_count
from
	events e
	join event_identifier ei on e.event_type = ei.event_type
	join page_hierarchy ph on ph.page_id = e.page_id
group by
	page_name
order by
	count(*) desc 
	
-- 8. What is the number of views and cart adds for each product category?
SELECT
	product_category,
	SUM(
		CASE
			WHEN e.event_type = 1 THEN 1
			ELSE 0
		END
	) AS page_views,
	SUM(
		CASE
			WHEN e.event_type = 2 THEN 1
			ELSE 0
		END
	) AS cart_adds
FROM
	events e
	JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE
	ph.product_category IS NOT NULL
GROUP BY
	ph.product_category
ORDER BY
	page_views DESC;

-- 9. What are the top 3 products by purchases?
WITH cte As (
	SELECT
		visit_id,
		cookie_id,
		e.page_id,
		page_name
	FROM
		events e
		JOIN page_hierarchy p ON e.page_id = p.page_id
	WHERE
		event_type = 2
)
SELECT
	page_name,
	COUNT(page_id) abandon_count
FROM
	cte
WHERE
	visit_id IN (
		SELECT
			visit_id
		FROM
			events a
		WHERE
			event_type = 3
	)
GROUP BY
	page_name
ORDER BY
	COUNT(page_id) DESC;

GO 

-- 3. Product Funnel Analysis
/*
 Using a single SQL query - create a new output table which has the following details:
 
 1. How many times was each product viewed?
 2. How many times was each product added to cart?
 3. How many times was each product added to a cart but not purchased (abandoned)?
 4. How many times was each product purchased?
 
 Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
 
 Use your 2 new output tables - answer the following questions: */
drop table if exists # view_temp go
SELECT
	page_name,
	COUNT(e.page_id) view_count INTO # view_temp
FROM
	events e
	JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE
	event_type = 1
GROUP BY
	page_name;

GO drop table if exists # add_temp;

go
SELECT
	page_name,
	COUNT(e.page_id) add_count INTO # add_temp
FROM
	events e
	JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE
	event_type = 2
GROUP BY
	page_name;

GO drop table if exists # np_temp;

go WITH cte As (
	SELECT
		visit_id,
		cookie_id,
		e.page_id,
		page_name
	FROM
		events e
		JOIN page_hierarchy p ON e.page_id = p.page_id
	WHERE
		event_type = 2
)
SELECT
	page_name,
	COUNT(page_id) abandon_count INTO # np_temp
FROM
	cte
WHERE
	visit_id not IN (
		SELECT
			visit_id
		FROM
			events a
		WHERE
			event_type = 3
	)
GROUP BY
	page_name
ORDER BY
	COUNT(page_id) DESC;

GO drop table if exists # p_temp;

go WITH cte As (
	SELECT
		visit_id,
		cookie_id,
		e.page_id,
		page_name
	FROM
		events e
		JOIN page_hierarchy p ON e.page_id = p.page_id
	WHERE
		event_type = 2
)
SELECT
	page_name,
	COUNT(page_id) purchase_count INTO # p_temp
FROM
	cte
WHERE
	visit_id IN (
		SELECT
			visit_id
		FROM
			events a
		WHERE
			event_type = 3
	)
GROUP BY
	page_name
ORDER BY
	COUNT(page_id) DESC;

GO 

-- 1. Which product had the most views, cart adds and purchases?
drop table if exists # product_details;

go
SELECT
	product_id,
	p.page_name AS product_name,
	product_category,
	view_count,
	add_count,
	abandon_count,
	purchase_count INTO # product_details
FROM
	# p_temp p
	JOIN # add_temp a ON a.page_name = p.page_name
	JOIN # np_temp n ON n.page_name = p.page_name
	JOIN # view_temp v ON v.page_name = p.page_name
	JOIN page_hierarchy ph ON ph.page_name = p.page_name
ORDER BY
	product_id;

GO
select
	*
from
	# product_details
select
	product_category,
	sum(view_count) view_count,
	sum(add_count) add_count,
	sum(abandon_count) abandon_count,
	sum(purchase_count) purchase_count
from
	# product_details
group by
	product_category 

-- 1. Which product had the most views, cart adds and purchases?
	WITH cte AS(
		� � �
		SELECT
			� � � � � � � � *,
			rank() over(
				order by
					view_count desc
			) as view_rank,
			rank() over(
				order by
					add_count desc
			) as add_rank,
			rank() over(
				order by
					purchase_count desc
			) as purchase_rank � � �
		FROM
			# product_details
	)
SELECT
	product_name,
	� � � 'most_viewed' AS Product
FROM
	cte
WHERE
	view_rank = 1
UNION
SELECT
	product_name,
	� � � 'most_carted' AS Product
FROM
	cte
WHERE
	add_rank = 1
UNION
SELECT
	product_name,
	� � � 'most_purchased' AS Product
FROM
	cte
WHERE
	purchase_rank = 1 
	
-- 2. Which product was most likely to be abandoned?

select
	top 1 *
from
	# np_temp
order by
	abandon_count desc;

-- 3. Which product had the highest view to purchase percentage?

WITH cte AS(
	SELECT
		product_name,
		CAST(
			ROUND(
				CAST(purchase_count AS NUMERIC(10, 2)) / view_count * 100,
				2
			) AS NUMERIC(10, 2)
		) AS vp_ratio
	FROM
		# product_details
)
SELECT
	TOP 1 product_name,
	vp_ratio
FROM
	cte
ORDER BY
	vp_ratio DESC;

GO 

-- 4. What is the average conversion rate from view to cart add?
WITH cte AS(
	SELECT
		product_name,
		CAST(
			ROUND(CAST(add_count AS NUMERIC(10, 2)) / view_count * 100, 2) AS NUMERIC(10, 2)
		) AS view_add_ratio
	FROM
		# product_details
)
SELECT
	CAST(ROUND(AVG(view_add_ratio), 2) AS NUMERIC(10, 2)) AS avg_conv
FROM
	cte;

GO 

-- 5. What is the average conversion rate from cart add to purchase?
WITH cte AS(
	SELECT
		product_name,
		CAST(
			ROUND(
				CAST(purchase_count AS NUMERIC(10, 2)) / add_count * 100,
				2
			) AS NUMERIC(10, 2)
		) AS add_purchase_ratio
	FROM
		# product_details
)
SELECT
	CAST(ROUND(AVG(add_purchase_ratio), 2) AS NUMERIC(10, 2)) AS avg_conversation
FROM
	cte;

GO 

-- 4. Campaigns Analysis
/*
 
 Generate a table that has 1 single row for every unique visit_id record and has the following columns:
 
 1. user_id
 2. visit_id
 3. visit_start_time: the earliest event_time for each visit
 4. page_views: count of page views for each visit
 5. cart_adds: count of product cart add events for each visit
 6. purchase: 1/0 flag if a purchase event exists for each visit
 7. campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
 8. impression: count of ad impressions for each visit
 click: count of ad clicks for each visit
 (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
 Use the subsequent dat
 
 */
SELECT
	u.user_id,
	e.visit_id,
	MIN(e.event_time) AS visit_start_time,
	SUM(
		CASE
			WHEN e.event_type = 1 THEN 1
			ELSE 0
		END
	) AS page_views,
	SUM(
		CASE
			WHEN e.event_type = 2 THEN 1
			ELSE 0
		END
	) AS cart_adds,
	SUM(
		CASE
			WHEN e.event_type = 3 THEN 1
			ELSE 0
		END
	) AS purchase,
	c.campaign_name,
	SUM(
		CASE
			WHEN e.event_type = 4 THEN 1
			ELSE 0
		END
	) AS impression,
	SUM(
		CASE
			WHEN e.event_type = 5 THEN 1
			ELSE 0
		END
	) AS click
FROM
	users AS u
	INNER JOIN events AS e ON u.cookie_id = e.cookie_id
	left JOIN campaign_identifier AS c ON e.event_time BETWEEN c.start_date
	AND c.end_date
	left JOIN page_hierarchy AS p ON e.page_id = p.page_id
GROUP BY
	u.user_id,
	e.visit_id,
	c.campaign_name
