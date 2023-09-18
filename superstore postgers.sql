SELECT * from superstore limit 10 

-- Q1 What is the total_Sales, total_quantity, total_profit?

SELECT SUM(sales) total_Sales , SUM(profit) total_profit, SUM(quantity) total_quantity
FROM superstore 

-- Q2 What is no_of customers, orders, products?

SELECT 
	COUNT( DISTINCT customer_id) total_customers,
	COUNT( DISTINCT order_id) total_orders,
	COUNT( DISTINCT product_id) total_products
FROM superstore

-- Q3 What is no_of categories, sub_categories, region, state, city?

SELECT 
	COUNT( DISTINCT category) no_of_categories,
	COUNT( DISTINCT sub_category) no_of_sub_categories,
	COUNT( DISTINCT region) no_of_regions,
	COUNT( DISTINCT state) no_of_states,
	COUNT( DISTINCT city) no_of_cities
FROM superstore

-- Q4 What is The Average Profit Margin

SELECT  round((sum(profit)/ sum(sales))*100,2) as avg_profit_margin
FROM superstore

-- Q5 What is The Average Order Value

SELECT  round(sum(sales) / count(distinct(customer_id)),2) as avg_order_value 
FROM superstore

-- Q6 What is the Basket Size 

SELECT  sum(quantity) / count(distinct(customer_id)) as basket_size
FROM superstore

-- Q7 What is the best sales by segment and percent of sales  ?

with seg as (
SELECT 
	segment, sum(sales) sales,
	(select sum(sales) from superstore) all_sales
FROM superstore
group by 1 
order by 2 desc ),

sal_per as (
select * , round((sales / all_sales)*100,2) sales_percent
from seg )

select segment, sales , sales_percent 
from sal_per


-- Q8 What is the best sales by ship_mode and percent of sales ?

with ship_mode as (
SELECT 
	ship_mode, sum(sales) sales,
	(select sum(sales) from superstore) all_sales
FROM superstore
group by 1 
order by 2 desc ),

ship_mode_per as (
select * , round((sales / all_sales)*100,2) sales_percent
from ship_mode )

select ship_mode, sales , sales_percent 
from ship_mode_per


-- Q9 What is the best sales by region and percent of sales ?

with reg as (
SELECT 
	region, sum(sales) sales,
	(select sum(sales) from superstore) all_sales
FROM superstore
group by 1 
order by 2 desc ),

reg_per as (
select * , round((sales / all_sales)*100,2) sales_percent
from reg )

select region, sales , sales_percent 
from reg_per

-- Q10 What is the best sales by  state and percent of sales ?

with sta as (
SELECT 
	 state, sum(sales) sales,
	(select sum(sales) from superstore) all_sales
FROM superstore
group by 1
),

state_per as (
select * , round((sales / all_sales)*100,2) sales_percent
from sta )

select state, sales , sales_percent 
from state_per
order by sales_percent desc 


-- Q11 What is the  sales by each city in state and percent of sales ?

select  state,city , sum(sales) 
FROM superstore
where state = 'Alabama'
group by state,city , sales

-- Q12 What is The shipment_duration average  for each order  ? 

SELECT round(AVG(ship_date - order_date),1) as shipment_duration_by_days
FROM superstore 

-- Q13 What is The sales by  Year,month & season?
-- Year --
SELECT DATE_PART('YEAR',order_date) as year, sum(sales) sales 
FROM superstore 
GROUP BY 1 
order by 2 desc 

-- Month --
SELECT DATE_PART('MONTH',order_date) as month, sum(sales) sales 
FROM superstore 
GROUP BY 1 
order by 2 desc

-- Month in Each Year --
SELECT 
DATE_PART('Year',order_date) as year, 
DATE_PART('MONTH',order_date) as montth,
sum(sales) sales 
FROM superstore 
GROUP BY 1,2
order by 3 desc

-- season --
SELECT 
	CASE 
		WHEN DATE_PART('MONTH',order_date) in (12, 1, 2) then 'Winter'
		WHEN DATE_PART('MONTH',order_date) in (3, 4, 5) then 'Spring'
		WHEN DATE_PART('MONTH',order_date) in (6, 7, 8) then 'Summer'
		ELSE 'Autumn' END AS seasons,
		sum(sales) sales
FROM superstore 
GROUP BY 1 
order by 2 desc


-- Q14 What is The sales runing total for quantity, sales, and profit ?

SELECT 
	order_id,
	DATE_TRUNC('day', order_date),
	sum(quantity) OVER(order by DATE_TRUNC('day', order_date)) quantity_runing_total,
	sum(sales) OVER(order by DATE_TRUNC('day', order_date)) sales_runing_total,
	sum(profit) OVER(order by DATE_TRUNC('day', order_date)) profit_runing_total,
	DENSE_RANK() OVER(order by DATE_TRUNC('day', order_date)) rnk
FROM superstore 

-- Q15 What is The sales difference for cutomers ?
WITH sales as (
SELECT 
	DISTINCT customer_id,
	sum(sales) sum_sales
FROM superstore
group by 1 )

SELECT
	customer_id,
	sum_sales,
	LAG(sum_sales) OVER(order by sum_sales),
	sum_sales - LAG(sum_sales) OVER(order by sum_sales) lag_difference
FROM sales


-- Q16 What is The sales discount percent of sales ?
SELECT  100 * sum(cast(discount as float )*sales) / sum(sales) sales_disc_percent
FROM superstore 


-- Q17 Who are  the customers  they have the most sales top(10) by rank   ?
With best_cust as (
SELECT 
	customer_id, 
	sum(sales) sales ,
	RANK() OVER(order by sum(sales) desc ) rnk 
FROM superstore 
group by 1
order by 2 desc )

SELECT * 
FROM best_cust
WHERE rnk <= 10


-- Q18 What is the most product ordered ? 
SELECT 
	product_name, 
	sum(quantity) total_Quantity ,
	sum(sales) sales_sum
FROM superstore 
group by 1
order by 2 desc
limit 1

-- Q19 What is the most sold product by each customer  ?
WITH t1 as (
SELECT 
	customer_id, 
	product_name, 
	sum(quantity) quantity_sold,
	RANK() OVER(PARTITION BY customer_id order by sum(quantity) desc) rnk 
FROM superstore
group by 1, 2 
order by 3 desc )

SELECT 
	customer_id, 
	product_name, 
	quantity_sold
FROM t1 
WHERE rnk = 1

-- Q20 What is the number of categories sold in each  state?
CREATE EXTENSION tablefunc;


SELECT
	state,
	coalesce(Furniture,0) as Furniture, 
	coalesce(Office_Supplies,0) as Office_Supplies  ,
	coalesce(Technology,0) as Technology
FROM crosstab('SELECT state , category , count(state) quantity 
			  	FROM superstore
				group by 1, 2 
				order by state , category 
				')
				as result(state varchar, Furniture bigint, Office_Supplies bigint ,Technology bigint)


-- Q21 Customer Segmentation (RFM)
/*
first we want to get the recency, frequency and monetary
*/

DROP TABLE IF EXISTS temp_rfm ;
WITH rfm as (
SELECT 
	customer_id,
	sum(sales) as monetary,
	count(order_id) as  frequency,
	max(order_date) as  last_order_date,
	(select max(order_date) from superstore ) as max_order_id,
	((select max(order_date) from superstore ) - max(order_date)) as recency
	
FROM superstore
group by customer_id 
),
rfm_cal as (
select *, 
	NTILE(4) OVER(ORDER BY recency  desc ) as rfm_recency,
	NTILE(4) OVER(ORDER BY frequency) as rfm_frequency,
	NTILE(4) OVER(ORDER BY monetary) as rfm_monetary
	

from rfm)

SELECT 
	*,
	cast(rfm_recency as varchar(10)) || cast(rfm_frequency as varchar(10)) || cast(rfm_monetary as varchar(10)) as rfm_column
into temp_rfm
from rfm_cal

-- Customer Segmentation (puting customers in groups)
DROP TABLE IF EXISTS temp_customer_seg;
SELECT 
	customer_id,
	rfm_recency,
	rfm_frequency,
	rfm_monetary,
	CASE 
	WHEN rfm_column in ('111', '112', '142', '131', '124', '121', '122', '123', '132', '211', '212', '114', '141', '144', '221', '113') then 'lost customers'  
	WHEN rfm_column in ('133', '143', '143', '244', '242', '334', '343', '344', '224', '243', '234', '134', '213', '214','324', '314', '313') then 'slipping away - can not lose' --(big spenders who haven't purchased lately) sliping away
	WHEN rfm_column in ('311', '411', '414', '331', '412', '421','413') then 'new customers'
	WHEN rfm_column in ('222', '223', '233', '322', '232', '231', '241','312') then  'potential churners'
	WHEN rfm_column in ('323', '333', '321', '422', '332', '432', '423','431', '342' ) then  'active'--(customers who buy often & recently, but at low price point)
	WHEN rfm_column in ('433', '434', '443', '444','442','424') then 'loyal'
end as rfm_segments
into temp_customer_seg
from temp_rfm


-- Count the no. of customers in each group --

SELECT rfm_segments, COUNT(rfm_segments)
FROM temp_customer_seg
GROUP BY 1 
order by 2 desc



--select * from temp_rfm 
--select * from temp_customer_seg
	
	
	









