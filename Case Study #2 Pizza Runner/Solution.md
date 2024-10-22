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

# **Solutions**

## A. Pizza Metrics

**1. How many pizzas were ordered?**
Idea: Calculate the total number of pizzas in the customer orders.

```sql
select count(*) pizza_count from customer_orders;
```
Output:
\

**2. How many unique customer orders were made?**
Idea: Find the number of distinct orders from the updated runner orders table.

```sql
select Count(order_id) "orders were made" from updated_runner_orders;
```
Output:
\

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

**9. What was the total volume of pizzas ordered for each hour of the day?**
Idea: Group and count pizza orders by the hour of the day.

```sql
select DATEPART(hour, order_time) hours, count(*) Pizza_Ordered_Count 
from Updated_customer_orders
group by DATEPART(hour, order_time);
```
Output:
\

**10. What was the volume of orders for each day of the week?**
Idea: Group and count pizza orders by the day of the week.

```sql
select DATENAME(WEEKDAY, order_time), count(*) Pizza_Ordered_Count 
from Updated_customer_orders
group by DATENAME(WEEKDAY, order_time);
```
Output:
\
