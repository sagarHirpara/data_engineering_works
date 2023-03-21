--> we can make update, delete and select using with CTE
-- create user = create role + login
-- create role = create role only


----------->  Managing Databases  <--------

create database datbase_exa_2
with
	owner = postgres
	template = template1
	encoding = 'UTF-8'
	tablespace = pg_default
	connection limit = -1
	is_template = True;
	
grant all on database datbase_exa_1 TO riyank;
grant all on database datbase_exa_1 to sagar;

--   alter database

alter database datbase_exa_1 
with
	is_template = false 
	connection limit = 1000;

-- ----- rename database

alter database datbase_exa_1 rename to database_exa_1;
alter database database_exa_1
set tablespace pg_default;

-- ----- copy database

create database example with template riyank;

pg_dump -U postgres -d Practice -h localhost -f sourcedb.sql --- used by terminal for .sql file

pg_dump -U postgres -h localhost -W -F t Practice > sourcedb.tar   -- for create a tar file

select pid,usename,client_addr from pg_stat_activity where datname = 'riyank';  --- for check active connection
select pg_terminate_backend(pid) from pg_stat_activity where datname = 'riyank';  -- for terminate active connection

pg_dump -U postgres -d Practice -f sourcedb.sql

-- SELECT  *
-- FROM pg_stat_activity
-- WHERE datname = 'database_exa_1';

-- SELECT
--     pg_terminate_backend (pid)
-- FROM
--     pg_stat_activity
-- WHERE
--     datname = 'database_exa_1';

select pg_relation_size('actor');
select pg_size_pretty(pg_relation_size('actor'));

select pg_size_pretty(pg_total_relation_size('actor'));

select pg_size_pretty(pg_database_size('Practice'));

select * from pg_database;

select pg_database.datname,pg_size_pretty(pg_database_size(pg_database.datname)) from pg_database;

select pg_size_pretty(pg_indexes_size('actor'));

select pg_size_pretty(pg_tablespace_size('pg_default'));

---------------------------------->   Managing schema

-- schema is a namespace that contain named database object such as..
-- 	table
-- 	view
-- 	index
-- 	data types
-- 	procedure
-- 	function
-- 	operator

select current_schema;
show search_path;

create schema admin;
show search_path;

select current_schema();
set search_path to admin;

set search_path to admin;

create table sagar(id serial,name varchar(20));
set search_path to email;
create schema email authorization sagar;

select * from pg_roles;

create role john login password '12345';

create schema play authorization john;

-- -------->  Alter schema

alter schema play rename to play_ground;
alter schema play_ground owner to postgres;

SELECT * 
FROM 
    pg_catalog.pg_namespace
WHERE 
    nspacl is NULL AND
    nspname NOT LIKE 'pg_%'
ORDER BY 
    nspname;
	
-- 	------ drop schema

drop schema if exists email,admin;
drop schema if exists email,admin cascade;

--------->  table space

create tablespace student_d location '/home/sagar/abcd'; -- right now it will give error for permission

alter tablespace pg_global rename to student_d_2;
alter tablespace student_d_2 rename to pg_global;   -- don't be able to rename which start is with pg

alter tablespace student_d owner to john;

drop tablespace student_d;


-- ------>  Roles & Privileges  


create role rohit with nologin;
create role yash with login password 'Yash@123';
create role dhainik superuser login password 'Dhainik@123';
create role dev createdb login password 'Dev@123';
create role krinal login password 'Krinal@123' valid until '2024-03-23';
create role tapu login password 'Tapu@123' connection limit -1;
create role tinu login password 'Tinu@123' connection limit -1;
create role devs with nologin;

grant select,insert,update on public.account to tapu; 

grant select on public.employee to tinu;

grant all on all tables in schema play_ground to tinu;

-- Revoke 

revoke all on public.account from tinu;

------>  Alter role

alter role krinal rename to kinu;

---->  Drop role

reassign owned by tapu to postgres;  -- Copy the tapu privilleges into postgres 
drop owned by tapu; -- delete the tapu's privilleges

drop role tapu; -- drop the tapu role

------- Role Membership

select * from pg_catalog.pg_user;

grant tinu to dhainik;

--->



