/*
 In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
 
 1. Convert the week_date to a DATE format
 
 2. Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
 
 3. Add a month_number with the calendar month for each week_date value as the 3rd column
 
 4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
 
 5. Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
 
 
 */
drop table if exists week_sales;

WITH cte1 AS(
  SELECT
    region,
    platform,
    segment,
    customer_type,
    transactions,
    sales,
    CONVERT(DATE, week_date, 3) AS week_date
  FROM
    weekly_sales
)
SELECT
  week_date,
  DATEPART(WEEk, week_date) AS week_number,
  DATEPART(MONTH, week_date) AS month_number,
  DATEPART(YEAR, week_date) AS calendar_year,
  region,
  platform,
  CASE
    WHEN segment IN ('F1', 'C1') THEN 'Young Adults'
    WHEN segment IN ('F2', 'C2') THEN 'Middle Aged'
    WHEN segment IN ('C3', 'F3', 'C4') THEN 'Retirees'
    ELSE 'unknown'
  END AS age_band,
  CASE
    WHEN segment LIKE 'C%' THEN 'Couples'
    WHEN segment LIKE 'F%' THEN 'Families'
    ELSE 'unknown'
  END AS demographic,
  customer_type,
  transactions,
  CAST(sales AS BIGINT) sales,
  CAST((sales * 1.0) / transactions AS DECIMAL(10, 2)) AS avg_transaction INTO week_sales
FROM
  cte1;

-- 2. Data Exploration
-- 1. What day of the week is used for each week_date value?
select
  week_date,
  day
from
  week_sales;

--2. What range of week numbers are missing from the dataset?
select
  *
from
  generate_series(1, 53)
where
  value not in(
    select
      distinct week
    from
      week_sales
  );

--3. How many total transactions were there for each year in the dataset?
select
  year,
  sum(transactions) as total_transaction
from
  week_sales
group by
  year;

--4. What is the total sales for each region for each month?
select
  region,
  month,
  sum(cast(sales as bigint)) total_sales
from
  week_sales
group by
  region,
  month;

--5. What is the total count of transactions for each platform
select
  platform,
  sum(transactions)
from
  week_sales
group by
  platform;

--6. What is the percentage of sales for Retail vs Shopify for each month?
select
  month,
  cast(
    (
      sum(
        case
          when platform = 'Retail' then cast(sales as bigint)
          else 0
        end
      ) * 100.0
    ) / sum(cast(sales as bigint)) as decimal(4, 2)
  ) as retail_percentage,
  cast(
    (
      sum(
        case
          when platform = 'Shopify' then cast(sales as bigint)
          else 0
        end
      ) * 100.0
    ) / sum(cast(sales as bigint)) as decimal(4, 2)
  ) as shopify_percentage
from
  week_sales
group by
  month;

--7. What is the percentage of sales by demographic for each year in the dataset?
select
  year,
  cast(
    (
      sum(
        case
          when demographic = 'Couples' then cast(sales as bigint)
          else 0
        end
      ) * 100.0
    ) / sum(cast(sales as bigint)) as decimal(4, 2)
  ) as couple_percentage,
  cast(
    (
      sum(
        case
          when demographic = 'Families' then cast(sales as bigint)
          else 0
        end
      ) * 100.0
    ) / sum(cast(sales as bigint)) as decimal(4, 2)
  ) as Families_percentage,
  cast(
    (
      sum(
        case
          when demographic = 'unknown' then cast(sales as bigint)
          else 0
        end
      ) * 100.0
    ) / sum(cast(sales as bigint)) as decimal(4, 2)
  ) as unkown_percentage
from
  week_sales
group by
  year;

--8. Which age_band and demographic values contribute the most to Retail sales?
select
  age_band,
  demographic,
  sum(cast(sales as bigint)) as contribution
from
  week_sales
group by
  age_band,
  demographic
order by
  sum(cast(sales as bigint)) desc;

--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify?
--If not - how would you calculate it instead?
select
  year,
  platform,
  cast(avg(avg_transaction) as decimal(38, 2)) as avg_transaciton_size_using_avg,
  cast(
    sum(cast(sales as bigint)) * 1.0 / sum(transactions) as decimal(10, 2)
  ) as sales_and_transaction
from
  week_sales
group by
  year,
  platform;

-- C:
/*
 
 This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
 
 Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
 
 We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
 
 Using this analysis approach - answer the following questions:
 
 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
 2. What about the entire 12 weeks before and after?
 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
 */
-- 1. What is the total sales for the 4 weeks before and after 2020-06-15?
--What is the growth or reduction rate in actual values and percentage of sales?
SELECT
  week_date,
  week,
  SUM(sales) AS total_sales
FROM
  week_sales
WHERE
  (
    week BETWEEN 21 AND 28
  )
  AND (year = 2020)
GROUP BY
  week_date,
  week -- What is the growth or reduction rate in actual values and percentage of sales?
  WITH changes AS (
    SELECT
      week_date,
      week,
      SUM(sales) AS total_sales
    FROM
      week_sales
    WHERE
      (
        week BETWEEN 21 AND 28
      )
      AND (year = 2020)
    GROUP BY
      week_date,
      week
  ),
  changes_2 AS (
    SELECT
      SUM(
        CASE
          WHEN week BETWEEN 21 AND 24 THEN cast(total_sales as bigint)
        END
      ) AS before_change,
      SUM(
        CASE
          WHEN week BETWEEN 25 AND 28 THEN cast(total_sales as bigint)
        END
      ) AS after_change
    FROM
      changes
  )
SELECT
  before_change,
  after_change,
  after_change - before_change AS variance,
  cast(
    100.0 * (after_change - before_change) / before_change as decimal(5, 2)
  ) AS percentage
FROM
  changes_2 --2.  What about the entire 12 weeks before and after?
  WITH changes AS (
    SELECT
      week_date,
      week,
      SUM(sales) AS total_sales
    FROM
      week_sales
    WHERE
      (
        week BETWEEN 13 AND 37
      )
      AND (year = 2020)
    GROUP BY
      week_date,
      week
  ),
  changes_2 AS (
    SELECT
      SUM(
        CASE
          WHEN week BETWEEN 13 AND 24 THEN cast(total_sales as bigint)
        END
      ) AS before_change,
      SUM(
        CASE
          WHEN week BETWEEN 25 AND 37 THEN cast(total_sales as bigint)
        END
      ) AS after_change
    FROM
      changes
  )
SELECT
  before_change,
  after_change,
  after_change - before_change AS variance,
  cast(
    100.0 * (after_change - before_change) / before_change as decimal(5, 2)
  ) AS percentage
FROM
  changes_2 --  3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
  -- 4 week before and after
  WITH changes AS (
    SELECT
      week_date,
      week,
      year,
      SUM(sales) AS total_sales
    FROM
      week_sales
    WHERE
      (
        week BETWEEN 21 AND 28
      )
    GROUP BY
      week_date,
      week,
      year
  ),
  changes_2 AS (
    SELECT
      year,
      SUM(
        CASE
          WHEN week BETWEEN 21 AND 24 THEN cast(total_sales as bigint)
        END
      ) AS before_change,
      SUM(
        CASE
          WHEN week BETWEEN 25 AND 28 THEN cast(total_sales as bigint)
        END
      ) AS after_change
    FROM
      changes
    group by
      year
  )
SELECT
  year,
  before_change,
  after_change,
  after_change - before_change AS variance,
  cast(
    100.0 * (after_change - before_change) / before_change as decimal(5, 2)
  ) AS percentage
FROM
  changes_2 -- 12 week before and after
  WITH changes AS (
    SELECT
      week_date,
      week,
      year,
      SUM(sales) AS total_sales
    FROM
      week_sales
    WHERE
      (
        week BETWEEN 13 AND 37
      )
    GROUP BY
      week_date,
      week,
      year
  ),
  changes_2 AS (
    SELECT
      year,
      SUM(
        CASE
          WHEN week BETWEEN 13 AND 24 THEN cast(total_sales as bigint)
        END
      ) AS before_change,
      SUM(
        CASE
          WHEN week BETWEEN 25 AND 37 THEN cast(total_sales as bigint)
        END
      ) AS after_change
    FROM
      changes
    group by
      year
  )
SELECT
  year,
  before_change,
  after_change,
  after_change - before_change AS variance,
  cast(
    100.0 * (after_change - before_change) / before_change as decimal(5, 2)
  ) AS percentage
FROM
  changes_2 --D Bonus Question
  --Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
  --region
  --platform
  --age_band
  --demographic
  --customer_type
  --Do you have any further recommendations for Danny?s team at Data Mart or any interesting insights based off this analysis?
  --Part 1 region
  DECLARE @ week_date DATE = '2020-06-15';

WITH cte1 AS(
  SELECT
    region,
    SUM(
      CASE
        WHEN week_date BETWEEN DATEADD(WEEK, -12, @ week_date)
        AND DATEADD(WEEK, -1, @ week_date) THEN sales
      END
    ) AS before_change,
    SUM(
      CASE
        WHEN week_date BETWEEN @ week_date
        AND DATEADD(WEEK, 11, @ week_date) THEN sales
      END
    ) AS after_change
  FROM
    week_sales
  GROUP BY
    region
)
SELECT
  region,
  before_change,
  after_change,
  after_change - before_change AS variance,
  CAST(
    100.0 * (after_change - before_change) / before_change AS DECIMAL(4, 2)
  ) AS percentage
FROM
  cte1;

--Part 2 platform
use [ 8weeksql ] DECLARE @ week_date DATE = '2020-06-15';

WITH cte1 AS(
  SELECT
    platform,
    SUM(
      CASE
        WHEN week_date BETWEEN DATEADD(WEEK, -12, @ week_date)
        AND DATEADD(WEEK, -1, @ week_date) THEN sales
      END
    ) AS before_change,
    SUM(
      CASE
        WHEN week_date BETWEEN @ week_date
        AND DATEADD(WEEK, 11, @ week_date) THEN sales
      END
    ) AS after_change
  FROM
    week_sales
  GROUP BY
    platform
)
SELECT
  platform,
  before_change,
  after_change,
  after_change - before_change AS variance,
  CAST(
    100.0 * (after_change - before_change) / before_change AS DECIMAL(4, 2)
  ) AS percentage
FROM
  cte1;

--Part 3 age_band
DECLARE @ week_date DATE = '2020-06-15';

WITH cte1 AS(
  SELECT
    age_band,
    SUM(
      CASE
        WHEN week_date BETWEEN DATEADD(WEEK, -12, @ week_date)
        AND DATEADD(WEEK, -1, @ week_date) THEN sales
      END
    ) AS before_change,
    SUM(
      CASE
        WHEN week_date BETWEEN @ week_date
        AND DATEADD(WEEK, 11, @ week_date) THEN sales
      END
    ) AS after_change
  FROM
    week_sales
  GROUP BY
    age_band
)
SELECT
  age_band,
  before_change,
  after_change,
  after_change - before_change AS variance,
  CAST(
    100.0 * (after_change - before_change) / before_change AS DECIMAL(4, 2)
  ) AS percentage
FROM
  cte1;

--Part 4 demographic
DECLARE @ week_date DATE = '2020-06-15';

WITH cte1 AS(
  SELECT
    demographic,
    SUM(
      CASE
        WHEN week_date BETWEEN DATEADD(WEEK, -12, @ week_date)
        AND DATEADD(WEEK, -1, @ week_date) THEN sales
      END
    ) AS before_change,
    SUM(
      CASE
        WHEN week_date BETWEEN @ week_date
        AND DATEADD(WEEK, 11, @ week_date) THEN sales
      END
    ) AS after_change
  FROM
    week_sales
  GROUP BY
    demographic
)
SELECT
  demographic,
  before_change,
  after_change,
  after_change - before_change AS variance,
  CAST(
    100.0 * (after_change - before_change) / before_change AS DECIMAL(4, 2)
  ) AS percentage
FROM
  cte1;

--Part 5 customer_type
DECLARE @ week_date DATE = '2020-06-15';

WITH cte1 AS(
  SELECT
    customer_type,
    SUM(
      CASE
        WHEN week_date BETWEEN DATEADD(WEEK, -12, @ week_date)
        AND DATEADD(WEEK, -1, @ week_date) THEN sales
      END
    ) AS before_change,
    SUM(
      CASE
        WHEN week_date BETWEEN @ week_date
        AND DATEADD(WEEK, 11, @ week_date) THEN sales
      END
    ) AS after_change
  FROM
    week_sales
  GROUP BY
    customer_type
)
SELECT
  customer_type,
  before_change,
  after_change,
  after_change - before_change AS variance,
  CAST(
    100.0 * (after_change - before_change) / before_change AS DECIMAL(4, 2)
  ) AS percentage
FROM
  cte1;
