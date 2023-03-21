-- aggrigate function

select count(*) from film;

select max(salary) from employee;

select min(salary) from employee;

select avg(salary) from employee;

select sum(salary) from employee;

-- string function

select ascii('A');
select chr(65);
select concat('a','b','c');
select concat_ws(',','a','b','c');
select FORMAT('Hello %s %s','PostgreSQL','sagar hirapara');  -- %s replace by coresponding variable
select initcap('sagar hirapara'); -- first letter of word will be capitalize
select lower('SAGAR HIRAPARA');
select upper('sagar hirapra');
select length('sagar hirapara');
select left('abcde',2);
select right('abcd',3);
select lpad('sag',7,'t');
select rpad('sag',7,'t');
select ltrim('00890','0');
select rtrim('sgarrrr','r');
select btrim('sagar hiraparas','s');
select trim('   sagar hirapara   ');
select md5('sagar');
select position('ga' in 'sagar');
select repeat('*',5);
select replace('ABC','B','A');
select reverse('abc');
select split_part('12-02-2022','-',3);
select substring('abcd',2,4);  -- (string,start_position,substrin of how many character)


-- math function

select ceil('33.6');
select floor('33.6');
select abs(-33.6);
select div(8,3);
select pow(3,2);
select mod(9,2);
select cbrt(8);
select sqrt(9);
select trunc(10.5);
select sign(65); -- return 1 or -1 if negative then -1 or  
select scale(3.4555);
select round(10.4);
select pi();

-- date function

select current_date;
select current_time;
select now();
select current_timestamp;
select age(now(),'02-06-2002');






