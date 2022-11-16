/* 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)*/
SELECT ((cast(strftime('%d', registration_date) as int)) + 6)/7 as day_week, count(runner_id) as numbers_runners_per_week
FROM runners
GROUP by 1;
/* 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?*/
SELECT r.runner_id, round(avg((JULIANDAY(r.pickup_time) - JULIANDAY(c.order_time))*24*60), 2) AS time_to_pickup
from customer_orders c 
join runner_orders r
on c.order_id = r.order_id
and r.pickup_time != 'null'
GROUP by 1
ORDER by 2;
/* 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?*/
SELECT c.order_id, COUNT(c.pizza_id) as count_pizza_per_order,
round((JULIANDAY(r.pickup_time) - JULIANDAY(c.order_time))*24*60, 2) as minute_prepare_order
from customer_orders c
join runner_orders r 
on c.order_id = r.order_id
and r.pickup_time != 'null'
GROUP by 1;

/* 4.What was the average distance travelled for each customer?*/
SELECT c.customer_id, round(avg(REPLACE(r.distance, 'km',''))) as average_distance
from customer_orders c 
join runner_orders r
on c.order_id = r.order_id
and r.pickup_time != 'null'
GROUP by 1
ORDER by 2;

/* 5. What was the difference between the longest and shortest delivery times for all orders?*/
WITH clean_duration as 
(SELECT  CASE
 WHEN duration LIKE '%minutes' then trim(duration, 'minutes')
 when duration like '%mins%' THEN trim(duration, 'mins')
 WHEN duration LIKE '%minute%' THEN trim(duration, 'minute')
 ELSE duration
 END as cleaned_duration
FROM runner_orders
WHERE pickup_time != 'null')

SELECT max(cleaned_duration) - min(cleaned_duration) as difference_duration
from clean_duration;
/* 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?*/
with cleaned_distance_duration as(SELECT runner_id, order_id, CASE
WHEN distance LIKE '%km%' then trim(distance, 'km')
ELSE distance
END as cleaned_distance,                            
CASE
WHEN duration LIKE '%minutes' then trim(duration, 'minutes')
when duration like '%mins%' THEN trim(duration, 'mins')
WHEN duration LIKE '%minute%' THEN trim(duration, 'minute')
ELSE duration
END as cleaned_duration
FROM runner_orders
WHERE pickup_time != 'null')                               

SELECT runner_id, order_id, round(avg(CAST((cleaned_distance * 1000) as real)/ (cleaned_duration * 60)), 2) as average_delivery_speed
from cleaned_distance_duration
group by 1,2;

/* 7. What is the successful delivery percentage for each runner?*/
with show_counts as (SELECT runner_id, COUNT(CASE WHEN pickup_time != 'null' then 1 END) as count_success_delivery,
COUNT(*) as count_all
from runner_orders 
GROUP by 1)

SELECT runner_id, (CAST(count_success_delivery as real)/count_all) * 100 as success_ratio_per_runner
from show_counts;