/*
to show the query in Google Big query:
https://console.cloud.google.com/bigquery?sq=640351986204:8b99ae0956cc41e59c59e9dbd603fdc5

*/
/* 1. What day of the week is used for each week_date value?*/
SELECT FORMAT_DATE("%A", week_date) as day_week
FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
limit 1;

/* 3. How many total transactions were there for each year in the dataset?*/
select calendar_year, sum(transactions) as sum_transactions
FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
group by calendar_year;

/* 4. What is the total sales for each region for each month?*/
select region, month_number, sum(sales) as sum_sales
FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
group by 1, 2;

/* 5. What is the total count of transactions for each platform*/
select platform, sum(transactions) as sum_transactions
FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
group by 1;

/* 6. What is the percentage of sales for Retail vs Shopify for each month?*/
with cte as(
  select month_number, platform, round((sum(sales)/sum(sum(sales)) over(partition by month_number))*100, 1) as percentage_sales
  FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
  group by 1, 2)

select month_number,
  sum(case when platform = "Retail" then percentage_sales else 0 end ) as retail_percentage_sales,
  sum(case when platform = "Shopify" then percentage_sales else 0 end) as shopify_percentage_sales
from cte
group by 1
order by 1;

/* 7. What is the percentage of sales by demographic for each year in the dataset?*/
with total_cte1 as(
  select calendar_year, sum(sales) as totlal_sales_y
  FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
  group by 1
),
total_cte2 as(
  select demographic, calendar_year, sum(sales) as totlal_sales_y_d
  FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
  group by 1, 2
)

select cte2.calendar_year, cte2.demographic ,round((cte2.totlal_sales_y_d/cte1.totlal_sales_y)*100, 2) as sales_percentage
FROM total_cte1 cte1
join total_cte2 cte2
on cte1.calendar_year = cte2.calendar_year;

/* another solution*/
select demographic, calendar_year, round((sum(sales)/sum(sum(sales)) over(partition by calendar_year))*100, 2) as totlal_sales_y_d
FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
group by 1, 2;


/* 8. Which age_band and demographic values contribute the most to Retail sales?*/
select age_band, demographic, sum(sales) as sum_sales, round((sum(sales)/sum(sum(sales)) over())*100, 2) as percentage
FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
where platform = "Retail"
group by 1, 2
having age_band != "unknown" and demographic != "unknown"
order by 3 desc
limit 1;

/* 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
If not - how would you calculate it instead?*/
/*- using avg of avg not accurate of data, so avg_transactions = sum(sales)/sum(transactions)*/
with avg_cte as (
  select calendar_year, platform, round(sum(sales)/sum(transactions), 2) as average_transactions_year_platform
  FROM `case-study-5-data-mart.DataMart.clean_weekly_sales`
  group by 1,2)

select calendar_year,
sum(case when platform = "Shopify" then average_transactions_year_platform else 0 end) as shopify_average_transactions,
sum(case when platform = "Retail" then average_transactions_year_platform else 0 end) as retail_average_transactions
FROM avg_cte
group by 1
order by 1;
