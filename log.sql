create table person(
id bigserial not null primary key,
first_name varchar(50) not null,
last_name varchar(50) not null,
gender varchar(7) not null default 'male',
date_of_birth date not null,
email varchar(150));

insert into person(first_name,last_name,gender,date_of_birth)
values('sagar','hirapara','male',date '2002-06-02');

insert into person(first_name,last_name,date_of_birth,email) 
values ('riyank','hirapara',date '2001-2-22','riyankhirapara@gmail.com'),
		('rohit','kachadiya',date '2000-3-21','rohitkachadiya2gmail.com');


select * from dd;

create table emp(
id serial primary key,
name varchar(20),
department varchar(20),
salary bigint);

insert into emp(name,department,salary)
values ('a','1',10000),
		('b','5',5000),
		('c','5',7000),
		('d','2',2000),
		('e','3',6000);
		
Select e.id
From emp e
Where not exists
(Select * From emp s where s.department = '5' and
s.salary >=e.salary)	

Select e.id
From employee e 
Where e.department <> '5' and e.salary> any
(Select distinct salary From employee s Where s.department = '5'); 

create table dd(
Borrower varchar(100),
Bank_Manager varchar(100),
Loan_Amount bigint);

insert into dd(Borrower,Bank_Manager,Loan_Amount)
values ('Ramesh','Sunderajan',10000),
		('Suresh','Ramgopal',5000),
		('Mahesh','Sunderajan',7000);

SELECT Count(*)
FROM ( ( SELECT Borrower, Bank_Manager
FROM dd) AS S
NATURAL JOIN ( SELECT Bank_Manager, Loan_Amount
FROM dd) AS T );

create table sample_database (
	id INT,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	email VARCHAR(50),
	gender VARCHAR(50),
	dob DATE,
	salary INT,
	country VARCHAR(50)
);







