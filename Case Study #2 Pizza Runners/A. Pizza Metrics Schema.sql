/* 1. How many pizzas were ordered? */
SELECT COUNT(order_id)
FROM customer_orders;

/* 2. How many unique customer orders were made?*/
SELECT COUNT(DISTINCT order_id) 
from customer_orders;

/* 3. How many successful orders were delivered by each runner?*/
SELECT COUNT(order_id) 
from runner_orders
where pickup_time != 'null';

/* 4. How many of each type of pizza was delivered?*/
SELECT c.pizza_id, COUNT(c.pizza_id) as number_pizza_deliverd
from customer_orders c
JOIN runner_orders r
on c.order_id = r.order_id
and r.pickup_time != 'null'
GROUP by 1;

/* 5. How many Vegetarian and Meatlovers were ordered by each customer?*/
SELECT p.pizza_name, COUNT(c.pizza_id) as number_pizza_ordered
from customer_orders c
join pizza_names p 
on c.pizza_id = p.pizza_id
GROUP by 1;

/* 6. What was the maximum number of pizzas delivered in a single order?*/
with count_orders as (select c.order_id, COUNT(c.pizza_id) as number_pizzas_per_order
from customer_orders c 
join runner_orders r
on c.order_id = r.order_id
and r.pickup_time != 'null'
GROUP by 1)
SELECT order_id, max(number_pizzas_per_order) as max_order
from count_orders;

/* 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?*/
SELECT c.customer_id, COUNT(CASE WHEN (exclusions != 'null' or  exclusions != '' ) OR (extras != 'null' or  extras != '' ) THEN 1 END) as pizzas_number_changed,
COUNT(CASE WHEN (exclusions = 'null' or  exclusions = '' ) and (extras = 'null' or  extras = '' ) THEN 1 END) as pizzas_number_no_changed
from customer_orders c 
join runner_orders r
on c.order_id = r.order_id
and r.pickup_time != 'null'
GROUP by 1; 

/* 8.How many pizzas were delivered that had both exclusions and extras*/
SELECT COUNT(CASE WHEN (exclusions != 'null' AND  exclusions != '' ) AND (extras != 'null' AND  extras != '' ) THEN 1 END) as pizzas_number
from customer_orders c 
join runner_orders r
on c.order_id = r.order_id
and r.pickup_time != 'null'; 

/* 9.What was the total volume of pizzas ordered for each hour of the day?*/
SELECT strftime('%H', order_time) as hour, COUNT(pizza_id) as pizzas_ordered_per_hour
from customer_orders
GROUP by 1
order by 2 DESC;

/* What was the volume of orders for each day of the week?*/
SELECT strftime('%d', order_time) as day, COUNT(DISTINCT order_id) as number_orders_per_day
from customer_orders
GROUP by 1
order by 2 DESC;