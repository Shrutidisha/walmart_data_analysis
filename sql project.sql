--creating table sale
create table sale(
transaction_id int,
customer_id int,
product_id int,
product_name varchar(50),
category varchar(50),
quantity_sold int,
unit_price numeric,
transaction_date timestamp,
store_id int,
store_location varchar(50),
inventory_level int,
reorder_point int,
reorder_quantity int,
supplier_id int,
supplier_lead_time int,
customer_age int,
customer_gender varchar(10),
customer_income numeric,
customer_loyalty_level varchar(10),
payment_method varchar(20),
promotion_applied varchar(10),
promotion_type varchar(20),
weather_conditions varchar(10),
holiday_indicator varchar(10),
weekday varchar(10),
stockout_indicator varchar(10),
forecasted_demand int,
actual_demand int
);

--importing the dataset 
COPY sale (transaction_id,customer_id,product_id,product_name,category,quantity_sold,unit_price,transaction_date,store_id,store_location,
inventory_level,reorder_point,reorder_quantity,supplier_id,supplier_lead_time,customer_age,customer_gender,customer_income,
customer_loyalty_level,payment_method,promotion_applied,promotion_type,weather_conditions,holiday_indicator,weekday,stockout_indicator,
forecasted_demand,actual_demand)
FROM 'C:/Users/Public/project docs/archive/walmart.csv'
DELIMITER ','
CSV HEADER;

--for checking if table was present
select * from sale;




--sales and revenue analysis


--Q: What are the overall sales trends, including total revenue, monthly trends, and the highest revenue-generating period?

--total,avg sales revenue and total orders calculation
SELECT SUM(quantity_sold * unit_price) AS total_sales_revenue,
     count(transaction_id) as total_orders,
	 AVG(quantity_sold * unit_price) AS average_order_value
FROM sale;

--monthly revenue
create view monthly_revenue_sale as                            
select date_trunc('month',transaction_date)as month,
sum(quantity_sold * unit_price) as monthly_sales,
sum(quantity_sold) as total_quantity_sold
FROM sale
GROUP BY DATE_TRUNC('month', transaction_date);
select month,monthly_sales,total_quantity_sold
from monthly_revenue_sale
order by month;

--quarterly revenue
select date_trunc('quarter',transaction_date)as quarter,
sum(quantity_sold * unit_price) as quarterly_sales
from sale
GROUP BY DATE_TRUNC('quarter', transaction_date)
order by quarter;

--daily sales
SELECT DATE(transaction_date) AS day,
       SUM(quantity_sold * unit_price) AS daily_sales_revenue
FROM sale
GROUP BY DATE(transaction_date)
ORDER BY day;

--month with highest revenue
select month,monthly_sales
from monthly_revenue_sale
order by monthly_sales desc
limit 1;


--Q. How does sales revenue change month over month?

--sales growth rate
select monthly_sales,
lag(monthly_sales)over (order by month) as previous_month_sales,
ROUND(
           (monthly_sales -lag(monthly_sales)over (order by month) ) * 100.0 /
           COALESCE(lag(monthly_sales)over (order by month), 1), 2
       ) AS growth_rate
from monthly_revenue_sale;


--Q.How does sales revenue differ between holidays and regular days?

--sales on basis of holiday and weekdays
select holiday_indicator,
sum(quantity_sold * unit_price) as total_revenue,
sum(quantity_sold) as total_sale
from sale
group by holiday_indicator;
--day wise sales
create view weekday_sort as
select weekday,
sum(quantity_sold * unit_price) as total_revenue,
sum(quantity_sold) as total_sale
from sale
group by weekday
ORDER BY ARRAY_POSITION(ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'], weekday);


--Q.How do different weather conditions impact sales?

--sales affected by weather conditions
select weather_conditions,
sum(quantity_sold * unit_price) as total_revenue,
sum(quantity_sold) as total_sale
from sale
group by weather_conditions;


--Q: Which stores generate the most revenue?

--sales by store location
SELECT store_location,
       SPLIT_PART(store_location, ',', 2) AS state, 
       sum(quantity_sold * unit_price) as total_revenue,
sum(quantity_sold) as total_sale
FROM sale
GROUP BY store_location
ORDER BY total_revenue DESC;




--customer behavior


--Who are the highest spending customers, and how does customer loyalty affect revenue?

--customer with the spend with the product
SELECT customer_id,sum(quantity_sold) as total_quantity,
sum(quantity_sold * unit_price) as total_amount,
product_name
FROM sale
GROUP BY customer_id,product_name
ORDER BY total_amount DESC;

--highest spending customers
SELECT customer_id, SUM(quantity_sold *unit_price) AS total_revenue
FROM sale
GROUP BY customer_id
ORDER BY total_revenue Desc
limit 20;

--customer loyalty wise sales
select customer_loyalty_level,count(distinct customer_id) as total_customers,SUM(quantity_sold *unit_price) AS total_revenue
from sale
group by customer_loyalty_level
ORDER BY total_revenue Desc;

--customer with their loyalty change
SELECT customer_id, 
       STRING_AGG(DISTINCT customer_loyalty_level, ' -> ') AS loyalty_changes
FROM sale
GROUP BY customer_id
HAVING COUNT(DISTINCT customer_loyalty_level) > 1;



--Q.How do customer purchasing frequency, lifetime value, repeat purchases, and demographics (age & gender) impact sales?

-- top 10 customers with the highest purchase frequency
select customer_id,
    count(customer_id) as purchase_count
from sale
group by customer_id
order by purchase_count desc
limit 10;

--lifetime value
SELECT customer_id, 
       SUM(quantity_sold * unit_price) AS lifetime_value 
FROM sale
GROUP BY customer_id 
ORDER BY lifetime_value DESC;

--new and repeated customers
SELECT customer_id, 
       COUNT(DISTINCT DATE_TRUNC('month', transaction_date)) AS purchase_months 
FROM sale
GROUP BY customer_id 
HAVING COUNT(DISTINCT DATE_TRUNC('month', transaction_date)) > 1; -- Repeat Customers
SELECT customer_id, 
       DATE_TRUNC('month', transaction_date)::DATE AS purchase_month
FROM sale
GROUP BY customer_id,DATE_TRUNC('month', transaction_date)
HAVING COUNT(DISTINCT DATE_TRUNC('month', transaction_date)) =1; -- NEW CUSTOMERS

--customer segmentation by age and gender
SELECT 
    CASE 
        WHEN customer_age BETWEEN 18 AND 24 THEN '18-24'
        WHEN customer_age BETWEEN 25 AND 34 THEN '25-34'
        WHEN customer_age BETWEEN 35 AND 44 THEN '35-44'
        WHEN customer_age BETWEEN 45 AND 54 THEN '45-54'
        WHEN customer_age between 55 and 64 THEN '55-64'
		when customer_age between 65 and 74 then '65-74'
        ELSE 'Unknown'
    END AS age_group,
    customer_gender,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(quantity_sold * unit_price) AS total_revenue,
    AVG(quantity_sold * unit_price) AS avg_spending_per_customer
FROM sale
GROUP BY age_group, customer_gender
ORDER BY age_group, total_revenue DESC;



--product performance analysis


--Q: Which products and categories generate the most revenue?
--top selling product by revenue
select product_name,sum(quantity_sold *unit_price) as money_spent
from sale
group by product_name
order by money_spent desc
limit 3;

--product wise sales
select product_name,
      sum(quantity_sold) as total_quantity_sold,
	  sum(quantity_sold * unit_price) as revenue 
from sale
group by product_name
order by total_quantity_sold,revenue desc;

--category wise sales
select category,sum(quantity_sold) as total_quantity_sold,
sum(quantity_sold * unit_price) as revenue
from sale
group by category
order by total_quantity_sold desc;



--Promotion effect

--Q.Which type of promotion results in the highest revenue?
--revenue with and without promotion
SELECT promotion_applied, 
       SUM(quantity_sold * unit_price) AS revenue 
FROM sale
GROUP BY promotion_applied 
ORDER BY revenue DESC;
SELECT promotion_type,
       COUNT(distinct customer_id) AS total_transactions, 
       SUM(quantity_sold * unit_price) AS revenue 
FROM sale 
where promotion_applied = 'TRUE'
GROUP BY promotion_type
ORDER BY revenue DESC;



--store performance

--Q.Which product generates the highest revenue in each store?
--store with their highest revenue generating product
SELECT store_id, store_location, 
       SUM(quantity_sold * unit_price) AS store_revenue,
	   sum(quantity_sold) as sold_quantity,
	   product_name	   
FROM sale 
GROUP BY store_id,product_name,store_location
ORDER BY store_revenue DESC;


--Q,Which regions generate the highest sales revenue?
--sales by region
SELECT SUBSTRING(store_location FROM LENGTH(store_location) - 2) AS state, 
       SUM(quantity_sold * unit_price) AS total_sales, 
	   sum(quantity_sold) as quantity_sold
FROM sale 
GROUP BY state 
ORDER BY total_sales DESC;




--Q.Which products experience frequent stockouts in different stores?
--stockout analysis
SELECT product_id, product_name, 
       store_id,store_location,
       COUNT(*) AS stockout_occurrences 
FROM sale 
WHERE stockout_indicator = 'TRUE'
GROUP BY product_id, product_name,store_id,store_location
ORDER BY stockout_occurrences DESC;




--Payment Methods and High-Value Transactions


--Q: Which payment methods are most used, and what are the highest transaction values?
--payment method analysis
SELECT payment_method, 
       COUNT(distinct customer_id) AS customer_using, 
	   count(*) as transaction_count,
       SUM(quantity_sold * unit_price) AS revenue,
	   sum(quantity_sold) as total_quantity,
	   SUM(quantity_sold * unit_price) / COUNT(DISTINCT transaction_id) AS avg_order_value 
FROM sale
GROUP BY payment_method 
ORDER BY revenue DESC;

--higher end transaction
SELECT transaction_id, 
       customer_id, 
       SUM(quantity_sold * unit_price) AS order_value,
	   product_name
FROM sale 
GROUP BY transaction_id, customer_id,product_name 
ORDER BY order_value DESC 
LIMIT 10;

--inventory level analysis
SELECT store_id,store_location, AVG(inventory_level) AS avg_inventory
FROM sale
GROUP BY store_location,store_id;
