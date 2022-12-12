/*
to show query in Google BigQuery:
https://console.cloud.google.com/bigquery?sq=640351986204:aa59444c47d34f28a46801be7346c8f7
*/

/* Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
region
platform
age_band
demographic
customer_type*/
/* first need to extract week number from base date*/
select DISTINCT extract(WEEK FROM DATE "2020-06-15") AS week_number,
       extract(YEAR FROM DATE "2020-06-15") AS year
FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`;

with cte as(
  select
    week_date, 
    calendar_year,
    extract(WEEK FROM  week_date) as week_number,
    region, platform, age_band, demographic, customer_type,
    sales
    FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
),
region_impact as(select 
  region,
  sum(case when week_number between 12 and 24 AND calendar_year = 2020 then sales else 0 end) as sum_sales_before_change,
  sum(case when week_number between 25 and 37 AND calendar_year = 2020 then sales else 0 end) as sum_sales_after_change
from cte
group by 1
order by 3
limit 1),
platform_impact as(select 
  platform,
  sum(case when week_number between 12 and 24 AND calendar_year = 2020 then sales else 0 end) as sum_sales_before_change,
  sum(case when week_number between 25 and 37 AND calendar_year = 2020 then sales else 0 end) as sum_sales_after_change
from cte
group by 1
order by 3
limit 1),
age_band_impact as(select 
  age_band,
  sum(case when week_number between 12 and 24 AND calendar_year = 2020 then sales else 0 end) as sum_sales_before_change,
  sum(case when week_number between 25 and 37 AND calendar_year = 2020 then sales else 0 end) as sum_sales_after_change
from cte
group by 1
order by 3
limit 1),
demographic_impact as(select 
  demographic,
  sum(case when week_number between 12 and 24 AND calendar_year = 2020 then sales else 0 end) as sum_sales_before_change,
  sum(case when week_number between 25 and 37 AND calendar_year = 2020 then sales else 0 end) as sum_sales_after_change
from cte
group by 1
order by 3
limit 1),
customer_type_impact as(select 
  customer_type,
  sum(case when week_number between 12 and 24 AND calendar_year = 2020 then sales else 0 end) as sum_sales_before_change,
  sum(case when week_number between 25 and 37 AND calendar_year = 2020 then sales else 0 end) as sum_sales_after_change
from cte
group by 1
order by 3
limit 1)

select *, round((sum_sales_after_change - sum_sales_before_change)/sum_sales_before_change, 2) as economic_change_rate
from region_impact
union all
select *, round((sum_sales_after_change - sum_sales_before_change)/sum_sales_before_change, 2)
from platform_impact
union all
select *, round((sum_sales_after_change - sum_sales_before_change)/sum_sales_before_change, 2)
from age_band_impact
union all
select *, round((sum_sales_after_change - sum_sales_before_change)/sum_sales_before_change, 2) 
from demographic_impact
union all
select *, round((sum_sales_after_change - sum_sales_before_change)/sum_sales_before_change, 2)
from customer_type_impact;

/* I show number of sales decreases and every area of business has negative impact
so my recommendation to Danny to rollback about this change
*/
