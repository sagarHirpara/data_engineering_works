-- aggrigate function

select count(*) from film;

select max(salary) from employee;

select min(salary) from employee;

select avg(salary) from employee;

select sum(salary) from employee;

-- Window function
alter table student_p rename column marks_scored to marks;
alter table student_p rename column subject_name to subject;
select subject,max(marks) from student_p group by subject;

with cte as (select subject,max(marks) as max_marks from student_p group by subject) 
select student_p.*,cte.max_marks from student_p,cte where student_p.subject = cte.subject order by student_p.subject;

with cte as (select subject,max(marks) as max_marks from student_p group by subject),
cte2 as (select subject,min(marks) as min_marks from student_p group by subject),
cte3 as (select subject,avg(marks) as avg_marks from student_p group by subject)
select student_p.*,cte.max_marks,cte2.min_marks,cte3.avg_marks from student_p join cte 
on student_p.subject = cte.subject join cte2 on student_p.subject = cte2.subject join cte3 on
student_p.subject = cte3.subject order by student_p.subject;

--- upper query using by window function

select *, max(marks) over(partition by subject) as max_marks from student_p;  
select *,min(marks) over(partition by subject) from student_p;
select *,avg(marks) over() from student_p;

-->  Row number

select *,row_number() over(partition by subject order by marks) from student_p; 

select *,row_number() over(partition by department order by points desc) from quiz; -- only give the rownumber of each group, new group row number start from 1

--- rank function

select *,rank() over(partition by department order by points desc) from quiz; -- same as row_numberbut two same points give same rank 

-- desnse_rank function

select *, dense_rank() over(partition by department order by points desc, time) from quiz; --  give it's rank not row number

-- lag function

select * from quiz;
select *,lag(time) over(partition by department order by time) from quiz; -- by default give previous value
select *,lag(time,2) over(partition by department order by time) from quiz;  -- give previous 2
select *,lag(time,2,0) over(partition by department order by time) from quiz;  -- give previous 2, default value will be 0
select * from quiz offset (select count(*) from quiz) - 3;


-- lead function

select *,lead(time) over(partition by department order by time) from quiz;
select *,lead(time,2) over(partition by department order by time) from quiz;  -- give next 2
select *,lead(time,2,0) over(partition by department order by time) from quiz;  -- give next 2, default value will be 0

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






