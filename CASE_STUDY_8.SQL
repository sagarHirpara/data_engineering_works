SELECT
	*
FROM
	[ dbo ].[ interest_map ]
SELECT
	*
FROM
	[ dbo ].[ interest_metrics ]
SELECT
	*
FROM
	[ dbo ].[ json_data ]
	/*
	 1. Update the fresh_segments.interest_metrics table by modifying the month_year column
	 to be a date data type with the start of the month
	 */
alter table
	[ interest_metrics ]
alter column
	month_year varchar(20)
update
	[ interest_metrics ]
set
	month_year = '01-' + month_year
from
	[ interest_metrics ]
update
	[ interest_metrics ]
set
	month_year = CONVERT(DATE, month_year, 105)
	/*
	 
	 2. What is count of records in the fresh_segments.interest_metrics for each month_year value 
	 sorted in chronological order (earliest to latest) with the null values appearing first?
	 */
select
	month_year,
	count(*) as total
from
	interest_metrics
group by
	month_year
order by
	month_year;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
-- before delete null
SELECT
	COUNT(*)
FROM
	interest_metrics
where
	month_year is null;

-- delete the null values
delete from
	interest_metrics
where
	month_year is null;

-- after delete null
SELECT
	COUNT(*)
FROM
	interest_metrics
where
	month_year is null;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table
-- but not in the fresh_segments.interest_map table? What about the other way around?
with cte as(
	select
		count(interest_id) as not_in_map
	from
		interest_metrics
	where
		interest_id not in (
			select
				id
			from
				interest_map
		)
),
cte2 as (
	select
		count(id) as not_in_metrics
	from
		interest_map
	where
		id not in (
			select
				interest_id
			from
				interest_metrics
		)
)
select
	*
from
	cte,
	cte2;

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
select
	count(*)
from
	interest_map;

select
	count(distinct id)
from
	interest_map;

-- 6. What sort of table join should we perform for our analysis and why?
--Check your logic by checking the rows where interest_id = 21246 in your joined output
-- and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map
--except from the id column.
select
	i.*,
	interest_name,
	interest_summary,
	created_at,
	last_modified
from
	interest_map im
	join interest_metrics i on i.interest_id = im.id
where
	interest_id = 21246;

-- 7. Are there any records in your joined table where the month_year value is before
--the created_at value from the fresh_segments.interest_map table?
--Do you think these values are valid and why?
select
	count(*) n_records
from
	interest_map im
	join interest_metrics i on i.interest_id = im.id
where
	month_year < created_at;

-- Interest Analysis
-- 1. Which interests have been present in all month_year dates in our dataset?
with cte as(
	select
		interest_id,
		count(*) as total
	from
		interest_metrics
	group by
		interest_id
	having
		count(distinct month_year) = (
			select
				count(distinct month_year)
			from
				interest_metrics
		)
)
select
	interest_id
from
	cte;

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
with cte as(
	SELECT
		interest_id,
		count(DISTINCT month_year) AS total_months
	FROM
		interest_metrics
	GROUP BY
		interest_id
),
cumm_per as(
	select
		total_months,
		count(*) no_ids,
		cast(
			100.0 * sum(count(*)) over(
				order by
					total_months desc
			) / sum(count(*)) over() as numeric(10, 2)
		) as cumm_percentage
	from
		cte
	group by
		total_months
)
select
	*
from
	cumm_per
where
	cumm_percentage > 90
order by
	total_months desc;

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
with cte as (
	SELECT
		interest_id,
		count(DISTINCT month_year) AS total_months
	FROM
		interest_metrics
	GROUP BY
		interest_id
	HAVING
		count(DISTINCT month_year) < 6
)
select
	sum(total_months)
from
	cte;

-- 4. Does this decision make sense to remove these data points from a business perspective?
-- Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
-- 5. After removing these interests - how many unique interests are there for each month?
WITH cte_total_months AS (
	SELECT
		interest_id,
		count(DISTINCT month_year) AS total_months
	FROM
		interest_metrics
	GROUP BY
		interest_id
	HAVING
		count(DISTINCT month_year) >= 6
)
SELECT
	month_year,
	count(interest_id) AS n_interests
FROM
	interest_metrics
WHERE
	interest_id IN (
		SELECT
			interest_id
		FROM
			cte_total_months
	)
GROUP BY
	month_year
ORDER BY
	month_year;

--
--  C . Segment Analysis
-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data,
-- which are the top 10 and bottom 10 interests which have the largest composition values in any month_year?
-- Only use the maximum composition value for each interest but you must keep the corresponding month_year
DROP TABLE IF EXISTS # filtered_data;

WITH cte_total_months AS (
	SELECT
		interest_id,
		count(DISTINCT month_year) AS total_months
	FROM
		interest_metrics
	GROUP BY
		interest_id
	HAVING
		count(DISTINCT month_year) >= 6
),
cte2 as(
	SELECT
		*
	FROM
		interest_metrics
	WHERE
		interest_id IN (
			SELECT
				interest_id
			FROM
				cte_total_months
		)
)
select
	* into # filtered_data
from
	cte2;

WITH get_top_ranking AS (
	SELECT
		month_year,
		interest_id,
		ip.interest_name,
		composition,
		rank() OVER (
			ORDER BY
				composition desc
		) AS rnk
	FROM
		# filtered_data
		JOIN interest_map AS ip ON interest_id = ip.id
)
SELECT
	*
FROM
	get_top_ranking
WHERE
	rnk <= 10;

-- get_bottom_ranking
WITH get_bottom_ranking AS (
	SELECT
		month_year,
		interest_id,
		ip.interest_name,
		composition,
		rank() OVER (
			ORDER BY
				composition
		) AS rnk
	FROM
		# filtered_data
		JOIN interest_map AS ip ON interest_id = ip.id
)
SELECT
	*
FROM
	get_bottom_ranking
WHERE
	rnk <= 10;

-- 2. Which 5 interests had the lowest average ranking value?

with cte as (
	select
		interest_id,
		avg(ranking) avgrage,
		rank() over(
			order by
				avg(ranking)
		) rank
	from
		# filtered_data
	group by
		interest_id
)
select
	*
from
	cte
where
	rank <= 5;

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?

with cte as (
	select
		interest_id,
		stdev(percentile_ranking) stddev,
		rank() over(
			order by
				stdev(percentile_ranking) desc
		) rank
	from
		# filtered_data
	group by
		interest_id
)
select
	*
from
	cte
where
	rank <= 5;

-- 4. For the 5 interests found in the previous question
-- what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value?
-- Can you describe what is happening for these 5 interests?

with std_dev as (
	SELECT
		interest_id,
		ip.interest_name,
		round(stdev(percentile_ranking), 2) AS std_dev,
		rank() OVER (
			ORDER BY
				stdev(percentile_ranking) desc
		) AS rnk
	FROM
		# filtered_data
		JOIN interest_map AS ip ON interest_id = ip.id
	GROUP BY
		interest_id,
		ip.interest_name
),
interest as (
	select
		*
	from
		std_dev
	where
		rnk <= 5
),
get_min_max as (
	SELECT
		month_year,
		interest_id,
		percentile_ranking,
		rank() over(
			PARTITION BY interest_id
			ORDER BY
				percentile_ranking
		) AS min_rank,
		rank() over(
			PARTITION BY interest_id
			ORDER BY
				percentile_ranking desc
		) AS max_rank
	FROM
		# filtered_data
	WHERE
		interest_id IN (
			SELECT
				interest_id
			FROM
				interest
		)
)
SELECT
	gmm.month_year,
	ip.interest_name,
	percentile_ranking
FROM
	get_min_max AS gmm
	JOIN interest_map AS ip ON ip.id = gmm.interest_id
WHERE
	min_rank = 1
	OR max_rank = 1
ORDER BY
	interest_id,
	percentile_ranking;

-- 5. How would you describe our customers in this segment based off their composition and ranking values?
-- What sort of products or services should we show to these customers and what should we avoid?
/* ans : Customers in this market category enjoy travelling, some may be business travellers, they seek a luxurious lifestyle, and they participate in sports. 
 Instead of focusing on the budget category or any products or services connected to unrelated hobbies like computer games or astrology, 
 we should highlight those that are relevant to luxury travel or a luxurious lifestyle. Hence, in general, we must concentrate on the interests with high composition values, 
 but we also must monitor this metric to determine when clients become disinterested in a particular subject.*/
-- Index Analysis
/*
 The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
 
 Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.
 
 */
-- 1. What is the top 10 interests by the average composition for each month?

with cte as (
	SELECT
		im.month_year,
		im.interest_id,
		imap.interest_name,
		round((im.composition / im.index_value), 2) AS avg_composition,
		rank() over(
			PARTITION BY month_year
			ORDER BY
				round((im.composition / im.index_value), 2) desc
		) AS rnk
	FROM
		interest_metrics AS im
		JOIN interest_map AS imap ON imap.id = im.interest_id
)
SELECT
	month_year,
	interest_name,
	avg_composition
FROM
	cte
WHERE
	rnk <= 10;

-- 2. For all of these top 10 interests - which interest appears the most often?

with cte as (
	SELECT
		im.month_year,
		im.interest_id,
		imap.interest_name,
		round((im.composition / im.index_value), 2) AS avg_composition,
		rank() over(
			PARTITION BY month_year
			ORDER BY
				round((im.composition / im.index_value), 2) desc
		) AS rnk
	FROM
		interest_metrics AS im
		JOIN interest_map AS imap ON imap.id = im.interest_id
),
cte2 as (
	SELECT
		month_year,
		interest_name,
		avg_composition
	FROM
		cte
	WHERE
		rnk <= 10
),
cte3 as(
	select
		interest_name,
		count(*) count,
		rank() over(
			order by
				count(*) desc
		) rank
	from
		cte2
	group by
		interest_name
)
select
	interest_name
from
	cte3
where
	rank = 1;

-- 3. What is the average of the average composition for the top 10 interests for each month?

with cte as (
	SELECT
		im.month_year,
		im.interest_id,
		imap.interest_name,
		im.composition,
		round((im.composition / im.index_value), 2) AS avg_composition,
		rank() over(
			PARTITION BY month_year
			ORDER BY
				round((im.composition / im.index_value), 2) desc
		) AS rnk
	FROM
		interest_metrics AS im
		JOIN interest_map AS imap ON imap.id = im.interest_id
)
SELECT
	month_year,
	round(avg(avg_composition), 2) as avg_avg_composition
FROM
	cte
WHERE
	rnk <= 10
group by
	month_year;

-- 4. What is the 3 month rolling average of the max average composition value
-- from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.

with cte as (
	SELECT
		im.month_year,
		im.interest_id,
		imap.interest_name,
		round((im.composition / im.index_value), 2) AS avg_composition,
		rank() over(
			PARTITION BY month_year
			ORDER BY
				round((im.composition / im.index_value), 2) desc
		) AS rnk
	FROM
		interest_metrics AS im
		JOIN interest_map AS imap ON imap.id = im.interest_id
),
cte2 as(
	select
		month_year,
		interest_name,
		avg_composition max_index_composition,
		round(
			avg(avg_composition) over(
				order by
					month_year ROWS BETWEEN 2 PRECEDING
					AND CURRENT ROW
			),
			2
		) "3_month_moving_avg",
		CONCAT(
			LAG(interest_name) OVER(
				ORDER BY
					month_year
			),
			' : ',
			LAG(avg_composition) OVER(
				ORDER BY
					month_year
			)
		) "1_month_ago",
		CONCAT(
			LAG(interest_name, 2) OVER(
				ORDER BY
					month_year
			),
			' : ',
			LAG(avg_composition, 2) OVER(
				ORDER BY
					month_year
			)
		) "2_month_ago"
	from
		cte
	where
		rnk = 1
)
select
	*
from
	cte2
where
	month_year > '2018-08-01';

-- 5. Provide a possible reason why the max average composition might change from month to month?
-- Could it signal something is not quite right with the overall business model for Fresh Segments?

/* ANS.I believe that the user's interests have shifted, and that they are now less interested in certain topics, if at all. 
 Users "burned out," and the index composition value fell. Some users may need to be moved to a different segment. 
 Although some interests have a high index composition value, which could indicate that these topics are always of interest to the users. */
