select cast(week_date as date) as week_date,     /* Convert the week_date to a DATE format */  
extract(month from week_date) as month_number,  /* Extract month_number from each week_date */
extract(year from week_date) as calendar_year,  /* Extract calander_year from each week_date */
region, platform, customer_type, segment,
case                                            /* Add age_band column to classify the age from segment */
  when segment like '%1' then 'Young Adults'
  when segment like '%2' then 'Middle Aged'
  when segment like '%3' or segment like '%4' then 'Retirees'
  else 'unknown'
end as age_band,
case                                            /* Add demographic column to show the peole type: couples or families from segment */
  when segment like 'C%' then 'Couples'
  when segment like 'F%' then 'Families'
  else 'unknown'
end as demographic,
transactions, sales,
round(sales/transactions, 2) as avg_transaction  /* Add  avg_transaction column*/
from `case-study-5-data-mart.DataMart.weekly_sales`;  
