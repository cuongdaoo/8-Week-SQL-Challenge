select * from [dbo].[plans];
select * from [dbo].[subscriptions];

-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
--B. Data Analysis Questions
-- 1.	How many customers has Foodie-Fi ever had?
select count(distinct customer_id) unique_customers from subscriptions;
-- 2.	What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select month(start_date) months,count(price) monthly_distribute from subscriptions s 
join plans p on p.plan_id=s.plan_id
where plan_name='trial'
group by month(start_date);

-- 3.	What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select plan_name,count(*) distribute from subscriptions s 
join plans p on p.plan_id=s.plan_id
where year(start_date)>2020
group by plan_name;
-- 4.	What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select plan_name,count(*) distribute ,round(count(*)*100.0/((select count(distinct customer_id) e from subscriptions)),1) "percentage of customers"
from subscriptions s 
join plans p on p.plan_id=s.plan_id
where plan_name='churn'
group by plan_name;
-- 5.	How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cte as(SELECT 
s.customer_id,
s.start_date,
p.plan_name,
LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id)
select count(*)"customers have churned straight after their initial free trial", round(100*count(*)/((select count(distinct customer_id) e from subscriptions)),0) "percentage of customers" from cte
where plan_name='trial' and next_plan='churn';
-- 6.	What is the number and percentage of customer plans after their initial free trial?
with cte as(SELECT 
s.customer_id,
s.start_date,
p.plan_name,
LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id)
select next_plan, count(*)"customers after their initial free trial", round(100*count(*)/((select count(distinct customer_id) e from subscriptions)),0) "percentage of customers" from cte
where plan_name='trial' and next_plan is not null
group by next_plan;
-- 7.	What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with cte as(SELECT 
s.customer_id,
s.start_date,
p.plan_id,
p.plan_name,
LEAD(s.start_date) OVER(PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id)

select plan_name, count(*) customers, round(CAST(100*COUNT(*) AS FLOAT)/((select count(distinct customer_id) e from subscriptions)),1) percentage  from cte
where (next_date is not null and (start_date< '2020-12-31' and next_date > '2020-12-31')) or
		(next_date is null and start_date >'2020-12-31')
group by plan_name;
-- 8.	How many customers have upgraded to an annual plan in 2020?
select count(distinct customer_id) customer_2020_proannual from subscriptions s
join plans p on p.plan_id=s.plan_id
where plan_name='pro annual' and year(start_date)=2020;
-- 9.	How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with trialplan as ( select customer_id, start_date as trial_date from subscriptions s
join plans p on p.plan_id=s.plan_id
where plan_name='trial' ),
		annualplan as ( select customer_id, start_date as annual_date from subscriptions s
join plans p on p.plan_id=s.plan_id
where plan_name='pro annual')

select avg(cast(DATEDIFF(d,trial_date,annual_date) as float)) avg_date from trialplan t 
join annualplan a on t.customer_id=a.customer_id;

-- 10.	Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with trialplan as ( select customer_id, start_date as trial_date from subscriptions s
join plans p on p.plan_id=s.plan_id
where plan_name='trial' ),
		annualplan as ( select customer_id, start_date as annual_date from subscriptions s
join plans p on p.plan_id=s.plan_id
where plan_name='pro annual'),
	 dateif as (select t.customer_id, DATEDIFF(d,trial_date,annual_date) diff from trialplan t 
join annualplan a on t.customer_id=a.customer_id),
	cte as (select 0 as start_period, 30 as end_period
					union all
			select end_period+1 as start_period, end_period+30 as end_period
			from cte
			where end_period<360)
select start_period, end_period, count(*) from cte
join dateif d on d.diff>=start_period and d.diff <=end_period
group by start_period, end_period;

-- 11.	How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with pro_month as ( select customer_id, start_date as pro_month_date from subscriptions s
join plans p on p.plan_id=s.plan_id
where plan_name='pro monthly' ),
		basic_month as ( select customer_id, start_date as basic_month_date from subscriptions s
join plans p on p.plan_id=s.plan_id
where plan_name='basic monthly')
select count(*) pro_to_basic_monthly from pro_month p
join basic_month b on p.customer_id=b.customer_id and pro_month_date < basic_month_date
where year(pro_month_date) =2020 and year(basic_month_date)=2020;


---
with cte as(
select customer_id, s.plan_id, plan_name,start_date as payment_date, 
		case when lead(start_date) over (partition by customer_id order by start_date) is null
		then '2020-12-31'
		else dateadd(month, datediff(month,start_date, lead(start_date) over (partition by customer_id order by start_date)),start_date) END AS last_date,
		price as amount
from subscriptions s
join plans p on s.plan_id=p.plan_id
where plan_name !='trial' and year(start_date)=2020

union all

select customer_id, plan_id, plan_name, DATEADD(month, 1, payment_date) as payment_date, last_date, amount
from cte
where DATEADD(MONTH, 1, payment_date)<=last_date and plan_name !='pro annual')

select 
  customer_id,
  plan_id,
  plan_name,
  payment_date,
  amount,
  ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date) AS payment_order 
from cte
where amount is not null
order by customer_id;
