
-- creating schema 
create schema project;
use project;

-- creating new tables and importing info from .csv files 
create table customers (
customer_id int primary key,
first_name varchar(50), 
last_name varchar(50),
email varchar (150),
gender varchar (20),
date_of_birth varchar(30),
registration_date varchar(30),
last_purchase_date varchar(30)
);


create table products(
product_id int primary key,
product_name varchar(50),
category varchar(50),
price int,
stock_quantity int, 
date_added varchar(50)
);

create table sales(
sale_id int primary key,
customer_id int,
product_id int,
quantity_sold int,
sale_date varchar(50), 
discount_applied int,
total_amount int
);

create table inventory_movements(
movement_id int primary key,
product_id int,
movement_type varchar(5),
quantity_moved int,
movement_date varchar(50)
);

select * from customers;
select * from inventory_movements;
select * from products;
select * from sales;

-- Module 1: Sales Performance Analysis

-- 1) Total Sales per Month:
-- Calculate the total sales amount per month, including the number of units sold
--  and the total revenue generated.

-- i have saved date as varchar so changign to date first: "str_to_date", then date_format to seperate
-- group by month 
-- agg: total sales, number of units sold, total revenue 

SELECT DATE_FORMAT(STR_TO_DATE(sale_date, '%Y-%m-%d'), '%Y-%m') AS month, COUNT(*) AS total_sales,
sum(quantity_sold) as number_of_units_sold, sum(total_amount) as total_revenue
FROM sales
GROUP BY month
ORDER BY month;

-- 2. Average Discount per Month: 
-- Calculate the average discount applied to sales in each month (sales) and assess how discounting strategies impact total sales.

-- group by month in sales table for avg(discount_applied)

select DATE_FORMAT(STR_TO_DATE(sale_date, '%Y-%m-%d'), '%Y-%m') as month, avg(discount_applied)
from sales
group by month;

select discount_applied, SUM(quantity_sold) AS total_quantity_sold
from sales
group by discount_applied
order by discount_applied;

-- 3. Identify high-value customers:
-- 	Which customers have spent the most on their purchases? Show their details 


select customer_id,sum(total_amount)
from sales
group by customer_id
order by sum(total_amount) desc
limit 10;

-- using cte to store as new table 

with table2 as (
select customer_id,sum(total_amount)
from sales
group by customer_id
order by sum(total_amount) desc
limit 10 )

select * 
from customers
where customer_id in (select customer_id
						from table2);


-- 4) Identify the oldest Customer:
-- Find the details of customers born in the 1990s, including their total spending and specific order details. 

-- inner join on customer_id 
-- use customers table to find details of customers in 1990s
-- where date of birth 
-- group by customer id for sum(total_amount) and order details


select c.customer_id, c.first_name,c.last_name,c.email,c.gender,c.date_of_birth, 
s.sale_id,s.product_id,s.quantity_sold,s.sale_date,
sum(total_amount) over (partition by c.customer_id) as total_spending
from customers c
inner join sales s on c.customer_id = s.customer_id
where date_of_birth between '1990-01-01' and '1999-12-31';

-- 5. Customer Segmentation: 
-- Use SQL to create customer segments based on their total spending (e.g., Low Spenders, Medium Spenders, High Spenders). 

select customer_id, SUM(total_amount),
    case 
        when SUM(total_amount) < 500 then 'Low Spender'
        when SUM(total_amount) <1500 then 'Medium Spender'
        else 'High Spender'
    end as type_of_spender
from sales
group by customer_id
order by SUM(total_amount) desc;


 -- Module 3: Inventory and Product Management
 
 -- 6. Stock Management:
 --  Write a query to find products that are running low in stock (below a threshold like
 -- 10 units) and recommend restocking amounts based on past sales performance.    

-- stock_quantity < 30 from products table : low 
-- recommend if these should be restocked based on their sales 

-- join sales and products 
-- create a cte which stores the joined tables with condition: stock_quantity < 30
-- finally use group by product_id on the new table 
-- order by sum of total amount, limit to top 15 


with q9 as (
select s.product_id,p.stock_quantity, p.price,s.total_amount,s.quantity_sold
from products p
join sales s on p.product_id=s.product_id
where stock_quantity < 30)
     
select product_id, sum(total_amount),sum(quantity_sold)
from q9 
group by product_id
order by sum(total_amount) desc
limit 15;
     

-- 7. Inventory Movements Overview:
-- Create a report showing the daily inventory movements (restock vs. sales) for each product over a given period. 

-- latest period: 2024 
-- out: sale 
-- in: restock 

select product_id, movement_type, count(*)
from inventory_movements
where (movement_date like '2024%')
group by product_id,movement_type
order by product_id asc;


-- 8. Rank Products: 
-- Rank products in each category by their prices.

select product_id ,category,price, dense_rank() over (partition by category order by price desc) 
from products;

-- 9. Average order size: 
-- What is the average order size in terms of quantity sold for each product? 

select product_id, round(avg(quantity_sold),2)
from sales
group by product_id
order by product_id;


-- 10. Recent Restock Product: 
-- Which products have seen the most recent restocks?

-- filter for movement_type = "in" meaning restock 
-- order by movement date, desc
-- set limit of 10 to get most recent 

select * 
from inventory_movements 
where movement_type = "IN"
order by movement_date desc
limit 10;

 

