
do $$
declare
	film_count int := 0;
begin
	select count(*) into film_count from film;
	
	raise notice 'the film count is %', film_count;
	
end$$;

-- ---- both are same but we mostly used upper part to demonstrate the block in pl/Sql

do '
declare
	film_count int := 0;
begin
	select count(*) into film_count from film;
	
	raise notice ''the film count is %'', film_count;
	
end';


-- ---- 

do $$
declare
	first_num int := 10;
	second_num int := 20;
	total int;
begin
	total := first_num + second_num;
	raise notice 'the sum is %',total;
end $$;
	
-- -----

do $$
declare
	counter integer := 1;
	first_name varchar(20) := 'sagar';
	last_name varchar(50) := 'Hirapara';
	payment numeric(12,2) := 20.45;
begin
	
	raise notice '%. % % has paid % USD',
	counter,
	first_name,
	last_name,
	payment;
end$$;


-- -----

do $$
declare
	today time := now();	
begin
	raise notice 'time is %',today;
	perform pg_sleep(10); -- sleep the process till 10 second
	today := now();
	raise notice 'time is %',today;
end$$;


-- -----

do $$
declare
	title film.title%type;
	featured_title title%type;
begin
	select film.title into title from film where film_id = 100;
	raise notice 'the title is %',title;
	
end$$;

----

do $$
declare
	title film.title%type;
	featured_title title%type;
begin
	select film.title into featured_title from film where film_id = 10;
	raise notice 'the title is %',featured_title;
	
end$$;

-- ---- Creatign a sub-block

do $$
declare 
	counter integer := 0;
begin
	counter := counter + 1;
	raise notice 'the current counter is% ',counter;
	
	declare
		counter integer := 0;
	begin
		counter := counter + 10;
		raise notice 'the counter is %',counter;
	end;
	
	raise notice 'the counter is %',counter;
end$$;

-- ------- row type gives all the record not for selected column

do $$
declare
	film film%rowtype;
begin

	select * into film from film;
	raise notice 'the film title is %', film;
end$$;

------------ gives particular record


do $$
declare
	film record;
begin

	select title,description into film from film;
	raise notice 'the film description is %', film.description;
end$$;


--  use of constant 

do $$
declare
	pi constant integer := 10;
	x integer := 100;
	r integer;
begin
	r := pi * x;
-- 	pi = pi + 10; it will give error
	raise notice 'result is %',r;
end$$;


-- --------  raise error

do $$
declare 
	email varchar(30) := 'hiraparasagar3@gmail.com';
begin

	raise exception 'email is not valid %', email using hint = 'please enter right email';

end$$;

do $$ 
begin 
	raise invalid_regular_expression;
end $$;



-- ---- assert

do $$
declare	
	film_count integer;
begin

	select count(*) into film_count from film;
	 --- if the condition is right then error message is not display but if not satisfied condition then it will raise the error
	
	assert film_count = 1001, 'film is not more than 0';         

end$$;          


-- --------------->    Control structures   <-------------

-- ----- If statement
do $$
declare	
	selected_film film.title%type;
	film_id_ film.film_id%type := 1;
begin

	select title into selected_film from film where film.film_id = film_id_;

if not found then
	raise notice 'film with id % is not found',film_id_;
else
	raise notice 'film wih id % is found and it''s name is %',film_id_,selected_film;
	
end if;

end$$;

-- ---- elsif <---

do $$
declare
	v_film film%rowtype;
	id film.film_id%type := 101;
	len_des varchar(200);
begin

select * into v_film from film where film.film_id = id;
if not found then
	raise notice 'the film is not found';
else
	if v_film.length > 0 and v_film.length<50 then
		len_des = 'short';
	elsif v_film.length > 50 and v_film.length < 120 then
		len_des = 'medium';
	elsif v_film.length >120 then
		len_des = 'Large';
	else
		len_des = 'N/A';
	end if;
	
	raise notice 'the film % and it''s description is: %', v_film.title ,len_des;
end if;
end$$;

do $$
declare
	rate film.rental_rate%type;
	price_segment varchar(30);
	
begin
	
	select rental_rate into rate from film where film_id = 100;
	
	if not found then 
		raise notice 'film not found';
	else 
		case rate
			when 0.99 then
			price_segment = 'Mass';
			when 2.99 then
			price_segment = 'Mainstream';
			when 4.99 then
			price_segment = 'High';
			
			else 
			price_segment = 'Unspecified';
		end case;
		raise notice '%',price_segment;
	end if;
end $$;


do $$
declare
	total_payment numeric;
	service_level varchar(25) ;
begin

	select sum(amount) into total_payment
     from Payment
     where customer_id = 100; 
	
	if found then
		case
			when total_payment > 200 then
				service_level = 'platinum';
			when total_payment > 100 then
				service_level = 'Gold';
			else
				service_level = 'Silver';
		end case;
		raise notice 'the service level is %', service_level;
	end if;
end $$;
 
--  -------> Loop 

do $$
declare
	i integer := 0;
	j integer := 1;
	counter integer := 0;
	n integer := 10;
	fib integer := 0;
begin

	if n<1 then
		fib = 0;
	end if;
	
	loop 
		exit when n = counter;
		counter := counter + 1;
		select j,i+j into i,j;
	end loop;
	fib := i;
	raise notice '% fibonaci number is %',n,i;
end $$;


-- -----> while loop

do $$
declare 
	i integer := 0;
	n integer := 10;
begin

	while i <> n loop
		raise notice '%',i;
		i = i + 1;
	end loop;

end $$;

-- ---- For loop

do $$
begin

for i in 1..5 loop
	raise notice '%',i;
end loop;

for i in reverse 5..1 loop
	raise notice '%',i;
end loop;

for k in 1..10 by 2 loop
	raise notice '%',k;
end loop;

for k in reverse 10..1 by 2 loop
	raise notice '%',k;
end loop;
end $$;
 
 
-- ---- Loop with select

do $$
declare
	i record;
begin
for i in select * from account loop
	raise notice '% % %',i.id,i.owner,i.balance;
end loop;
end $$;


-- -------> Exit 
do $$
begin
for i in 1..5 loop
	exit when i >= 4;
	raise notice '%',i;
end loop;
end $$;


-- ------> Continue

do $$
begin
for i in 1..5 loop
	continue when i = 3;
	raise notice '%',i;
end loop;
end $$;

-- -------->   User define function

create or replace function no_of_film()
returns int
language plpgsql
as
$$
declare
	film_count integer;
begin
	
	select count(*) into film_count from film where film_id between 1 and 300;
	update film set title = 'sagar hirapar two times' where film_id = 2;
	return film_count;

end $$;

select * from film where film_id = 2;
select no_of_film();

-- fun 2 : sum of two number
-- we can not change data type if we want to change it and run replace function it will give error,so for that we need to drop it and create new one

drop function if exists sum_of_two(x int,y int); 
create or replace function sum_of_two(x int,y int)
returns void
language plpgsql
as
$$
begin
	raise notice 'the sum is %',x+y;
end $$;

select sum_of_two(10,20);


create or replace function print(a int,b int,c int,d int,e int)
returns void
language plpgsql
as
$$
begin
	
	raise notice 'a value is %', a;
	raise notice 'b value is %', b;
	raise notice 'c value is %', c;
	raise notice 'd value is %', d;
	raise notice 'e value is %', e;
end$$;

select print(50,10,d:=20,c:=30,e:=20);

-- Mode in userdefine function

create or replace function abc(out min_len int,out max_len int,out avg_len numeric)  -- it will return record as output
returns record
language plpgsql
as
$$
declare 
	ae int := 10;
begin
select min(length),max(length),avg(length)::numeric into min_len,max_len,avg_len from film;
end$$;

select abc();
select * from abc();


create function pymax (a integer, b integer)
  returns integer
  language plpython3u
AS $$
  if a > b:
    return a
  return b
$$;

select pymax(10,20);


--   inout mode

create function swap(inout x int,inout y int)
language plpgsql
as
$$
begin
	select x,y into y,x;

end$$;

select swap(12,20);

-- ---> Method Overloading

create function first_1(a int,b int)
returns int
language plpgsql
as
$$
begin
	return a + b;
end $$;

create function first_1(a int)
returns int
language plpgsql
as
$$
begin
return a + 10;
end $$;

select first_1(10,20);
select first_1(10);


-- -------->  Exception Handling
-- -----> We can't use transaction in the user define function and block, for that we need a procedure
do $$
declare
	rec record;
	v_film_id film.film_id%type := 0;
begin
	select * into strict rec from film; 

	exception
		when no_data_found then
			raise notice 'data not found';
-- 		when too_many_rows then 
-- 			raise notice 'multiple record found';
		when sqlstate 'P0003' then
			raise notice 'multiple record found bro';
end $$;


-- ------>  Procedure 

create or replace procedure first_procedure(a int,b int)
language plpgsql
as
$$
declare
begin
	raise notice 'the sum is %',a+b;
	return;   -- stop the execution of the function  
	raise notice 'the totla sum';
end $$;
 
call first_procedure(10,20);

-- mode in procedure

DROP PROCEDURE get_film_count() 
create or replace procedure get_film_count(out film_count int,out b int)
language plpgsql
as
$$
begin
	b = 10;
	call first_procedure(10,20);
	select count(*) into film_count from film;

end$$;

call get_film_count(0,0);



-- ------->   Courser in postgres
-------- declare the cursor

create or replace function lan()
returns void
language plpgsql
as
$$
declare

	c1 cursor for select * from language;
	rec record;
begin	

	open c1;
	fetch last from c1 into rec;    -- 	fetch first from c1 into rec;
	raise notice 'name is %',rec.name;
	fetch prior from c1 into rec; --- one step backward from current position
	raise notice 'name is %',rec.name;
	
	fetch absolute 3 from c1 into rec;   -- fetch particular row --> fetched 3rd row
	raise notice 'name is %',rec.name;
	
	fetch next from c1 into rec;  -- fetch the next row from the current pointer
	raise notice 'name is %',rec.name;
	
	fetch relative -3 from c1 into rec;
	raise notice 'name is %',rec.name;
	
	move first from c1;
	fetch from c1 into rec;
	raise notice 'name is %',rec.name;
	
	move forward 3 from c1;
	fetch from c1 into rec;
	raise notice 'name is %',rec.name;
	close c1;
	
	
end $$;

select lan();


create or replace function langu()
returns void
language plpgsql
as 
$$
declare 
	c1 cursor for select * from language;
	rec language%rowtype;
begin
	open c1;
	loop
		fetch from c1 into rec;
		exit when not found;
		raise notice '%,%', rec.language_id, rec.name;
	end loop;
	close c1;
end $$;

select langu();


-- ------->> Trigger function in postgres

create trigger check_data
before insert on employee
for each row execute procedure check_data();

create or replace function check_data() 
returns trigger 
language plpgsql
as
$$
begin

	if new.salary < 5000 then
		raise exception 'salary can not less than 5000';
	end if;
	
	return new;

end $$;

insert into employee values (125,'sagar','computer',4000);


create or replace trigger delete_trigger
before delete on employee
for each row execute procedure check_delete();

create or replace function check_delete()
returns trigger
language plpgsql
as 
$$
begin
	if old.salary< 6000 then
		raise exception 'can''t delte the row because salary is less than 6000';
	end if;
	
	return old;
end $$;

delete from employee where emp_id = 117;


-- update trigger
create trigger update_check
before update on language
for each row execute procedure update_check();

create or replace function update_check()
returns trigger
language plpgsql
as
$$
begin

	if new.name = old.name then
		raise exception 'you enter a same name';
	end if;
	return new;
end $$;

update language set name = 'english' where language_id = 1;

create trigger update_check
before update on film
for each row execute procedure update_check();

















































































































































-- -----

begin
set transaction isolation level serializable 
select * from account;
select sum(balance) from account;
insert into account(owner,balance) values('sum',270);
commit;
rollback


delete from account where id = 19;

alter table account alter column id restart with 7;

alter table account add primary key (id);

-- for restart identity

select setval(pg_get_serial_sequence('table_name','Column_name'),max('Column_name')) from table_name;
select setval(pg_get_serial_sequence('account','id'),max(id)) from account;


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          




	
























