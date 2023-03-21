-- -----------------------> Querying data <--------------

select * from sample_database;
select first_name,last_name from sample_database;

select * from sample_database order by salary asc;
select first_name,last_name,salary from sample_database order by salary desc, first_name;

select distinct country from sample_database;

select count(*) as number_of_records from sample_database;


-- ------------------> Filtering Data <-------------


select * from sample_database where salary between 55000 and 60000;
select 2!=1;
select * from sample_database limit 5;
select * from sample_database offset 4 limit 5;
select * from sample_database offset 2 fetch first 3 row only;
select * from sample_database offset 2 fetch first 10 row only;
select * from sample_database where country in ('Australia','Bangladesh','Indonesia') order by country;
select * from sample_database where dob between '2002-01-22' and '2022-02-23';
select * from sample_database where email like '%gizmodo.com';
select * from sample_database where country like 'P%';
select * from sample_database where country ilike 'p%'; -- ignore the case sensitivity

select 'I''m also a s"tring constant';
select E'I\'m also a ''string constant';


-- ------------------> Joining multiple tables <-------------

-- innerjoin
select * from department d join sudent s on s.department::int = d.did; 
-- left join 
select * from department d left join sudent s on s.department::int = d.did; 
-- right join
select * from sudent s right join department d on s.department::int = d.did; 
-- cross join 
select * from department d cross join sudent; -- output will be m*n  m and n is number of rows in both able 
-- self join 
select e.first_name || ' ' || e.last_name as employee_name,
	   m.first_name || ' ' || m.last_name as manager_name from employee e join employee m on e.manager_id = m.employee_id;
-- full outer join

select * from sudent s full outer join department d on s.department::int = d.did;


-- ------------------> Grouping data <---------------

select country, count(*) as cnt from sample_database group by country;
select country, count(*) as cnt from sample_database group by country having count(*)>5;

-- --------------> Aggrigate functions <--------------

select max(price) from car;
select min(price) from car;
select round(avg(price)) from car;
select make,model,avg(price) from car group by make,model;

select 10+2*20;

select *,(price * 0.85) as discounted_price, (price-(price * .15)) as pri from car;

create table audi as select * from car where make = 'Audi';

-- -----------------> set operation <------------------

select * from car where make = 'Audi'
union
select * from car where make = 'Dodge';


select * from car where make = 'Audi'    -- duplicate records also considered
union all
select * from car;

select * from car where make = 'Audi'	 -- duplicate records discarded only first appear will remain
union 
select * from car;

select * from car where make in ('Nissan','GMC','Subaru')
intersect
select * from car where make = 'GMC';

select * from car where make in ('Nissan','GMC','Subaru')
except 
select * from car where make = 'GMC';


-- --------------------> Subquery <-----------------------------------

select * from car where price > (select avg(price) from car) order by price;
select * from car where price > all(select price from car where make ='Honda'); -- output 53 reocrds
select * from car where price > any(select price from car where make ='Honda'); -- output 976 records affected

select first_name,last_name from customer c where exists(select 1 from Practice.payment p where p.customer_id = c.customer_id amount > 11);
select first_name,last_name from customer c where not exists(select 1 from payment p where p.customer_id = c.customer_id and amount>11);
 
-- --------------------> Modifying data <------------------------------
-- insert
INSERT INTO employee (
	employee_id,
	first_name,
	last_name,
	manager_id
)
VALUES
	(1, 'Windy', 'Hays', NULL);
	
-- update

update employee set first_name = 'sagar bro' where employee_id = 2;

-- update join 

update sudent set name = name || 'GG' from department d where sudent.department::int = d.did and d.dep_name = 'computer';

update product p set net_price = price - price * d.discount from product_segment d where p.segment_id = d.id;

update product p set net_price = 30000 from product_segment d where p.segment_id = d.id and d.discount*1000 > 60;
 
-- delete

delete from person where id = 2;

-- delete join

delete from product using product_segment where product.segment_id = product_segment.id and product_segment.discount> 0.06;

-- upsert

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
	customer_id serial PRIMARY KEY,
	name VARCHAR UNIQUE,
	email VARCHAR NOT NULL
);

INSERT INTO 
    customers (name, email)
VALUES 
    ('IBM', 'contact@ibm.com'),
    ('Microsoft', 'contact@microsoft.com'),
    ('Intel', 'contact@intel.com');

select * from customers;

insert into customers(name,email)
values ('Microsoft','abc@gmail.com')
on conflict (name) do nothing;

insert into customers(name,email)
values ('Microsoft','abcd@gmail.com')
on conflict (name) 
do
update set email = excluded.email || ';' || customers.email;

-- -------------------------> Common table expression CTE <------------------

with ctc_1 as (
	select 
		name,dep_name
	from
		sudent join department
	on  sudent.department::int = department.did 
)

select * from ctc_1 where dep_name = 'plastic';

-- recursive cte

with recursive ctc_2 as(
		select 
				name,dep_name
		from 
			sudent join department
		on sudent.department::int = department.did where dep_name = 'plastic'
	
		union
	 
		select name,dep_name
		from ctc_2 where name = 'rohit'
)
select * from ctc_2;

-- ----------------->    Transaction   <-----------------

begin;
	insert into department (did,dep_name) values(13,'BB');
	select * from department;
commit;


begin;
	insert into department (did,dep_name) values(16,'BB');
rollback;

begin
	insert into department (did,dep_name) values(110,'BB');
	savepoint e1;
	
	insert into department (did,dep_name) values(18,'BB');
	savepoint e2;
	
	insert into department (did,dep_name) values(19,'BB');
	savepoint e3;
	
	insert into department (did,dep_name) values(20,'BB');
	savepoint e4;
	
	rollback to savepoint e2;
	release savepoint e3;
	select * from department;
	
commit;

-- ------------------ import from csv file <--------

create table department (id int,dep_name varchar(30)); 

copy department(did,dep_name) 
from '/home/sagar/Pictures/test.csv'
delimiter ','
csv header;

delete from department;
select * from department;

copy department
to '/home/sagar/music/test.csv'
delimiter ','
csv header;


-- --------------->  Managing Tables <-----------------
-- ----> DataTyes

select salary::numeric(7,2) from employee;
select now()::date;
select current_date;
select to_char(now()::date , 'dd/mm/yyyy') as date;
select now()::date - '2023-02-03' as diff;
select extract(hour from localtime) as hour;
select localtime + interval '2 hour' as t;
SELECT LOCALTIME AT TIME ZONE 'UTC-7';

-- ------->  Array

create table array_prc(
id serial,
name text,
phone text []
);

insert into array_prc (name,phone) values ('sagar','{"9825035725","9978279717"}');
insert into array_prc (name,phone) values ('riyank',array ['8523697415','5689231478']);

select phone[1] from array_prc where id = 1;
select phone from array_prc where id = 1;
select * from array_prc where phone[2] = '9978279717';
select name,unnest(phone) from array_prc;


create table json_prc(
id serial,
name varchar(20),
details json
);

-- ------------> Json

insert into json_prc(name,details) values
('sagar','{"name":"sagar","department":{"first_dpt":"electric","sec_dep":"computer"}}');

select details -> 'name' from json_prc;
select details -> 'department' ->> 'first_dpt' from json_prc; -- the operator ->> gives text form
select details -> 'department' -> 'first_dpt' from json_prc; -- the oerator -> gives json object

select name,json_each(details) from json_prc;
select json_typeof(details -> 'name') from json_prc;

-- ------> Select into 
select * into car2 from car where id <30;
select * from car2;

-- ------> create table as

create temp table car3 as select * from car where id <50; -- temp keyword create a temprory table 
select * from car3;

-- ---------> sequence

create sequence seq_1;
select nextval('seq_1');

create sequence seq_2 start 3 minvalue 1 maxvalue 5 cycle;
select nextval('seq_2');

drop sequence seq_2;

alter sequence seq_2 start 4 maxvalue 10;

-- ---------> generated identity

create table color(
	color_id int generated always as identity (start with 10 increment by 10),
	color_name varchar(20)
)

insert into color (color_id,color_name) values (1,'Yellow'); -- it will give error because it is generated always as identity it don't allow to add id manually
    
insert into color(color_id,color_name)
overriding system value 
values
(1,'Yellow');


drop table color;
select * from color;

create table color(
	color_id int generated by default as identity (start with 10 increment by 10), 
	color_name varchar(20)
)

alter table color
alter column color_id
drop identity;


-- ----> Alter table

alter table employee
add column job_title varchar(20);

alter table employee
drop column job_title;

alter table employee
rename column first_name to First__name;

alter table employee
alter column job_title
set default 'default_value';

alter table employee
alter column job_title 
drop default;

alter table employee
alter column job_title
set not null;

update employee set job_title = 'Data Engineering';

alter table employee
alter column job_title
drop not null;

alter table employee rename to emp_details;
alter table emp_details rename to employee;

alter table employee
add check (job_title = 'Data Engineering');

alter table employee
alter column job_title type varchar(30);

alter table employee
alter column job_title type int using job_title::int;


truncate table color restart identity;

create temp table exa(
id serial,
name varchar(20)
);

insert into exa(name) values
('sagar'),
('riyank'),('rohit');
select * from exa;

truncate table exa restart identity;

drop table exa;

create temp table exa as table payment with no data;
select * from exa;

-- ------------------ Conditional expressions and operators <--------

-- ---> Case
select price,
case 
	when price > 59000 and price < 200000 then 'Smaller'
	when price > 200000 and price <500000 then 'Medium'
	when price > 500000 and price < 900000 then 'larger'
	else 'extralarge'
end as length
from car;

--------> coalescs

select coalesce(email,'not email provided') as email from sample_database; --> if email is null goto next value till not null is encounter

--------> nullif
select 10 / 0 ; -->gives error but

select 10/ null; --> not give error so

select 10/nullif(0,0); --> if two value is same then function return a null and error will not generate

-- -----> 

select 
	cast (price as varchar(20))
from car;

-- same different way

select price::varchar(20) from car;
	price::varchar(20)
from car;

     -













-- --------------> Psql Utilities <--------------

-- ---how to compare two tables? 
CREATE TABLE foo (
	ID INT PRIMARY KEY,
	NAME VARCHAR (50)
);

INSERT INTO foo (ID, NAME)
VALUES
	(1, 'a'),
	(2, 'b');
	
CREATE TABLE bar (
	ID INT PRIMARY KEY,
	NAME VARCHAR (50)
);

INSERT INTO bar (ID, NAME)
VALUES
	(1, 'a'),
	(2, 'b');
select * from foo;
select * from bar;

UPDATE bar
SET name = 'c'
WHERE
	id = 2;
	
select id,name from foo 
except
select id,name from bar;
	
select id,name from bar
except
select id,name from foo;

select bar.id,bar.name,foo.id,foo.name from bar full outer join foo using(id,name) where foo.id is null or bar.id is null;

-- ---- how to generate random number in a range 

select random(); -- gives number between 0 and 1
--  low = 11
-- high = 25
select (random() * (25- 11) + 11)::int;


-- ---->  Explain function

explain analyze select * from bar where id = 1;
explain (costs false) select * from bar where id = 1;










































































-- -----------------> outside from the course <-------------------


insert into emp(name,department,salary)
values ('mayank','computer','40000');

select coalesce(email,'email not provided') from sample_database; -- if email is null  then second value consider as a output if second not then third value is considered

select nullif(77,77); -- if two values is same then it will give null as output
select coalesce(10/nullif(0,0),0);
select now();
select now()::time;
select now() - interval '1 year';


select extract(second from now());
select extract(hour from now());
select extract(minute from now());
select extract(dow from now());
select extract(week from now());
select extract(year from now());
select extract(month from now());
select extract(day from now());

select *,age(now(),dob) as age from sample_database;






