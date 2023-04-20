select
	*
from
	[ dbo ].[ customer_orders ];

select
	*
from
	[ dbo ].[ pizza_names ];

select
	*
from
	[ dbo ].[ pizza_recipes ];

select
	*
from
	[ dbo ].[ pizza_toppings ];

select
	*
from
	[ dbo ].[ runner_orders ];

select
	*
from
	[ dbo ].[ runners ];

-- pizza metrics
-- 1. How many pizzas were ordered?
select
	count(*)
from
	customer_orders;

-- 2. How many unique customer orders were made?
select
	count(distinct customer_id)
from
	customer_orders;

-- 3. How many successful orders were delivered by each runner?
select
	runner_id,
	count(runner_id) as sucessful_order
from
	runner_orders
where
	cancellation is null
	or cancellation = ''
	or cancellation = 'null'
group by
	runner_id;

-- 4. How many of each type of pizza was delivered?
select
	pizza_id,
	count(pizza_id)
from
	customer_orders c
	join runner_orders r on r.order_id = c.order_id
where
	cancellation is null
	or cancellation = ''
	or cancellation = 'null'
group by
	pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select
	customer_id,
	sum(
		case
			when convert(varchar, pizza_name) = 'Meatlovers' then 1
			else 0
		end
	) as meatlover,
	sum(
		case
			when convert(varchar, pizza_name) = 'Vegetarian' then 1
			else 0
		end
	) as vagetarian
from
	customer_orders c
	join pizza_names p on p.pizza_id = c.pizza_id
group by
	customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
select
	top 1 r.order_id,
	count(*) as count_of_order
from
	customer_orders c
	join runner_orders r on r.order_id = c.order_id
where
	cancellation is null
	or cancellation = ''
	or cancellation = 'null'
group by
	r.order_id
order by
	count(*) desc;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select
	customer_id,
	sum(
		case
			when (
				exclusions is null
				or exclusions = ''
				or exclusions = 'null'
			)
			and (
				extras is null
				or extras = ''
				or extras = 'null'
			) then 1
			else 0
		end
	) as no_chnge,
	sum(
		case
			when (
				exclusions is not null
				and exclusions <> ''
				and exclusions <> 'null'
			)
			and (
				extras is not null
				or extras <> ''
				and extras <> 'null'
			) then 1
			else 0
		end
	) as with_changes
from
	customer_orders c
	join runner_orders r on r.order_id = c.order_id
where
	cancellation is null
	or cancellation = ''
	or cancellation = 'null'
group by
	customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
select
	sum(
		case
			when (
				exclusions is not null
				and exclusions <> ''
				and exclusions <> 'null'
			)
			and (
				extras is not null
				or extras <> ''
				and extras <> 'null'
			) then 1
			else 0
		end
	) as with_excusion_and_extras
from
	customer_orders c
	join runner_orders r on r.order_id = c.order_id
where
	cancellation is null
	or cancellation = ''
	or cancellation = 'null';

-- 9. What was the total volume of pizzas ordered for each hour of the day?
select
	DATEPART(day, order_time) as day,
	DATEPART(HOUR, order_time) as hour,
	count(*) as pizza_order
from
	customer_orders
group by
	DATEPART(day, order_time),
	DATEPART(HOUR, order_time);

-- 10 What was the volume of orders for each day of the week?
-- B. Runner and Customer Experience
-- B1. How many runners signed up for each 1 week period?
SELECT
	runner_id,
	datepart(WEEK, registration_date) as week,
	registration_date
FROM
	runners 
	
	
	
-- B2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select
	runner_id,
	avg(
		DATEDIFF(MINUTE, order_time, convert(datetime2, pickup_time))
	)
from
	runner_orders r
	join customer_orders c on c.order_id = r.order_id
where
	pickup_time <> 'null'
group by
	runner_id;

-- B3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
select
	r.order_id,
	DATEDIFF(MINUTE, order_time, convert(datetime2, pickup_time))
from
	runner_orders r
	join customer_orders c on c.order_id = r.order_id
where
	pickup_time <> 'null'

-- time fro preparing pizza increase acording to number of pizzas are more, approx 10 minutes for make 1 pizza
-- B4. What was the average distance travelled for each customer?

select
	customer_id,
	round(
		avg(
			case
				when isnumeric(distance) = 1 then cast(distance as float)
				else cast(
					trim(substring(distance, 1, len(distance) - 2)) as float
				)
			end
		),
		2
	) as distance
from
	runner_orders r
	join customer_orders c on c.order_id = r.order_id
where
	pickup_time <> 'null'
group by
	customer_id;

-- b5. What was the difference between the longest and shortest delivery times for all orders?
select
	max(
		case
			when isnumeric(duration) = 1 then cast(duration as float) + DATEDIFF(MINUTE, order_time, convert(datetime2, pickup_time))
			else cast(trim(substring(duration, 1, 2)) as float) + DATEDIFF(MINUTE, order_time, convert(datetime2, pickup_time))
		end
	) - min(
		case
			when isnumeric(duration) = 1 then cast(duration as float) + DATEDIFF(MINUTE, order_time, convert(datetime2, pickup_time))
			else cast(trim(substring(duration, 1, 2)) as float) + DATEDIFF(MINUTE, order_time, convert(datetime2, pickup_time))
		end
	) Total_time
from
	runner_orders r
	join customer_orders c on c.order_id = r.order_id
where
	pickup_time <> 'null' 
	
-- B6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
select
	distinct r.order_id,
	r.runner_id,
	round(
		(
			(
				case
					when isnumeric(distance) = 1 then cast(distance as float)
					else cast(
						trim(substring(distance, 1, len(distance) - 2)) as float
					)
				end
			) * 1000
		) / (
			(
				case
					when isnumeric(duration) = 1 then cast(duration as float)
					else cast(trim(substring(duration, 1, 2)) as float)
				end
			) * 60
		),
		2
	) as 'avg_spedd(m/s)'
from
	runner_orders r
	join customer_orders c on c.order_id = r.order_id
where
	pickup_time <> 'null';

-- B7. What is the successful delivery percentag

select
	r.runner_id,
	round(
		(
			sum(
				case
					when cancellation is null
					or cancellation = ''
					or cancellation = 'null' then 1
					else 0
				end
			) * 100.0
		) / count(*),
		2
	) as Sucessfull_percentage
from
	runner_orders r
	join customer_orders c on c.order_id = r.order_id
group by
	runner_id;

----- C: Ingredient Optimisation
-- c1. What are the standard ingredients for each pizza?
select
	pizza_id,
	cast(value as int) as topping_id,
	topping_name
from
	pizza_recipes cross apply string_split(cast(toppings as varchar), ',') as pr
	join pizza_toppings pt on pr.value = pt.topping_id;

-- c2. what was the most comanlly added extra
select
	max(value) as most_comman_extras
from
	customer_orders cross apply string_split(cast(extras as varchar), ',')
where
	value <> 'null'
	and value <> 'null'
	and value <> '';

-- c3.  What was the most common exclusion?
select
	max(value) as most_comman_extras
from
	customer_orders cross apply string_split(cast(exclusions as varchar), ',')
where
	value <> 'null'
	and value <> 'null'
	and value <> '';

/* c4. Generate an order item for each record in the customers_orders table in the format of one of the following:
 Meat Lovers
 Meat Lovers - Exclude Beef
 Meat Lovers - Extra Bacon
 Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */
with extra as (
	select
		order_id,
		pizza_id,
		extras,
		string_agg(cast(topping_name as varchar), ',') as added_extra
	from
		customer_orders cross apply string_split(cast(extras as varchar), ',') as E
		join pizza_toppings p on p.topping_id = E.value
	where
		value <> 'null'
		and value <> ''
	group by
		order_id,
		pizza_id,
		extras
),
exclusion as (
	select
		order_id,
		pizza_id,
		exclusions,
		string_agg(cast(topping_name as varchar(100)), ',') as added_exclusion
	from
		customer_orders cross apply string_split(cast(exclusions as varchar), ',') as E
		join pizza_toppings p on p.topping_id = E.value
	where
		value <> 'null'
		and value <> ''
	group by
		order_id,
		pizza_id,
		exclusions
)
select
	co.order_id,
	co.pizza_id,
	concat(
		case
			when cast(pizza_name as varchar(100)) = 'Meatlovers' then 'Meat Lover'
			else pizza_name
		end,
		coalesce(' - extra ' + added_exclusion, ''),
		coalesce(' - exclude ' + added_extra, '')
	) as order_details
from
	customer_orders co
	left join extra e on co.order_id = e.order_id
	and co.pizza_id = e.pizza_id
	and co.extras = e.extras
	left join exclusion ex on co.order_id = ex.order_id
	and co.pizza_id = ex.pizza_id
	and co.exclusions = ex.exclusions
	join pizza_names pn on co.pizza_id = pn.pizza_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
with extra as (
	select
		order_id,
		pizza_id,
		extras,
		p.topping_id,
		topping_name
	from
		customer_orders cross apply string_split(cast(extras as varchar(max)), ',') as E
		join pizza_toppings p on p.topping_id = E.value
	where
		value <> 'null'
		and value <> ''
),
exclusion as (
	select
		order_id,
		pizza_id,
		exclusions,
		p.topping_id,
		topping_name as added_exclusion
	from
		customer_orders cross apply string_split(cast(exclusions as varchar(max)), ',') as E
		join pizza_toppings p on p.topping_id = E.value
	where
		value <> 'null'
		and value <> ''
),
orders as (
	select
		order_id,
		co.pizza_id,
		value as topping_id,
		topping_name
	from
		customer_orders co
		join pizza_recipes pr on co.pizza_id = pr.pizza_id cross apply string_split(cast(toppings as varchar(max)), ',')
		join pizza_toppings pt on pt.topping_id = value
),
order_with_extras_exculed_exclusion as (
	select
		o.order_id,
		o.pizza_id,
		o.topping_id,
		topping_name
	from
		orders o
		left join exclusion ex on o.order_id = ex.order_id
		and o.pizza_id = ex.pizza_id
		and o.topping_id = ex.topping_id
	where
		ex.topping_id is null
	union all
	select
		order_id,
		pizza_id,
		topping_id,
		topping_name
	from
		extra
),
item_details as (
	select
		order_id,
		cast(pizza_name as nvarchar(max)) as pizza_name,
		cast(topping_name as nvarchar(max)) as topping_name,
		count(topping_id) as topping_count --,count(topping_id)
	from
		order_with_extras_exculed_exclusion owe
		join pizza_names pn on pn.pizza_id = owe.pizza_id
	group by
		order_id,
		cast(topping_name as nvarchar(max)),
		cast(pizza_name as nvarchar(max))
),
summary as (
	select
		order_id,
		pizza_name,
		string_agg(
			case
				when topping_count > 1 then cast(topping_count as varchar(max)) + 'x' + topping_name
				else topping_name
			end,
			','
		) as items_details
	from
		item_details
	group by
		order_id,
		pizza_name
)
select
	order_id,
	pizza_name + ': ' + items_details as ingrident_details
from
	summary;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with extra as (
	select
		order_id,
		pizza_id,
		extras,
		p.topping_id,
		topping_name
	from
		customer_orders cross apply string_split(cast(extras as varchar(max)), ',') as E
		join pizza_toppings p on p.topping_id = E.value
	where
		value <> 'null'
		and value <> ''
),
exclusion as (
	select
		order_id,
		pizza_id,
		exclusions,
		p.topping_id,
		topping_name as added_exclusion
	from
		customer_orders cross apply string_split(cast(exclusions as varchar(max)), ',') as E
		join pizza_toppings p on p.topping_id = E.value
	where
		value <> 'null'
		and value <> ''
),
orders as (
	select
		order_id,
		co.pizza_id,
		value as topping_id,
		topping_name
	from
		customer_orders co
		join pizza_recipes pr on co.pizza_id = pr.pizza_id cross apply string_split(cast(toppings as varchar(max)), ',')
		join pizza_toppings pt on pt.topping_id = value
),
order_with_extras_exculed_exclusion as (
	select
		o.order_id,
		o.pizza_id,
		o.topping_id,
		topping_name
	from
		orders o
		left join exclusion ex on o.order_id = ex.order_id
		and o.pizza_id = ex.pizza_id
		and o.topping_id = ex.topping_id
	where
		ex.topping_id is null
	union all
	select
		order_id,
		pizza_id,
		topping_id,
		topping_name
	from
		extra
)
select
	cast(topping_name as nvarchar(max)) as topping_name,
	count(*) as total_count
from
	order_with_extras_exculed_exclusion owe
	join runner_orders ro on ro.order_id = owe.order_id
where
	cancellation is null
	or cancellation = ''
	or cancellation = 'null'
group by
	cast(topping_name as nvarchar(max))
order by
	count(*) desc;

-- D. Pricing and Ratings
-- D1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes -
-- how much money has Pizza Runner made so far if there are no delivery fees?
use [ 8weeksql ]
SELECT
	SUM(
		CASE
			WHEN cast(pizza_name as varchar) = 'Meatlovers' THEN 12
			ELSE 10
		END
	) AS totalMoney
FROM
	customer_orders c
	JOIN pizza_names p on p.pizza_id = c.pizza_id
	JOIN runner_orders r on c.order_id = r.order_id
WHERE
	cancellation is null
	or cancellation = ''
	or cancellation = 'null' -- D2. What if there was an additional $1 charge for any pizza extras?
	-- Add cheese is $1 extra
SELECT
	SUM(
		CASE
			WHEN extras LIKE '%4%' THEN 1
			WHEN LEN(extras) >= 1
			AND extras <> '4' THEN 1
			ELSE 0
		END
	) + SUM(
		CASE
			WHEN cast(pizza_name as varchar) = 'Meatlovers' THEN 12
			ELSE 10
		END
	) AS totalMoney
FROM
	customer_orders c
	JOIN pizza_names p on p.pizza_id = c.pizza_id
	JOIN runner_orders r on r.order_id = c.order_id
WHERE
	cancellation is null
	or cancellation = ''
	or cancellation = 'null' -- D3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
	-- how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data
	-- for ratings for each successful customer order between 1 to 5.
	CREATE SCHEMA ratings;

ALTER TABLE
	runner_orders
ADD
	CONSTRAINT unique_order_id UNIQUE(order_id);

CREATE TABLE ratings.runner_rating(
	rating_id int identity(1, 1) PRIMARY KEY,
	order_id INT,
	rate INT CHECK(
		rate >= 1
		AND rate <= 5
	),
	FOREIGN KEY(order_id) REFERENCES runner_orders(order_id)
);

INSERT INTO
	ratings.runner_rating(order_id, rate)
VALUES
	(1, 4),
	(2, 3),
	(3, 1),
	(4, 5);

SELECT
	*
FROM
	ratings.runner_rating;

-- D4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas


SELECT
	customer_id,
	ro.order_id,
	ro.runner_id,
	rr.rate,
	order_time,
	pickup_time,
	datepart(MINUTE, pickup_time - order_time) AS timeBetweenOrderAndPickup,
	duration,
	ROUND(
		(
			(
				case
					when isnumeric(distance) = 1 then cast(distance as float)
					else cast(
						trim(substring(distance, 1, len(distance) - 2)) as float
					)
				end
			) / (
				case
					when isnumeric(duration) = 1 then cast(duration as float)
					else cast(trim(substring(duration, 1, 2)) as float)
				end / 60
			)
		),
		2
	) AS speedInKMPH,
	COUNT(*) OVER(PARTITION BY runner_id) AS TotalPizaaByRunnerID
FROM
	runner_orders AS ro
	LEFT JOIN ratings.runner_rating AS rr ON ro.order_id = rr.order_id
	JOIN customer_orders AS co ON ro.order_id = co.order_id
WHERE
	cancellation is null
	or cancellation = ''
	or cancellation = 'null';

-- D5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled
-- how much money does Pizza Runner have left over after these deliveries?

WITH cte1 AS(
	SELECT
		ro.order_id,
		AVG(runner_id) AS runner_id,
		SUM(
			CASE
				WHEN cast(pizza_name as varchar) = 'Meatlovers' THEN 12.0
				ELSE 10.0
			END
		) - ROUND(
			AVG(
				case
					when isnumeric(distance) = 1 then cast(distance as float)
					else cast(
						trim(substring(distance, 1, len(distance) - 2)) as float
					)
				end
			) * 0.30,
			2
		) AS left_over_money
	FROM
		runner_orders AS ro
		JOIN customer_orders AS co ON ro.order_id = co.order_id
		JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id
	GROUP BY
		ro.order_id
)
SELECT
	sum(left_over_money)
FROM
	cte1 


-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design?
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?


INSERT INTO
	pizza_names ("pizza_id", "pizza_name")
VALUES
	(3, 'Supreme');

INSERT INTO
	pizza_recipes ("pizza_id", "toppings")
VALUES
	(3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
