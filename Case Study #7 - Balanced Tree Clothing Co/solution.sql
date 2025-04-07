select * from [dbo].[product_details];
---select * from [dbo].[sales];
select * from [dbo].[product_hierarchy];
select * from [dbo].[product_prices];

---High Level Sales Analysis
---1.	What was the total quantity sold for all products?
select sum(qty) total_quantity_sold from sales;
---2.	What is the total generated revenue for all products before discounts?
select sum(qty*price) total_revenue from sales;
---3.	What was the total discount amount for all products?
select sum(qty*price* (cast(discount as float)/100)) total_discount from sales;

---Transaction Analysis
---1.	How many unique transactions were there?
select count(distinct txn_id) total_unique_transaction  from sales;
---2.	What is the average unique products purchased in each transaction?
select count(qty)/count(distinct txn_id) as avg_product from sales;
---3.	What are the 25th, 50th and 75th percentile values for the revenue per transaction?
with cte as (select distinct txn_id, sum(qty*price) revenue from sales
group by txn_id)
select distinct PERCENTILE_CONT(0.25) within group (order by revenue) over () as pct_25th,
		PERCENTILE_CONT(0.5) within group (order by revenue) over () as pct_50th,
		PERCENTILE_CONT(0.75) within group (order by revenue) over () as pct_75th
		from cte;
---4.	What is the average discount value per transaction?
select sum(qty*price* (cast(discount as float)/100)) / count(distinct txn_id) avg_discount from sales;
---5.	What is the percentage split of all transactions for members vs non-members?
select round(cast(count(distinct case when member='t' then txn_id end)*100.00 / count(distinct txn_id) as float),2) as is_member,
		round(cast(count(distinct case when member='f' then txn_id end)*100.00 / count(distinct txn_id) as float),2) as non_member
from sales;
---6.	What is the average revenue for member transactions and non-member transactions?
with cte as (select distinct txn_id, member, sum(qty*price) revenue from sales
group by txn_id, member)

select member, cast(avg(revenue*1.0) as float) revenue from cte
group by member;


---Product Analysis
---1.	What are the top 3 products by total revenue before discount?
select top 3 product_name, sum(s.qty*s.price) revenue from product_details pd
join sales s on pd.product_id=s.prod_id
group by product_name
order by revenue desc;

---2.	What is the total quantity, revenue and discount for each segment?
select segment_name, sum(s.qty) total_quantity,sum(s.qty*s.price) revenue, sum(s.qty*s.price* (cast(discount as float)/100)) total_discount from product_details pd
join sales s on pd.product_id=s.prod_id
group by segment_name;
---3.	What is the top selling product for each segment?
with cte as (select segment_name, product_name,sum(s.qty) total_quantity,sum(s.qty*s.price) revenue, sum(s.qty*s.price* (cast(discount as float)/100)) total_discount from product_details pd
join sales s on pd.product_id=s.prod_id
group by segment_name, product_name),
	cte_rank as (select *, rank() over (partition by segment_name order by total_quantity desc) rank_qty from cte)
select * from cte_rank
where rank_qty=1;
---4.	What is the total quantity, revenue and discount for each category?
select category_name, sum(s.qty) total_quantity,sum(s.qty*s.price) revenue, sum(s.qty*s.price* (cast(discount as float)/100)) total_discount from product_details pd
join sales s on pd.product_id=s.prod_id
group by category_name;
---6.	What is the percentage split of revenue by product for each segment?
with cte as (select segment_name, product_name,sum(s.qty) total_quantity,sum(s.qty*s.price) revenue, sum(s.qty*s.price* (cast(discount as float)/100)) total_discount from product_details pd
join sales s on pd.product_id=s.prod_id
group by segment_name, product_name)
select segment_name, product_name, round(cast(revenue*100.0/(sum(revenue) over (partition by segment_name ORDER BY segment_name)) as float),2) as per_revenue 
from cte;
---7.	What is the percentage split of revenue by segment for each category?
with cte as (select category_name, segment_name,sum(s.qty) total_quantity,sum(s.qty*s.price) revenue, sum(s.qty*s.price* (cast(discount as float)/100)) total_discount from product_details pd
join sales s on pd.product_id=s.prod_id
group by category_name, segment_name)
select category_name, segment_name, round(cast(revenue*100.0/(sum(revenue) over (partition by category_name ORDER BY category_name)) as float),2) as per_revenue 
from cte;
---8.	What is the percentage split of total revenue by category?
with cte as (select category_name,sum(s.qty) total_quantity,sum(s.qty*s.price) revenue, sum(s.qty*s.price* (cast(discount as float)/100)) total_discount from product_details pd
join sales s on pd.product_id=s.prod_id
group by category_name)
select category_name, round(cast(revenue*100.0/(select sum(qty*price) from sales) as float),2) as per_revenue ,
	sum(revenue) over (partition by category_name order by category_name) as total_revenue
from cte;
---9.	What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
with cte as( SELECT 
    DISTINCT s.prod_id, pd.product_name,
    COUNT(DISTINCT s.txn_id) AS product_txn,
    (SELECT COUNT(DISTINCT txn_id) FROM sales) AS total_txn
  FROM sales s
  JOIN product_details pd 
    ON s.prod_id = pd.product_id
  GROUP BY prod_id, pd.product_name)

select *, round(cast((100.0*product_txn)/total_txn as float),2) penetration from cte;
---10.	What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH CTE AS (SELECT  txn_id, p1.product_name
                FROM sales s 
                LEFT JOIN product_details  p1 ON s.prod_id = p1.product_id)

SELECT top 1
        C1.product_name AS PRODUCT_1,
        C2.product_name AS PRODUCT_2,
        C3.product_name AS PRODUCT_3,
        COUNT (*) AS time_trans
FROM CTE c1 
LEFT JOIN CTE C2 ON C1.txn_id =C2.txn_id  AND C1.product_name < c2.product_name
LEFT JOIN CTE C3 ON C1.txn_id = C3.txn_id AND C1.product_name < c3.product_name AND C2.product_name < c3.product_name
WHERE C1.product_name IS NOT NULL and C2.product_name IS NOT NULL AND C3.product_name IS NOT NULL
GROUP BY C1.product_name, C2.product_name,C3.product_name
ORDER BY time_trans DESC ;

---Bonus Challenge
/*
Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

Hint: you may want to consider using a recursive CTE to solve this problem!*/
select pp.product_id, pp.price,  
		CONCAT(ph.level_text, ' ', ph2.level_text, ' - ', ph3.level_text) AS product_name,
		ph3.id as category_id,
		ph2.id as segment_id,
		ph.id as style_id,
		ph3.level_text as category_name,
		ph2.level_text as segment_name,
		ph.level_text as style_name
from product_hierarchy ph
join product_hierarchy ph2 on ph2.id=ph.parent_id
join product_hierarchy ph3 on ph3.id= ph2.parent_id
join product_prices pp on pp.id=ph.id;