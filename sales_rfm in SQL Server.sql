 --inspecting data 
SELECT top 1040*   FROM sales_data


--checking unique values
SELECT DISTINCT  STATUS from sales_data
SELECT DISTINCT  YEAR_ID from sales_data
SELECT DISTINCT  PRODUCTLINE from sales_data
SELECT DISTINCT  COUNTRY from sales_data
SELECT DISTINCT  TERRITORY from sales_data
SELECT DISTINCT  ORDERNUMBER from sales_data


SELECT DISTINCT  MONTH_ID from sales_data
where YEAR_ID = 2005
---just 5 months in year 2005 --


-- Analysis -- 

--grouping sales by productline

select productline , SUM(sales) as  sum_of_sales
from sales_data
group by productline
order by 2 desc 


select YEAR_ID , SUM(sales) as  sum_of_sales
from sales_data
group by YEAR_ID
order by 2 desc  


select COUNTRY , SUM(sales) as  sum_of_sales
from sales_data
group by COUNTRY
order by 2 desc


select DEALSIZE , SUM(sales) as  sum_of_sales
from sales_data
group by DEALSIZE
order by 2 desc


-- How was the best month for sales in a specific year? How much was earned that month?
SELECT month_id , SUM(sales) as Revenue, COUNT(Ordernumber) as Frequency
from sales_data
where YEAR_ID = 2004 -- cahnge year to know the rest 
group by MONTH_ID
order by 2 desc


--november is the top, what product do they sell in november, classic cars !!

SELECT month_id, productline, SUM(sales) Revenue, COUNT(Ordernumber) as Frequency
from sales_data
where YEAR_ID = 2004  AND MONTH_ID = 11 
group by month_id, productline
order by 3 desc 

-- Who is our best customer  this could be best answer with (FRM)--

DROP TABLE IF EXISTS #rfm ;
with rfm as (
SELECT customername ,
	   sum(sales) monetary_value ,
	   AVG(sales) avg_monetary_value ,
	   count(Ordernumber) frequency,
	   max(orderdate) last_order_date,
	   (select max(orderdate)   from sales_data) as max_order_date,
	   DATEDIFF(DD,max(orderdate),(select max(orderdate)   from sales_data)) as recency  
from sales_data
group by customername),
rfm_calc as (
select r.* ,
	   NTILE(4) OVER (ORDER BY  recency desc) rfm_recency,
	   NTILE(4) OVER (ORDER BY  frequency) rfm_frequency,
	   NTILE(4) OVER (ORDER BY  avg_monetary_value) rfm_monetary
from rfm r )

select c.*,
	   rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	   cast(rfm_recency as varchar(10) ) + cast( rfm_frequency as varchar(10) ) 
	   + cast(rfm_monetary  as varchar(10) ) as rmf_cell_sring
into #rfm
from rfm_calc c		

--SELECT * FROM #rfm



-- what products are most often sold together --  

select distinct ordernumber, STUFF(
	(select ',' + productcode 
	from sales_data a
	where ORDERNUMBER in (
			select ordernumber 
			from(
			select ordernumber, COUNT(*) rn
			from sales_data
			where STATUS = 'Shipped'
			group by ORDERNUMBER) t1
			where rn = 3) 
			and 
			a.ORDERNUMBER = b.ORDERNUMBER
	for xml path (''))
	, 1 , 1 , ' ')
from sales_data b
order by 2 desc 