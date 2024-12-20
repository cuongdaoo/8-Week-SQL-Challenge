# Challenge Case Study 2: Pizza Runner

# **Relationship Diagram**
![image](https://github.com/user-attachments/assets/54e00f61-c2ae-458d-82d6-d26569dd6975)



# **Data preview**
Runners table:
\
![image](https://github.com/user-attachments/assets/03870aa1-a55a-424e-8c5f-e29bd93211bf)
\
Customer orders table:
\
![image](https://github.com/user-attachments/assets/f703ab34-6ec7-4a7b-abef-3e1b77fc8760)
\
Runner order table:
\
![image](https://github.com/user-attachments/assets/36409e5d-bb2b-4f7d-beb5-eaa68c220269)
\
Pizza name table:
\
![image](https://github.com/user-attachments/assets/20759211-af28-499f-a23a-ba21d4759041)
\
Pizza recipes table:
\
![image](https://github.com/user-attachments/assets/945afaed-242d-4d8d-8402-2e1551409414)
\
Pizza topping table:
\
![image](https://github.com/user-attachments/assets/10bd1ef7-641e-49a8-982a-8512c4aca1b1)
# **Data cleaning**
```sql
--Cleaning
SELECT
  [order_id],   
  [customer_id],   
  [pizza_id],   
  CASE
    WHEN exclusions IS NULL OR
      exclusions LIKE 'null' THEN ' '
    ELSE exclusions
  END AS exclusions,
  CASE
    WHEN extras IS NULL OR
      extras LIKE 'null' THEN ' '
    ELSE extras
  END AS extras,
  [order_time] INTO Updated_customer_orders
FROM [customer_orders];

select * from Updated_customer_orders;

create table updated_runner_orders
(
[order_id] int,
[runner_id] int,
[pickup_time] datetime,
[distance] float,
[duration] int,
[cancellation] varchar(23)
);

insert into updated_runner_orders 
select 
  order_id, 
  runner_id, 
  case when pickup_time LIKE 'null' then null else pickup_time end as pickup_time, 
  case when distance LIKE 'null' then null else trim(
    REPLACE(distance, 'km', '')
  ) end as distance, 
  case when duration LIKE 'null' then null else trim(
    REPLACE(
      duration, 
      substring(duration, 3, 10), 
      ''
    )
  ) end as duration, 
  CASE WHEN cancellation IN ('null', 'NaN', '') THEN null ELSE cancellation END AS cancellation 
from 
  [runner_orders];

ALTER TABLE  [dbo].[updated_runner_orders]
ALTER COLUMN pickup_time DATETIME

ALTER TABLE [dbo].[updated_runner_orders]
ALTER COLUMN distance FLOAT

ALTER TABLE [dbo].[updated_runner_orders]
ALTER COLUMN duration INT;

ALTER TABLE pizza_names
ALTER COLUMN pizza_name VARCHAR(MAX);

ALTER TABLE pizza_recipes
ALTER COLUMN toppings VARCHAR(MAX);

ALTER TABLE pizza_toppings
ALTER COLUMN topping_name VARCHAR(MAX)
```
**After cleaning**:
\
Updated_customer_orders table:
\
![image](https://github.com/user-attachments/assets/baeeb6da-14c6-4daa-8100-eae03b102026)
\
updated_runner_orders table:
\
![image](https://github.com/user-attachments/assets/5c177c49-4abd-4881-a900-d3713743eb01)

# **Solutions**

## A. Pizza Metrics

**1. How many pizzas were ordered?**
Idea: Calculate the total number of pizzas in the customer orders.

```sql
select count(*) pizza_count from customer_orders;
```
Output:
\
![image](https://github.com/user-attachments/assets/f853c311-6fdb-41c4-9e1f-ae2b8867d322)

**2. How many unique customer orders were made?**
Idea: Find the number of distinct orders from the updated runner orders table.

```sql
select Count(order_id) "orders were made" from updated_runner_orders;
```
Output:
\
![image](https://github.com/user-attachments/assets/860f698d-9001-4106-b4db-5448051bc5d9)

**3. How many successful orders were delivered by each runner?**
Idea: Count the non-canceled orders for each runner.

```sql
select runner_id, COUNT(order_id) success_order 
from updated_runner_orders
where cancellation is null
group by runner_id;
```
Output:
\
![image](https://github.com/user-attachments/assets/d03a301d-40b4-44f7-abec-2de6d2faf6a6)

**4. How many of each type of pizza was delivered?**
Idea: Calculate the total deliveries for each pizza type by joining customer orders and runner orders.

```sql
select pizza_id, count(*) "pizza was delivered" 
from Updated_customer_orders uc
join updated_runner_orders ur on uc.order_id = ur.order_id
where pickup_time is not null
group by pizza_id;
```
Output:
\
![image](https://github.com/user-attachments/assets/f409e243-7406-4323-890f-3e4770b1dd44)

**5. How many Vegetarian and Meatlovers were ordered by each customer?**
Idea: Classify orders by pizza type and group them by customers.

```sql
with c as (
  select customer_id, 
         case when pizza_name='Meatlovers' then 1 else 0 end as meat, 
         case when pizza_name='Vegetarian' then 1 else 0 end as veget 
  from Updated_customer_orders uc
  join pizza_names pn on uc.pizza_id = pn.pizza_id
)
select customer_id, sum(meat) meat_lover, sum(veget) veget_lover 
from c
group by customer_id;
```
Output:
\
![image](https://github.com/user-attachments/assets/d1ed0e17-bdd1-4d14-a8eb-00764d87fbaf)

**6. What was the maximum number of pizzas delivered in a single order?**
Idea: Find the highest count of pizzas in any single order.

```sql
with c as (
  select order_id, count(pizza_id) amount 
  from Updated_customer_orders
  group by order_id
)
select max(amount) "maximum number of pizzas delivered in a single order" 
from c;
```
Output:
\
![image](https://github.com/user-attachments/assets/c38a4039-666f-43f8-8856-d123220efc20)

**7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**
Idea: Group pizza orders with or without changes per customer.

```sql
select customer_id, 
       SUM(CASE WHEN c.exclusions <> ' ' OR c.extras <> ' ' THEN 1 ELSE 0 END) AS Changes,
       SUM(CASE WHEN c.exclusions = ' ' AND c.extras = ' ' THEN 1 ELSE 0 END) AS No_changes
from Updated_customer_orders c
join updated_runner_orders r on c.order_id = r.order_id
where cancellation is null
group by customer_id;
```
Output:
\
![image](https://github.com/user-attachments/assets/58ecd17a-ae6c-4fdf-86c9-b937a1480ec0)


**8. How many pizzas were delivered that had both exclusions and extras?**
Idea: Count the pizzas with both exclusions and extras.

```sql
select SUM(CASE WHEN c.exclusions <> ' ' and c.extras <> ' ' THEN 1 ELSE 0 END) AS Changes
from Updated_customer_orders c
join updated_runner_orders r on c.order_id = r.order_id
where cancellation is null;
```
Output:
\
![image](https://github.com/user-attachments/assets/fcd9df94-0c6f-40b2-8324-b9d6faedb82c)

**9. What was the total volume of pizzas ordered for each hour of the day?**
Idea: Group and count pizza orders by the hour of the day.

```sql
select DATEPART(hour, order_time) hours, count(*) Pizza_Ordered_Count 
from Updated_customer_orders
group by DATEPART(hour, order_time);
```
Output:
\
![image](https://github.com/user-attachments/assets/4af7df83-6336-4f9d-ad8e-ca6cc3d992dd)

**10. What was the volume of orders for each day of the week?**
Idea: Group and count pizza orders by the day of the week.

```sql
select DATENAME(WEEKDAY, order_time), count(*) Pizza_Ordered_Count 
from Updated_customer_orders
group by DATENAME(WEEKDAY, order_time);
```
Output:
\
![image](https://github.com/user-attachments/assets/b696d49b-38b6-4fad-b265-8b8ecfb1d940)

## B. Runner and Customer Experience
**1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)**
**Idea:** We group runners by specific 1-week periods starting from a given date.
```sql
select case 
	WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN '2021-01-01'
    WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-14' THEN '2021-01-08'
    WHEN registration_date BETWEEN '2021-01-15' AND '2021-01-21' THEN '2021-01-15'
  END AS "Week Start Period", count(runner_id) as cnt 
from runners
group by case 
	WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN '2021-01-01'
    WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-14' THEN '2021-01-08'
    WHEN registration_date BETWEEN '2021-01-15' AND '2021-01-21' THEN '2021-01-15'
  END;
```
Output: \
![image](https://github.com/user-attachments/assets/ca87e00a-1e08-4e43-ac2d-71668a7eaf99)
  
**2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?**
**Idea:** Calculate the average time taken for runners to reach HQ after receiving an order.
```sql
select runner_id, avg(datepart(minute, pickup_time - order_time)) avg_time 
from updated_runner_orders r
join Updated_customer_orders o on o.order_id = r.order_id
where duration is not null
group by runner_id;
```
Output: \
![image](https://github.com/user-attachments/assets/a706e2d8-d6ac-40a5-bc5d-eb2111b13c06)

**3. Is there any relationship between the number of pizzas and how long the order takes to prepare?**
**Idea:** Compare the average preparation time against the number of pizzas in each order.
```sql
with preparetime as (
  select r.order_id, datepart(minute, pickup_time - order_time) time 
  from updated_runner_orders r
  join Updated_customer_orders o on o.order_id = r.order_id
  where pickup_time is not null
),
ordertime as (
  select order_id, order_time, count(pizza_id) amount 
  from Updated_customer_orders
  group by order_id, order_time
)
select amount, avg(time) avg_pre_time 
from preparetime p
join ordertime o on p.order_id = o.order_id
group by amount;
```
Output: \
![image](https://github.com/user-attachments/assets/5aafa15a-aba9-401e-a1d8-299201241d3e)

**4. What was the average distance traveled for each customer?**
**Idea:** Calculate the average delivery distance for each customer.
```sql
select customer_id, avg(distance) avg_distance 
from Updated_customer_orders c
join updated_runner_orders r on c.order_id = r.order_id
group by customer_id;
```
Output: \
![image](https://github.com/user-attachments/assets/4d48b432-b05c-4668-897f-cadd1c155e84)

**5. What was the difference between the longest and shortest delivery times for all orders?**
**Idea:** Find the maximum and minimum delivery times, then calculate the difference.
```sql
select max(duration) - min(duration) 
"Difference between the longest and shortest delivery times for all orders" 
from updated_runner_orders;
```
Output: \
![image](https://github.com/user-attachments/assets/ad1fb069-5e6c-4a88-8ae8-c0ff27a7df37)

**6. What was the average speed for each runner for each delivery and do you notice any trend for these values?**
**Idea:** Calculate the delivery speed of each runner and check for trends in the values.
```sql
with ordertime as (
  select order_id, order_time, count(pizza_id) amount 
  from Updated_customer_orders
  group by order_id, order_time
),
speed as (
  select order_id, runner_id, round((60 * distance / duration), 2) speed_km 
  from updated_runner_orders 
  where cancellation is null
)
select runner_id, amount, speed_km, 
       avg(speed_km) over (partition by runner_id) avg_time_runner 
from speed r
join ordertime o on o.order_id = r.order_id;
```
Output: \
![image](https://github.com/user-attachments/assets/1dcee408-f326-42cb-b483-25274841fd30)

**7. What is the successful delivery percentage for each runner?**
**Idea:** Calculate the percentage of successful deliveries (where pickup time is present) for each runner.
```sql
select runner_id, 
       round(100 * count(pickup_time) / count(order_id), 0) 
       "successful delivery percentage" 
from updated_runner_orders
group by runner_id;
```
Output: \
![image](https://github.com/user-attachments/assets/447d9f0d-4527-4e7e-af25-76a27cb86293)

## C. Ingredient Optimisation

**1. What are the standard ingredients for each pizza?**  
Idea: Retrieve the list of toppings for each pizza and combine them into a single string.
```sql
with cte as(select pizza_id,value as topping_id
		 from pizza_recipes
		cross apply string_split (toppings,',')),
		irg as( select pizza_id, topping_name from pizza_toppings pt
		join cte on cte.topping_id=pt.topping_id)
select pizza_name, STRING_AGG(topping_name,',') as topping_name from pizza_names pn
join irg on irg.pizza_id= pn.pizza_id
group by pizza_name;
```
Output:  
\
![image](https://github.com/user-attachments/assets/a6982b7e-c83c-4c89-b097-ba80d1c14090)


**2. What was the most commonly added extra?**  
Idea: Find the most frequently added extra topping by counting occurrences of extra toppings.
```sql
with extra as(select value as topping_id from Updated_customer_orders
				cross apply string_split(extras,','))
select top 1 topping_name, count(extra.topping_id) added_extras_count from pizza_toppings pt
join extra on extra.topping_id=pt.topping_id
group by topping_name
order by added_extras_count desc;
```
Output:  
\
![image](https://github.com/user-attachments/assets/bf9fe84f-1973-41bd-a6c9-8eac2e05f24a)


**3. What was the most common exclusion?**  
Idea: Identify the topping that customers most frequently exclude from their orders.
```sql
with extra as(select value as topping_id from Updated_customer_orders
				cross apply string_split(exclusions,','))
select top 1 topping_name, count(extra.topping_id) added_extras_count from pizza_toppings pt
join extra on extra.topping_id=pt.topping_id
group by topping_name
order by added_extras_count desc;
```
Output:  
\
![image](https://github.com/user-attachments/assets/be5c450b-582b-41e1-94e6-aeccb93a95e5)


**4. Generate an order item for each record in the customers_orders table**  
Idea: Create a descriptive label for each order, showing any excluded or extra toppings.
```sql
with up_row as(select *,ROW_NUMBER() over(order by order_id asc) as reorder_id from Updated_customer_orders),
	exclu as (select reorder_id, order_id,customer_id,pizza_id, split1.value as topping_id_exclu from up_row
				cross apply string_split(exclusions,',') as split1),
	all_exclu as (select  reorder_id,order_id,customer_id,pizza_name, string_agg(topping_id_exclu,',') exclusions, string_agg(pt1.topping_name,',') as topping_exclu_name from exclu 
					left join pizza_names on exclu.pizza_id= pizza_names.pizza_id
					left join pizza_toppings pt1 on exclu.topping_id_exclu=pt1.topping_id
					group by reorder_id,order_id,customer_id,pizza_name),
	extra as (select reorder_id, order_id,customer_id,pizza_id, split2.value as topping_id_extra from up_row
				cross apply string_split(extras,',') as split2),
	all_extra as (select  reorder_id,order_id,customer_id,pizza_name, string_agg(topping_id_extra,',') extras, string_agg(pt2.topping_name,',') as topping_extra_name from extra 
					left join pizza_names on extra.pizza_id= pizza_names.pizza_id
					left join pizza_toppings pt2 on extra.topping_id_extra=pt2.topping_id
					group by reorder_id,order_id,customer_id,pizza_name),
	final as (select all_exclu.reorder_id,all_exclu.order_id,all_exclu.customer_id,all_exclu.pizza_name, topping_exclu_name, topping_extra_name from all_exclu
				join all_extra on all_extra.reorder_id=all_exclu.reorder_id)
select reorder_id,order_id, pizza_name, case when pizza_name is not null and topping_exclu_name is null and topping_extra_name is null then pizza_name
	     when pizza_name is not null and topping_exclu_name is not null and topping_extra_name is not null then concat(pizza_name,' - ','Exclude ',topping_exclu_name,' - ','Extra ',topping_extra_name)
		 when pizza_name is not null and topping_exclu_name is null and topping_extra_name is not null then concat(pizza_name,' - ','Extra ',topping_exclu_name)
		 when pizza_name is not null and topping_exclu_name is not null and topping_extra_name is null then concat(pizza_name,' - ','Exclude ',topping_exclu_name)
	 end as order_item
from final
order by reorder_id,order_id, pizza_name;
```
Output:  
\
![image](https://github.com/user-attachments/assets/471a2ae5-be2c-4abe-9e32-892179cbaf33)


**5. Generate an alphabetically ordered comma-separated ingredient list for each pizza order**  
Idea: List ingredients alphabetically for each pizza order, prepending "2x" to duplicates.
```sql
with up_row as(select *,ROW_NUMBER() over(order by order_id asc) as reorder_id from Updated_customer_orders),
	cte as(select reorder_id, order_id,customer_id,c.pizza_id,toppings, exclusions,value as topping_id_extra  from up_row c left join pizza_recipes pr on pr.pizza_id=c.pizza_id
				cross apply string_split(extras,',')),
	cte2 as(select reorder_id,order_id,customer_id,pizza_id,toppings, exclusions,topping_name as topping_name_extra, value as topping_id_all from cte left join pizza_toppings on cte.topping_id_extra=pizza_toppings.topping_id
	cross apply string_split(toppings,',')),
	cte3 as(select reorder_id,order_id,customer_id,pizza_id,toppings, exclusions,topping_name_extra, topping_name as topping_name_all, case when topping_name_extra=topping_name then 'X2'+topping_name_extra else topping_name end as topping
	from cte2 left join pizza_toppings on cte2.topping_id_all=pizza_toppings.topping_id)
select reorder_id,order_id, customer_id ,pizza_id, toppings, exclusions,STRING_AGG(topping,',') topping_name from cte3
group by reorder_id,order_id, customer_id ,pizza_id, toppings, exclusions
order by order_id asc;
```
Output:  
\
![image](https://github.com/user-attachments/assets/b27b5148-96ad-4f9f-9456-6a72a1bb41f6)


**6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?**  
Idea: Count how often each topping is used across all pizzas, including extras and exclusions.
```sql
with cte as (
select LTRIM(RTRIM(value)) as topping, case when toppings <>'' then 1 else 0 end as marked from Updated_customer_orders c
join pizza_recipes pr on pr.pizza_id=c.pizza_id
cross apply string_split(toppings,',')
union all
select LTRIM(RTRIM(value)) as topping, case when exclusions <>'' then -1 else 0 end as marked from Updated_customer_orders c
join pizza_recipes pr on pr.pizza_id=c.pizza_id
cross apply string_split(exclusions,',')
union all
select LTRIM(RTRIM(value)) as topping, case when extras <>'' then 1 else 0 end as marked from Updated_customer_orders c
join pizza_recipes pr on pr.pizza_id=c.pizza_id
cross apply string_split(extras,','))
select topping_name, sum(marked) times_used_topping from cte
left join pizza_toppings pt on pt.topping_id=cte.topping
where topping <>''
group by topping_name
order by times_used_topping desc;
```
Output:  
\
![image](https://github.com/user-attachments/assets/af6a6fd4-2e66-4a5c-bf45-1a03c7ff4215)

## D. Pricing and Ratings

**1.	If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?**  
Idea: Compute the total revenue from completed orders, based on pizza type, without delivery fees or cancellations.
```sql
select sum(case when pizza_name='Meatlovers' then 12 else 10 end) cost from Updated_customer_orders c
join pizza_names pn on pn.pizza_id=c.pizza_id
join updated_runner_orders r on r.order_id=c.order_id and cancellation is null;
```
Output:  
\
![image](https://github.com/user-attachments/assets/e1538fdc-d5cd-49be-8dce-3a40d216a673)


**2.	What if there was an additional $1 charge for any pizza extras? -- a.	Add cheese is $1 extra**  
Idea: Adjust the total cost by adding $1 per extra topping for each pizza.
```sql
with  cte1 as (select *, case when pizza_name='Meatlovers' then 12 else 10 end as cost from pizza_names),
	  cte2 as (select pizza_name, case when extras='' then cost else cost + len(REPLACE(extras,', ','')) end as cost_add  from cte1
				join pizza_recipes pr on pr.pizza_id=cte1.pizza_id 
				join Updated_customer_orders c on c.pizza_id=cte1.pizza_id)
select sum(cost_add) all_cost from cte2;
```
Output:  
\
![image](https://github.com/user-attachments/assets/b994dd0f-a026-4737-acc3-a3f255cfc489)


**-- 3.	The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.**  
Idea: Create a table to store ratings for runners on a scale of 1 to 5.
```sql
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (
  order_id INT,
  rating INT);
INSERT INTO ratings (order_id, rating)
VALUES 
  (1,3),
  (2,5),
  (3,3),
  (4,1),
  (5,5),
  (7,3),
  (8,4),
  (10,3);
SELECT * FROM ratings;
```
Output:  
\
![image](https://github.com/user-attachments/assets/23fe288a-fcb5-467f-92a8-33c302b3e8ed)


**4.	Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- a.	customer_id
-- b.	order_id
-- c.	runner_id
-- d.	rating
-- e.	order_time
-- f.	pickup_time
-- g.	Time between order and pickup
-- h.	Delivery duration
-- i.	Average speed
-- j.	Total number of pizzas**  
Idea: Combine customer, order, and runner details, including timing and delivery metrics.
```sql
SELECT 
  c.customer_id,
  c.order_id,
  r.runner_id,
  c.order_time,
  r.pickup_time,
  DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS mins_difference,
  r.duration,
  ROUND(AVG(r.distance/r.duration*60), 1) AS avg_speed,
  COUNT(c.order_id) AS pizza_count
FROM Updated_customer_orders c
JOIN updated_runner_orders r 
  ON r.order_id = c.order_id
GROUP BY 
  c.customer_id,
  c.order_id,
  r.runner_id,
  c.order_time,
  r.pickup_time, 
  r.duration;
```
Output:  
\
![image](https://github.com/user-attachments/assets/c3b4442d-8ebe-468d-81a5-4cac4bbd7e29)


**-- 5.	If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?**  
Idea: Calculate net revenue by deducting runner costs (paid per km) from total revenue.
```sql
with cte as( select c.order_id ,sum(case when pizza_name='Meatlovers' then 12 else 10 end) revenue from Updated_customer_orders c
join pizza_names pn on pn.pizza_id=c.pizza_id
join updated_runner_orders r on r.order_id=c.order_id and cancellation is null
group by c.order_id)
select sum(revenue),  sum(distance*0.3) dis_cost, sum(revenue)- sum(distance*0.3) from updated_runner_orders r
join cte on cte.order_id=r.order_id;
```
Output:  
\
![image](https://github.com/user-attachments/assets/dec4dced-0759-4fc5-96c6-2a1cc01dc484)
