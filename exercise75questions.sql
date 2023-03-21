-- CREATE DATABASE SYNTAX
CREATE database example;

-- CREATE SCHEMA SYNTAX
CREATE schema sales;

-- create table name test and test1 (with column id,  first_name, last_name, school, percentage, status (pass or fail),pin, created_date, updated_date)
-- define constraints in it such as Primary Key, Foreign Key, Noit Null...
-- part from this take default value for some column such as cretaed_date
CREATE TABLE test1 (
	id serial PRIMARY key,
	first_name VARCHAR(40) notnull,
	last_name VARCHAR(40) notnull,
	school VARCHAR(200) notnull,
	status VARCHAR(4) notnull,
	pin VARCHAR(6) notnull,
	created_date TIMESTAMP DEFAULT now(),
	updated_date TIMESTAMP
);

-- Create film_cast table with film_id,title,first_name and last_name of the actor.. (create table from other table)
SELECT
	film_id,
	title,
	first_name,
	last_name INTO film_cast
FROM
	film
	JOIN film_actor USING(film_id)
	JOIN actor USING(actor_id);

-- drop table test1
DROP TABLE test1 -- what is temproray table ? what is the purpose of temp table ? create one temp table
--temproray table not store permentaly in the database. It is session specific table. when session end the temproray table will deleted automatically.
CREATE temp TABLE student(id serial, name VARCHAR(20));

-- difference between delete and truncate ?
/* delete : it is used  for delete specific row of the table. it takes more space and time to delete rows.
 truncate: it is used for delete all the row of the table it takes less time compare to delete. */
--rename test table to student table
ALTER TABLE
	test rename TO student_table;

-- add column in test table named city
ALTER TABLE
	test
ADD
	COLUMN city VARCHAR(20);

-- change data type of one of the column of test table
ALTER TABLE
	test
ALTER COLUMN
	city type VARCHAR(200);

-- drop column pin from test table
ALTER TABLE
	test DROP COLUMN pin;

-- rename column city to location in test table
ALTER TABLE
	test rename COLUMN city TO location;

-- Create a Role with read only rights on the database.
CREATE role john2;

GRANT
SELECT
	ON ALL tables IN schema public TO john2;

-- Create a role with all the write permission on the database.
GRANT INSERT,
UPDATE
,
	DELETE ON ALL tables IN schema public TO john2;

-- Create a database user who can read as well as write data into database.
GRANT ALL privileges ON ALL tables IN schema public TO john2;

-- Create an admin role who is not superuser but can create database and  manage roles.
CREATE role admin2 WITH createdb CREATEROLE;

-- Create user whoes login credentials can last until 1st June 2023
CREATE USER dev WITH login password 'dev' valid until '2023-6-1';

-- List all unique film’s name.
SELECT
	DISTINCT title
FROM
	film;

-- List top 100 customers details.
SELECT
	*
FROM
	customer
FETCH FIRST
	100 ROWS ONLY;

-- List top 10 inventory details starting from the 5th one.
SELECT
	*
FROM
	inventory
LIMIT
	10 offset 4;

-- find the customer's name who paid an amount between 1.99 and 5.99.
SELECT
	first_name,
	last_name,
	amount
FROM
	payment
	JOIN customer USING(customer_id)
WHERE
	amount BETWEEN 1.99 AND 5.99;

--  List film's name which is staring from the A.
SELECT
	*
FROM
	film
WHERE
	title LIKE 'A%';

-- List film's name which is end with "a"
SELECT
	*
FROM
	film
WHERE
	title LIKE '%a';

-- List film's name which is start with "M" and ends with "a"
SELECT
	*
FROM
	film
WHERE
	title LIKE 'M%a' --List all customer details which payment amount is greater than 40. (USING EXISTs)
SELECT
	customer_id,
	first_name,
	last_name
FROM
	customer c
WHERE
	EXISTS (
		SELECT
			*
		FROM
			payment
		WHERE
			customer_id = c.customer_id
			AND amount > 40
	);

-- List Staff details order by first_name.
SELECT
	*
FROM
	staff
ORDER BY
	first_name;

-- List customer's payment details (customer_id,payment_id,first_name,last_name,payment_date)
SELECT
	c.customer_id,
	p.payment_id,
	c.first_name,
	c.last_name,
	p.payment_date
FROM
	payment p
	JOIN customer c USING(customer_id);

-- Display title and it's actor name.
SELECT
	title,
	first_name,
	last_name
FROM
	film_actor
	JOIN film USING(film_id)
	JOIN actor USING(actor_id);

-- List all actor name and find corresponding film id
SELECT
	first_name,
	last_name,
	film_id
FROM
	film_actor
	JOIN actor USING(actor_id);

-- List all addresses and find corresponding customer's name and phone.
SELECT
	first_name,
	last_name,
	phone,
	address
FROM
	customer
	JOIN address USING(address_id);

-- Find Customer's payment (include null values if not matched from both tables)(customer_id,payment_id,first_name,last_name,payment_date)
SELECT
	p.customer_id,
	first_name,
	last_name,
	payment_date
FROM
	payment p
	FULL OUTER JOIN customer c USING(customer_id)
WHERE
	c.customer_id isnull
	AND p.customer_id;

-- List customer's address_id. (Not include duplicate id )
SELECT
	DISTINCT address_id
FROM
	customer;

-- List customer's address_id. (Include duplicate id )
SELECT
	address_id
FROM
	customer;

-- List Individual Customers' Payment total.
SELECT
	customer_id,
	first_name,
	last_name,
	SUM(amount) AS amount
FROM
	payment
	JOIN customer USING(customer_id)
GROUP BY
	customer_id
ORDER BY
	first_name;

-- List Customer whose payment is greater than 80.
SELECT
	customer_id,
	first_name,
	last_name
FROM
	payment
	JOIN customer USING(customer_id)
WHERE
	amount > 80;

-- Shop owners decided to give  5 extra days to keep  their dvds to all the rentees who rent the movie before June 15th 2005 make according changes in db
UPDATE
	rental
SET
	return_date = return_date + INTERVAL '5 days'
WHERE
	rental_date < DATE('2005-06-15') -- Remove the records of all the inactive customers from the Database
ALTER TABLE
	payment DROP CONSTRAINT payment_customer_id_fkey;

ALTER TABLE
	payment
ADD
	CONSTRAINT payment_customer_id_fkey FOREIGN key(customer_id) REFERENCES customer (customer_id);

DELETE FROM
	customer
WHERE
	active = 0;

SELECT
	constraint_name
FROM
	information_schema.table_constraints
WHERE
	table_name = 'payment';

-- count the number of special_features category wise.... total no.of deleted scenes, Trailers etc....
WITH cte AS (
	SELECT
		category.name,
		special_features
	FROM
		film_category
		JOIN film USING(film_id)
		JOIN category USING(category_id)
),
cte2 AS (
	SELECT
		name,
		UNNEST(special_features) AS special_features
	FROM
		cte
	GROUP BY
		name,
		special_features
),
cte3 AS (
	SELECT
		name,
		special_features,
		COUNT(*) AS count2
	FROM
		cte2
	GROUP BY
		name,
		special_features
	ORDER BY
		name
),
cte4 AS (
	SELECT
		name,
		CASE
			WHEN special_features = 'Deleted Scenes' THEN count2
			ELSE 0
		END AS Deleted_Scenes,
		CASE
			WHEN special_features = 'Trailers' THEN count2
			ELSE 0
		END AS Trailers,
		CASE
			WHEN special_features = 'Behind the Scenes' THEN count2
			ELSE 0
		END AS Behind_the_Scenes,
		CASE
			WHEN special_features = 'Commentaries' THEN count2
			ELSE 0end AS Commentaries
			FROM
				cte3
		)
	SELECT
		name,
		SUM(Deleted_Scenes) AS Deleted_Scenes,
		SUM(Trailers) AS Trailers,
		SUM(Behind_the_Scenes) AS Behind_the_Scenes,
		SUM(Commentaries) AS Commentaries
	FROM
		cte4
	GROUP BY
		name;

-- count the numbers of records in film table
SELECT
	COUNT(*) AS no_of_records
FROM
	film;

-- 41 count the no.of special fetures which have Trailers alone, Trailers and Deleted Scened both etc....
WITH cte AS (
	SELECT
		category.name,
		special_features
	FROM
		film_category
		JOIN film USING(film_id)
		JOIN category USING(category_id)
)
SELECT
	special_features,
	UNNEST(special_features)
FROM
	cte
GROUP BY
	special_features;

select * from film;
-- use CASE expression with the SUM function to calculate the number of films in each rating:
SELECT
	rating,
	COUNT(*) AS COUNT
FROM
	film
GROUP BY
	rating;

SELECT
	SUM(
		CASE
			WHEN rating = 'R' THEN 1
			ELSE 0
		END
	) AS R,
	SUM(
		CASE
			WHEN rating = 'NC-17' THEN 1
			ELSE 0
		END
	) AS NC_17,
	SUM(
		CASE
			WHEN rating = 'G' THEN 1
			ELSE 0
		END
	) AS G,
	SUM(
		CASE
			WHEN rating = 'PG' THEN 1
			ELSE 0
		END
	) AS PG,
	SUM(
		CASE
			WHEN rating = 'PG-13' THEN 1
			ELSE 0
		END
	) AS PG_13
FROM
	film;

-- Display the discount on each product, if there is no discount on product Return 0
SELECT
	product,
	COALESCE(discount, 0) AS discount
FROM
	items;

-- Return title and it's excerpt, if excerpt is empty or null display last 6 letters of respective body from posts table
SELECT
	title,
	CASE
		WHEN excerpt isnull
		OR excerpt = '' THEN RIGHT(body, 6)
		ELSE excerpt
	END
FROM
	posts;

SELECT
	COALESCE(NULLIF(excerpt, ''), RIGHT(body, 6))
FROM
	posts;

-- Can we know how many distinct users have rented each genre? if yes, name a category with highest and lowest rented number  ..
SELECT
	name,
	COUNT(DISTINCT customer.customer_id)
FROM
	rental
	JOIN customer USING(customer_id)
	JOIN payment USING(rental_id)
	JOIN inventory USING(inventory_id)
	JOIN film USING(film_id)
	JOIN film_category USING(film_id)
	JOIN category USING(category_id)
GROUP BY
	name
ORDER BY
	COUNT desc;

-- "Return film_id,title,rental_date and rental_duration
-- according to rental_rate need to define rental_duration
-- such as
-- rental rate  = 0.99 --> rental_duration = 3
-- rental rate  = 2.99 --> rental_duration = 4
-- rental rate  = 4.99 --> rental_duration = 5
-- otherwise  6"
SELECT
	film_id,
	title,
	rental_date,
	CASE
		WHEN rental_rate = 0.99 THEN 3
		WHEN rental_rate = 2.99 THEN 4
		WHEN rental_rate = 4.99 THEN 5
		ELSE 6
	END AS rental_duration
FROM
	rental
	JOIN inventory USING(inventory_id)
	JOIN film USING(film_id)
ORDER BY
	rental_duration -- Find customers and their email that have rented movies at priced $9.99.
SELECT
	first_name,
	last_name,
	email
FROM
	rental
	JOIN customer USING(customer_id)
	JOIN payment USING(rental_id)
WHERE
	amount = 9.99;

-- Find customers in store #1 that spent less than $2.99 on individual rentals, but have spent a total higher than $5.
SELECT
	first_name,
	last_name,
	SUM(amount)
FROM
	customer
	JOIN payment USING(customer_id)
WHERE
	customer.store_id = 1
	AND amount < 2.99
GROUP BY
	customer_id
HAVING
	SUM(amount) > 5;

-- Select the titles of the movies that have the highest replacement cost.
SELECT
	title
FROM
	film
WHERE
	replacement_cost = (
		SELECT
			MAX(replacement_cost)
		FROM
			film
	);

-- list the cutomer who have rented maximum time movie and also display the count of that... (we can add limit here too---> list top 5 customer who rented maximum time)
select * from (
	with cte as (select payment.customer_id,count(rental_id) as count
    from rental join payment using(rental_id) group by payment.customer_id order by count(rental_id) desc
			 )
select *,dense_rank() over(order by count desc) from cte)tt where dense_rank <= 5;

-- Display the max salary for each department
SELECT
	dept_name,
	MAX(salary) AS max_salary
FROM
	employee
GROUP BY
	dept_name;

--"Display all the details of employee and add one extra column name max_salary (which shows max_salary dept wise)
/*
 emp_id	 emp_name   dept_name	salary   max_salary
 120	     ""Monica""	""Admin""		5000	 5000
 101		 ""Mohan""	""Admin""		4000	 5000
 116		 ""Satya""	""Finance""	6500	 6500
 118		 ""Tejaswi""	""Finance""	5500	 6500
 
 --> like this way if emp is from admin dept then , max salary of admin dept is 5000, then in the max salary column 5000 will be shown for dept admin
 */
WITH cte AS (
	SELECT
		dept_name,
		MAX(salary) AS max_salary
	FROM
		employee
	GROUP BY
		dept_name
)
SELECT
	employee.*,
	max_salary
FROM
	employee,
	cte
WHERE
	cte.dept_name = employee.dept_name
ORDER BY
	employee.dept_name;

SELECT
	*,
	MAX(salary) OVER(
		PARTITION BY dept_name
		ORDER BY
			dept_name
	)
FROM
	employee
ORDER BY
	dept_name;

/*" Assign a number TO the ALL the employee department wise such AS if admin dept have 8 emp THEN NO.goes
 FROM
 1 TO 8,
 THEN if finance have 3 THEN it goes TO 1 TO 3 emp_id emp_name dept_name salary no_of_emp_dept_wsie 120 "" Monica "" "" Admin "" 5000 1 101 "" Mohan "" "" Admin "" 4000 2 113 "" Gautham "" "" Admin "" 2000 3 108 "" Maryam "" "" Admin "" 4000 4 113 "" Gautham "" "" Admin "" 2000 5 120 "" Monica "" "" Admin "" 5000 6 101 "" Mohan "" "" Admin "" 4000 7 108 "" Maryam "" "" Admin "" 4000 8 116 "" Satya "" "" Finance "" 6500 1 118 "" Tejaswi "" "" Finance "" 5500 2 104 "" Dorvin "" "" Finance "" 6500 3 106 "" Rajesh "" "" Finance "" 5000 4 104 "" Dorvin "" "" Finance "" 6500 5 118 "" Tejaswi "" "" Finance "" 5500 6 " */
SELECT
	*,
	ROW_NUMBER() OVER(
		PARTITION BY dept_name
		ORDER BY
			dept_name
	)
FROM
	employee;

-- Fetch the first 2 employees from each department to join the company. (assume that emp_id assign in the order of joining)
SELECT
	*
FROM
	(
		SELECT
			*,
			ROW_NUMBER() OVER(
				PARTITION BY dept_name
				ORDER BY
					emp_id
			)
		FROM
			employee
	) AS tt
WHERE
	ROW_NUMBER <= 2;

-- Fetch the top 3 employees in each department earning the max salary.
SELECT
	*
FROM
	(
		SELECT
			*,
			DENSE_RANK() OVER(
				PARTITION BY dept_name
				ORDER BY
					salary desc
			)
		FROM
			employee
	) tt
WHERE
	DENSE_RANK <= 3;

-- write a query to display if the salary of an employee is higher, lower or equal to the previous employee.
SELECT
	*
FROM
	(
		SELECT
			*,
			lag(salary) OVER(PARTITION BY dept_name) AS lag
		FROM
			employee
	) tt
WHERE
	lag IS NOT NULL;

-- Get all title names those are released on may DATE
SELECT
	*
FROM
	film;

-- get all Payments Related Details from Previous week
SELECT
	*
FROM
	payment
WHERE
	payment_date > NOW()::DATE-EXTRACT(DOW FROM NOW())::INTEGER-7;	

select  NOW()::DATE-EXTRACT(DOW FROM NOW())::INTEGER-7
-- Get all customer related Information from Previous Year
SELECT
	*
FROM
	customer
WHERE
	EXTRACT(
		YEAR
		FROM
			create_date
	) >= (
		SELECT
		
				EXTRACT(
					YEAR
					FROM
						now()::date
				)- 1
		FROM
			customer
	);

-- What is the number of rentals per month for each store?
SELECT
	store_id,
	EXTRACT(
		MONTH
		FROM
			rental_date
	) as month,
	EXTRACT(
		YEAR
		FROM
			rental_date
	) as year,
	COUNT(*)
FROM
	rental
	JOIN inventory USING(inventory_id)
	JOIN store USING(store_id)
GROUP BY
	store_id,
	EXTRACT(
		MONTH
		FROM
			rental_date
	),
	EXTRACT(
		YEAR
		FROM
			rental_date
	);

-- Replace Title 'Date speed' to 'Data speed' whose Language 'English'
UPDATE
	film
SET
	title = 'Data Speed'
FROM
	LANGUAGE
WHERE
	film.language_id = LANGUAGE.language_id
	AND LANGUAGE.name = 'English'
	AND film.title = 'Date speed';

-- Remove Starting Character " A " from Description Of film
UPDATE
	film
SET
	description = SUBSTRING(description, 3) --  if end Of string is 'Italian'then Remove word from Description of Title
UPDATE
	film
SET
	description = CASE
		WHEN RIGHT(description, 7) = 'Factory' THEN LEFT(description, length(description) - 7)
		ELSE description
	END;

-- Who are the top 5 customers with email details per total sales
SELECT
	*
FROM
	(
		WITH cte AS (
			SELECT
				customer_id,
				first_name,
				last_name,
				SUM(amount) AS total_sales
			FROM
				payment
				JOIN customer USING(customer_id)
			GROUP BY
				customer_id
		)
		SELECT
			*,
			DENSE_RANK() OVER(
				ORDER BY
					total_sales desc
			)
		FROM
			cte
	) tt
WHERE
	DENSE_RANK <= 5;

-- Display the movie titles of those movies offered in both stores at the same time.
SELECT
	DISTINCT i1.film_id,
	title
FROM
	inventory i1
	JOIN inventory i2 USING(film_id)
	JOIN film USING(film_id)
WHERE
	(
		i1.store_id = 1
		AND i2.store_id = 2
	)
	AND i1.last_update = i2.last_update;

-- Display the movies offered for rent in store_id 1 and not offered in store_id 2.
SELECT
	film_id,
	i1.store_id,
	i2.store_id
FROM
	inventory i1
	JOIN inventory i2 USING(film_id)
SELECT
	DISTINCT film_id
FROM
	inventory
WHERE
	store_id = 1
EXCEPT
SELECT
	DISTINCT film_id
FROM
	inventory
WHERE
	store_id = 2 -- Show the number of movies each actor acted in
SELECT
	actor_id,
	first_name,
	last_name,
	COUNT(*)
FROM
	film_actor
	JOIN actor USING(actor_id)
GROUP BY
	actor_id;

-- Find all customers with at least three payments whose amount is greater than 9 dollars
SELECT
	customer_id,
	first_name,
	last_name
FROM
	payment
	JOIN customer USING(customer_id)
WHERE
	amount > 9
GROUP BY
	customer_id
HAVING
(COUNT(*) >= 3);

-- find out the lastest payment date of each customer
SELECT
	customer_id,
	MAX(payment_date) AS latest_payment_date
FROM
	payment
GROUP BY
	customer_id
ORDER BY
	customer_id;

-- Create a trigger that will delete a customer’s reservation record once the customer’s rents the DVD


create or replace trigger retal_insert before insert on rental FOR EACH ROW execute procedure trigger_function();


create or replace function trigger_function()
returns trigger
language plpgsql
as 
$$
declare 
	res record;
begin
	
-- 	select * into res from reservation where reservation.inventory_id = new.inventory_id and customer_id = new.customer_id;
	
-- 	raise notice '%,%',new.inventory_id,new.customer_id;

	delete from reservation where customer_id = new.customer_id and inventory_id = new.inventory_id;
	return new;
end $$;

insert into rental(rental_date,inventory_id,customer_id,return_date,staff_id) values
(now(),14,3,now(),1);

-- Create a trigger that will help me keep track of all operations performed on the reservation table. I want to record whether an insert, delete or update occurred on the reservation table and store that log in reservation_audit table.
CREATE OR REPLACE FUNCTION insert_reservation()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS
$$
	BEGIN
		INSERT INTO reservation_audit
		VALUES('I', CURRENT_TIMESTAMP, NEW.customer_id, NEW.inventory_id, NEW.reserve_date);
	RETURN NULL;
	END;
$$;

CREATE OR REPLACE FUNCTION delete_reservation()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS
$$
	BEGIN
		INSERT INTO reservation_audit
		VALUES('D', CURRENT_TIMESTAMP, OLD.customer_id, OLD.inventory_id, OLD.reserve_date);
	RETURN NULL;
	END;
$$;

CREATE OR REPLACE FUNCTION update_reservation()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS
$$
	BEGIN
		INSERT INTO reservation_audit
		VALUES('U', CURRENT_TIMESTAMP, OLD.customer_id, OLD.inventory_id, OLD.reserve_date);
	RETURN NULL;
	END;
$$;

CREATE OR REPLACE TRIGGER trigger_insert_reservation
AFTER INSERT
ON reservation
FOR EACH ROW
EXECUTE PROCEDURE insert_reservation();

CREATE OR REPLACE TRIGGER trigger_delete_reservation
BEFORE DELETE
ON reservation
FOR EACH ROW
EXECUTE PROCEDURE delete_reservation();

CREATE OR REPLACE TRIGGER trigger_update_reservation
BEFORE UPDATE
ON reservation
FOR EACH ROW
EXECUTE PROCEDURE update_reservation();

SELECT * FROM reservation;
SELECT * FROM reservation_audit;
INSERT INTO reservation
VALUES(5, 55, '2025-5-25');

UPDATE reservation
SET inventory_id = 65 WHERE customer_id = 5;

DELETE FROM reservation WHERE inventory_id = 55;

-- Create trigger to prevent a customer for reserving more than 3 DVD’s.

create trigger max_dvd
before insert
on reservation
for each row
execute procedure dvd_max();

create or replace function dvd_max()
returns trigger
language plpgsql
as
$$
begin
	
	if (select count(*) from reservation where reservation.customer_id = new.customer_id) = 3 then
		raise exception 'customer have alreday equal or more than 3 dvd';
	end if;
	
	return new;

end$$;

-- create a function which takes year as a argument and return the concatenated result of title which contain 'ful' in it and release year like this (title:release_year) --> use cursor in function

create or replace function fetch_detail(f_year int)
returns text
language plpgsql
as
$$
declare
	titles text default '';
	res record;
	film_cur cursor for select * from film where release_year = f_year;
begin
	
	open film_cur;
	
	loop
	
	fetch film_cur into res;
	exit when not found;
	if res.title like '%Dat%' then
		titles := titles || ',' || res.title || ':' || res.release_year;
	end if;
	
	end loop;
	close film_cur;
	return titles;
end $$;


select fetch_detail(2006);

select * from film where ;
-- Find top 10 shortest movies using for loop

do
$$
declare
	x record;
begin

	for x in select * from 
				(select 
				 	*,
				 dense_rank() over(order by length) 
				 from film)tt 
				 where dense_rank <= 10 
			loop
		raise notice '%  ,  %',x.title,x.length;
	end loop;
end $$;

-- Write a function using for loop to derive value of 6th field in fibonacci series (fibonacci starts like this --> 1,1,.....)

create or replace function fibonacci(n int)
returns int
language plpgsql 
as
$$
declare 

	i int = 1;
	j int = 1;
	x int;
	
begin

	for x in 3..n loop
	
		select j,j+i into i,j;
	end loop;
	
	return j;

end $$;

select fibonacci(6);