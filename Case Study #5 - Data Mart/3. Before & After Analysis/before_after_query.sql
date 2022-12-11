/* To show query in Google BigQuery:
https://console.cloud.google.com/bigquery?sq=640351986204:ac98fb1d9eaf4d2eb690d61b6d4acebd
*/

/* 1. What is the total sales for the 4 weeks before and after 2020-06-15? 
What is the growth or reduction rate in actual values and percentage of sales?*/
select DISTINCT extract(WEEK FROM DATE "2020-06-15") AS week_number,
       extract(YEAR FROM DATE "2020-06-15") AS year
FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`;


with cte_week_number as(
  select
    week_date, 
    calendar_year,
    extract(WEEK FROM  week_date) as week_number,
    sales
    FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
)

select 
  sum(case when week_number between 20 and 24 AND calendar_year = 2020 then sales else 0 end) as sum_sales_before,
  sum(case when week_number between 25 and 29 AND calendar_year = 2020 then sales else 0 end) as sum_sales_after
from cte_week_number;


/* 2. What about the entire 12 weeks before and after?*/
with cte_week_number as(
  select
    week_date, 
    calendar_year,
    extract(WEEK FROM  week_date) as week_number,
    sales
    FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
),
sum_sales as(select 
  sum(case when week_number between 12 and 24 AND calendar_year = 2020 then sales else 0 end) as sum_sales_before,
  sum(case when week_number between 25 and 37 AND calendar_year = 2020 then sales else 0 end) as sum_sales_after
from cte_week_number)

select
  sum_sales_before, sum_sales_after,
  round((sum_sales_after-sum_sales_before)/sum_sales_before, 2) as economic_rate,
  (round((sum_sales_after-sum_sales_before)/sum_sales_before, 2) * 100) as percentage
from sum_sales;

/*3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?*/
with cte_week_number as(
  select
    week_date, 
    calendar_year,
    extract(WEEK FROM  week_date) as week_number,
    sales
    FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
),
sum_sales as(select 
  calendar_year,
  sum(case when week_number between 12 and 24  then sales else 0 end) as sum_sales_before,
  sum(case when week_number between 25 and 37  then sales else 0 end) as sum_sales_after
from cte_week_number
group by 1)

select *,
  round((sum_sales_after-sum_sales_before)/sum_sales_before, 2) as economic_rate,
  round((sum_sales_after-sum_sales_before)/sum_sales_before, 2) * 100 as percentage
from sum_sales;
