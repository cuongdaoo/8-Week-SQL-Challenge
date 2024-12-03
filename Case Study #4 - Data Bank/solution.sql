select * from [dbo].[regions];
select * from [dbo].[customer_nodes];
select * from [dbo].[customer_transactions];

--A. Customer Nodes Exploration
-- 1.	How many unique nodes are there on the Data Bank system?
select count(distinct node_id) unique_node 
from customer_nodes;
-- 2.	What is the number of nodes per region?
select region_name, count(node_id) node 
from customer_nodes c
join regions  r on c.region_id=r.region_id
group by region_name
order by node desc;
-- 3.	How many customers are allocated to each region?
select region_name, count(distinct customer_id) cus 
from customer_nodes c
join regions  r on c.region_id=r.region_id
group by region_name
order by cus desc;
-- 4.	How many days on average are customers reallocated to a different node?
with first_date_table as (select customer_id,region_id, node_id, min(start_date) first_date 
from customer_nodes
group by customer_id,region_id, node_id),
	reallocated_table as(select customer_id,region_id, node_id, first_date, 
	DATEDIFF(day, first_date, lead(first_date) over (partition by customer_id order by first_date)) as moving_date  
	from first_date_table)
select avg(moving_date*1.00) avg_moving_days  from reallocated_table;
-- 5.	What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with first_date_table as (select customer_id,region_id, node_id, min(start_date) first_date 
from customer_nodes
group by customer_id,region_id, node_id),
	reallocated_table as(select customer_id,region_id, node_id, first_date, 
	DATEDIFF(day, first_date, lead(first_date) over (partition by customer_id order by first_date)) as moving_date  
	from first_date_table)
select distinct region_name, 
		PERCENTILE_CONT(0.5) WITHIN GROUP ( ORDER BY moving_date) OVER ( partition by reallocated_table.region_id) as median,
		PERCENTILE_CONT(0.8) WITHIN GROUP ( ORDER BY moving_date) OVER ( partition by reallocated_table.region_id) as per_80th,
		PERCENTILE_CONT(0.95) WITHIN GROUP ( ORDER BY moving_date) OVER ( partition by reallocated_table.region_id) as per_95th
from reallocated_table
join regions on reallocated_table.region_id=regions.region_id;

--B. Customer Transactions
-- 1.	What is the unique count and total amount for each transaction type?
select txn_type, count(txn_type) unique_count, sum(txn_amount) total_amount
from customer_transactions
group by txn_type;
-- 2.	What is the average total historical deposit counts and amounts for all customers?
with cte as (select customer_id, count(customer_id) txn_count, avg(txn_amount) avg_amount
from customer_transactions
where txn_type='deposit'
group by customer_id)
select round(avg(txn_count)*1.00,2) avg_deposit_count,
		round(avg(avg_amount)*1.00,2) avg_deposit_amt
from cte;
-- 3.	For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with cte as (select customer_id, DATEPART(month,txn_date) monthtx,
					sum(case when txn_type='deposit' then 1 else 0 end) de_amount,
					sum(case when txn_type='withdrawal' then 1 else 0 end) wi_amount,
					sum(case when txn_type='purchase' then 1 else 0 end) pu_amount
from customer_transactions
group by customer_id, DATEPART(month,txn_date))

select monthtx, count(*) amount_customer  from cte
where de_amount > 1 and (pu_amount > 1 or wi_amount > 1)
group by monthtx;
-- 4.	What is the closing balance for each customer at the end of the month?
with cte as (select customer_id, DATEPART(month,txn_date) monthtx,
					sum(case when txn_type='deposit' then txn_amount else 0 end) de_amount,
					sum(case when txn_type='withdrawal' then -txn_amount else 0 end) wi_amount,
					sum(case when txn_type='purchase' then -txn_amount else 0 end) pu_amount
from customer_transactions
group by customer_id, DATEPART(month,txn_date)),
	cte2 as (select customer_id, monthtx, de_amount+pu_amount+wi_amount as amount_balance  from cte),
	cte3 as (select customer_id, monthtx, amount_balance, 
										lag(amount_balance) over (partition by customer_id order by customer_id) amount_pre_monthtx 
										from cte2)
select customer_id, monthtx, amount_balance,
							case when amount_pre_monthtx is null then amount_balance else amount_balance-amount_pre_monthtx end as closeing_balance
from cte3;
	
-- 5.	What is the percentage of customers who increase their closing balance by more than 5%?
with cte as (select customer_id, DATEPART(month,txn_date) monthtx,
					sum(case when txn_type='deposit' then txn_amount else 0 end) de_amount,
					sum(case when txn_type='withdrawal' then -txn_amount else 0 end) wi_amount,
					sum(case when txn_type='purchase' then -txn_amount else 0 end) pu_amount
from customer_transactions
group by customer_id, DATEPART(month,txn_date)),
	cte2 as (select customer_id, monthtx, de_amount+pu_amount+wi_amount as amount_balance  from cte),
	cte3 as (select customer_id, monthtx, amount_balance, 
										FIRST_VALUE(amount_balance) over (partition by customer_id order by customer_id) first_amount,
										LAST_VALUE(amount_balance) over (partition by customer_id order by customer_id) last_amount
										from cte2),
	cte4 as ( select *, ((last_amount-first_amount)*100/abs(first_amount)) grow_rate from cte3
				where ((last_amount-first_amount)*100/abs(first_amount))>5 and last_amount>first_amount)

select cast(count(distinct customer_id) as float)*100 / (select cast(count(distinct customer_id) as float) from customer_transactions) as "percentage of customers who increase their closing balance by more than 5%"  
from cte4
