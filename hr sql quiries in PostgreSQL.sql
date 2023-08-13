SELECT * FROM hr limit 20

-- adding age column -- 

ALTER TABLE hr 
ADD COLUMN age  int

UPDATE hr 
set age = DATE_PART('year', now()) - DATE_PART('year', birthdate)



-- What is the gender breakdown of employees of the company ?

SELECT gender , count(*) as count 
from hr 
where age > 18  and termdate IS  NULL
group by 1 


-- What is the race  breakdown of employees of the company ?


SELECT race , count(*) as count 
from hr 
where age >= 18  and termdate IS  NULL
group by 1 
order by 2 desc 


--- What is the age distribution employees in the company ? 

select min(age) youngest, max(age) oldest
from hr 
where  age >= 18  and termdate IS  NULL


select case
		when age >= 21 and age <= 29 then '21 - 29'
		when age >= 30 and age <= 39 then '30 - 39'
		when age >= 40 and age <= 49 then '40 - 49'
		when age >= 50 and age <= 59 then '50 - 59'
		else '+60' 
		END AS age_groups,
		count(*)
from hr 
where termdate is null 
group by 1 
order by 2 desc

--- Employees location (remote VS headquarters )

SELECT location , count(*)
from hr 
where  age >= 18  and termdate IS  NULL
group by 1 
order by 2 desc


--- What is the average length of employment for employees whi have been eliminated ?


SELeCT round(avg(cast(termdate as date) -  hire_date) / 365) as avg_length_of_employment
from hr 
where  termdate >= now() and age >= 18  and termdate IS NOT  NULL


--- How does the gender distibution vary across departments and job titles ?


select department,
	   coalesce(Female,0) as Female,
	   coalesce(Male,0) as Male,
	   coalesce(Non_Conforming,0) as Non_Conforming
from crosstab('
			SELECT department , gender, cast(COUNT (*) as numeric ) 
			from hr 
			where age >= 18  and termdate IS NOT  NULL
			group by 1, 2 
			order by 1, 2 ')
			as result 
			(department varchar(50), Female numeric, Male numeric , Non_Conforming numeric )



--- What is the distribution of job titles across the company ?

select jobtitle , count(*)
from hr 
where age >= 18  and termdate IS NOT  NULL
group by 1 
order by 2 desc


--- Which department has the highest turnover rate ?


with t1 as (
SELECT department , 
		cast(count(*) as numeric ) as total_count,
		cast (Sum(case when termdate IS not null and termdate <= now() then 1 else 0 End) as numeric)  as total_term
from hr 
group by 1 )

select department ,total_count, total_term, round((total_term / total_count)*100,2) as turnover_rate
from t1 
order by 3 desc 



--- employees distribution by city and state -- 

-- by state

select location_state, count(*)
from hr 
group by 1 
order by 2 desc

--- by city 

select location_city, count(*)
from hr 
group by 1 
order by 2 desc


--- how was the company's employee count changed over time based on hire and term dates ?

with t1 as (
select date_part('year',hire_date) as year , count(*) as hires,
cast (Sum(case when termdate IS not null and termdate <= now() then 1 else 0 End) as numeric) as term
from hr 
group by 1)

select year, hires, term, round(((hires - term)/hires)*100,2)
from t1 
group by 1 ,2,3
order by 1 


-- what is the tenure distribution for each depaartment ?


SELeCT department ,round(avg(cast(termdate as date) -  hire_date) / 365) as avg_tenure
from hr 
where  termdate >= now() and age >= 18  and termdate IS NOT  NULL
group by 1 
order by 2 desc 




