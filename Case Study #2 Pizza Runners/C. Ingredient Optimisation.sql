
/* 1. What are the standard ingredients for each pizza?*/
with cte1Split(pizza_id, topping, toppings) AS(
  SELECT pizza_id, '', toppings||','
  from pizza_recipes
  UNION ALL
  SELECT 
  pizza_id,
  substr(toppings, 0, instr(toppings, ',')),
  substr(toppings, instr(toppings, ',')+1)
  FROM cte1Split
  WHERE toppings != ''
)
SELECT pn.pizza_name, GROUP_concat(pt.topping_name) as pizza_toppings
FROM cte1Split cs
JOIN pizza_names pn
on cs.pizza_id = pn.pizza_id
JOIN pizza_toppings pt
on cs.topping = pt.topping_id
WHERE topping != ''
GROUP by 1;

/**********************************************/

/* 2.What was the most commonly added extra?*/
WITH cte_extra(extra, extras) AS(
  SELECT '', extras||',' FROM customer_orders
  WHERE extras != '' and extras != 'null'
  UNION ALL
  SELECT 
  substr(extras, 0, instr(extras, ',')),
  substr(extras, instr(extras, ',')+1)
  FROM cte_extra
  WHERE extras != ''
)
SELECT pt.topping_name, COUNT(pt.topping_name) count_most_extra
from cte_extra cte
join pizza_toppings pt
on cte.extra = pt.topping_id
and extra != ''
GROUP by 1
ORDER BY 2 DESC
LIMIT 1;

/***************************************************/

/* 3.What was the most common exclusion?*/
WITH cte_exclusion(exclusion, exclusions) AS(
  SELECT '', exclusions||',' FROM customer_orders
  WHERE exclusions != '' and exclusions != 'null'
  UNION ALL
  SELECT 
  substr(exclusions, 0, instr(exclusions, ',')),
  substr(exclusions, instr(exclusions, ',')+1)
  FROM cte_exclusion
  WHERE exclusions != ''
)
SELECT pt.topping_name, COUNT(pt.topping_name) count_most_exclusion
from cte_exclusion cte
join pizza_toppings pt
on cte.exclusion = pt.topping_id
and exclusion != ''
GROUP by 1
ORDER BY 2 DESC
LIMIT 1;

/**********************************/
/* 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/

/* create first cte to apply window function: ROW_NUMBER() to customer_orders table*/
with cte_row_number AS(
  SELECT 
  	ROW_NUMBER() OVER() AS row_number,
    *
  FROM customer_orders
),
/* split exclusions for each pizza order in single record  */
cteSplit_exclusions(row_number, exclusion, exclusions) AS(
  SELECT row_number, '', exclusions||',' from cte_row_number
  WHERE exclusions != '' and exclusions != 'null'
  UNION ALL
  SELECT 
  row_number,
  substr(exclusions, 0, instr(exclusions, ',')),
  substr(exclusions, instr(exclusions, ',')+1)
  FROM cteSplit_exclusions
  WHERE exclusions != ''
),
/*group exclusions toppings names by row_number*/
group_exclusions as(
  SELECT cte.row_number, 'Exclude ' || GROUP_CONCAT(pt.topping_name) exclusions_rowNumber
  from cteSplit_exclusions cte
  join pizza_toppings pt
  on cte.exclusion = pt.topping_id
  GROUP by cte.row_number
),
/* split extras for each pizza order in single record  */
cteSplit_extras(row_number, extra, extras) AS(
  SELECT row_number, '', extras||',' from cte_row_number
  WHERE extras != '' and extras != 'null'
  UNION ALL
  SELECT
  row_number,
  substr(extras, 0, instr(extras, ',')),
  substr(extras, instr(extras, ',')+1)
  FROM cteSplit_extras
  WHERE extras != ''
),
/*group extras toppings names by row_number*/
group_extras as(
  SELECT cte.row_number, 'Extra ' || GROUP_CONCAT(pt.topping_name) as extras_rowNumber
  from cteSplit_extras cte
  join pizza_toppings pt
  on cte.extra = pt.topping_id
  GROUP by cte.row_number
),
joining_pizzaNames_table as(
  SELECT * 
  from cte_row_number cte
  join pizza_names pn
  on cte.pizza_id = pn.pizza_id
)
/*every order generate with concatenate: pizza_name + exclusions + Extras*/
SELECT cte_1.*, 
CASE
	WHEN cte_2.exclusions_rowNumber != '' and cte_3.extras_rowNumber != '' 
  		THEN cte_1.pizza_name || ' - '|| cte_2.exclusions_rowNumber || ' - '|| cte_3.extras_rowNumber
    
    WHEN cte_2.exclusions_rowNumber != ''
  		THEN cte_1.pizza_name || ' - '|| cte_2.exclusions_rowNumber
        
    WHEN cte_3.extras_rowNumber != '' 
  		THEN cte_1.pizza_name || ' - ' || cte_3.extras_rowNumber
        
    ELSE cte_1.pizza_name
  END as pizza_details
  
from joining_pizzaNames_table cte_1
left join group_exclusions cte_2
on cte_1.row_number = cte_2.row_number
left join group_extras cte_3
on cte_1.row_number = cte_3.row_number;


/* 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order 
from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
*/
with cteSplit_5(pizza_id, topping, toppings) AS(
  SELECT pizza_id, '', toppings||','
  from pizza_recipes
  UNION ALL
  SELECT 
  pizza_id,
  substr(toppings, 0, instr(toppings, ',')),
  substr(toppings, instr(toppings, ',')+1)
  FROM cteSplit_5
  WHERE toppings != ''
),
group_ingredients as(
  SELECT cte5.pizza_id, '"' || pn.pizza_name || ': ' ||
  GROUP_CONCAT(CASE
    WHEn pt.topping_name = 'Bacon' OR pt.topping_name = 'Cheese' THEN '2x'||pt.topping_name 
    ELSE pt.topping_name
  END ) || '"' as pizza_ingredients
  FROM pizza_toppings as pt
  JOIN cteSplit_5 as cte5
  on pt.topping_id = cte5.topping
  JOIN pizza_names pn
  on cte5.pizza_id = pn.pizza_id
  GROUP by pn.pizza_id)
  
SELECT c.*, g.pizza_ingredients
from customer_orders c
join group_ingredients g
on c.pizza_id = g.pizza_id;

/* 6. What is the total quantity of each ingredient used in all delivered pizzas 
sorted by most frequent first?*/
/* make first CTE to filter only the delivered orders successfuly*/
with delivered_orders AS(
  SELECT * FROM customer_orders c
  JOIN runner_orders r 
  on c.order_id = r.order_id
  and r.pickup_time != 'null'),

/* join every pizza order with its topping */
join_toppings as(
  SELECT * 
  from delivered_orders d
  join pizza_recipes pr
  on d.pizza_id = pr.pizza_id
),

/*split every pizza topping to multi records: every single record has only one topping*/
cteSplit_topping(pizza_id, topping, toppings) AS(
  SELECT pizza_id, '', toppings||',' from join_toppings
  UNION ALL
  SELECT
  pizza_id,
  substr(toppings, 0, instr(toppings, ',')),
  substr(toppings, instr(toppings, ',')+1)
  FROM cteSplit_topping
  WHERE toppings != ''
),

/*join every pizaa with topping_id and topping_name
Ex : 1  1 Bacon
*/
cte_toppings as(
  SELECT cte_t.pizza_id, cte_t.topping, pt.topping_name
  from cteSplit_topping cte_t
  join pizza_toppings pt
  on cte_t.topping = pt.topping_id
  and cte_t.topping != ''
),

/* count the occurence of each topping*/
count_toppings AS(
  SELECT topping, COUNT(topping) as count_toppings
  from cte_toppings
  GROUP by 1
),
/*****************/
/* split exclusions for each pizza order in single record  */
cteSplit_exclusions(exclusion, exclusions) AS(
  SELECT '', exclusions||',' from customer_orders
  WHERE exclusions != '' and exclusions != 'null'
  UNION ALL
  SELECT 
  substr(exclusions, 0, instr(exclusions, ',')),
  substr(exclusions, instr(exclusions, ',')+1)
  FROM cteSplit_exclusions
  WHERE exclusions != ''
),

/*count the occurrence of each exclusion & multipy by -1 
when gus sum number of used each topping need to subtraxt the exclusion*/
count_exclusions AS(
  SELECT exclusion, COUNT(exclusion) * -1 as count_exclusions
  FROM cteSplit_exclusions
  WHERE exclusion != ''
  GROUP by 1
),

/* split extras for each pizza order in single record  */
cteSplit_extras(extra, extras) AS(
  SELECT '', extras||',' from customer_orders
  WHERE extras != '' and extras != 'null'
  UNION ALL
  SELECT 
  substr(extras, 0, instr(extras, ',')),
  substr(extras, instr(extras, ',')+1)
  FROM cteSplit_extras
  WHERE extras != ''
), 

/*count the occurrence of every extra orderd with pizza*/
count_extras as(
  SELECT extra, COUNT(extra) as count_extras
  FROM cteSplit_extras
  WHERE extra != ''
  GROUP by 1),

/*union all CTEs of count*/
union_ctes as (
  SELECT * from count_toppings
  UNION ALL 
  select * from count_exclusions
  UNION ALL
  SELECT * from count_extras)
   
/*sum the number of used every topping:
(topping with pizza delivered + topping when ordered as extra - topping when orded to be excluded)*/  
SELECT pt.topping_name, sum(ctes.count_toppings) as topping_times_used
from union_ctes ctes
JOIN pizza_toppings pt
on ctes.topping = pt.topping_id
GROUP by pt.topping_name
ORDER by 2 DESC;
