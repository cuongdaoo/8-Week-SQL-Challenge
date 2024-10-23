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