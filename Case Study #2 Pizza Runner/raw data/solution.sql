select * from [dbo].[runners];
select * from [dbo].[customer_orders];
select * from [dbo].[runner_orders];
select * from [dbo].[pizza_names] ;
select * from [dbo].[pizza_recipes];
select * from [dbo].[pizza_toppings];


-- After cleaning
select * from [dbo].[runners];
select * from [dbo].[Updated_customer_orders];
select * from [dbo].[updated_runner_orders];
select * from [dbo].[pizza_names] ;
select * from [dbo].[pizza_recipes];
select * from [dbo].[pizza_toppings];

--A. Pizza Metrics
-- 1.	How many pizzas were ordered?
select count(*) pizza_count from customer_orders;
-- 2.	How many unique customer orders were made?
select Count(order_id) "orders were made" from updated_runner_orders;
-- 3.	How many successful orders were delivered by each runner?
select runner_id, COUNT(order_id) success_order from updated_runner_orders
where cancellation is null
group by runner_id;
-- 4.	How many of each type of pizza was delivered?
select pizza_id, count(*) "pizza was delivered" from Updated_customer_orders uc
join updated_runner_orders ur on uc.order_id=ur.order_id
where pickup_time is not null
group by pizza_id;
-- 5.	How many Vegetarian and Meatlovers were ordered by each customer?
with c as (select customer_id, case when pizza_name='Meatlovers' then 1 else 0 end as meat, case when pizza_name='Vegetarian' then 1 else 0 end as veget 
from Updated_customer_orders uc
join pizza_names pn on uc.pizza_id=pn.pizza_id)
select customer_id, sum(meat) meat_lover, sum(veget) veget_lover from c
group by customer_id;
-- 6.	What was the maximum number of pizzas delivered in a single order?
with c as (select order_id, count(pizza_id) amount from Updated_customer_orders
group by order_id)
select max( amount) "maximum number of pizzas delivered in a single order" from c;
-- 7.	For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select customer_id,   SUM(CASE WHEN c.exclusions <> ' ' OR
      c.extras <> ' ' THEN 1 ELSE 0 END) AS Changes,
  SUM(CASE WHEN c.exclusions = ' ' AND
      c.extras = ' ' THEN 1 ELSE 0 END) AS No_changes
from Updated_customer_orders c
join updated_runner_orders r on c.order_id=r.order_id
where cancellation is null
group by customer_id;
-- 8.	How many pizzas were delivered that had both exclusions and extras?
select  SUM(CASE WHEN c.exclusions <> ' ' and
      c.extras <> ' ' THEN 1 ELSE 0 END) AS Changes
from Updated_customer_orders c
join updated_runner_orders r on c.order_id=r.order_id
where cancellation is null;
-- 9.	What was the total volume of pizzas ordered for each hour of the day?
select DATEPART(hour, order_time) hours, count(*) Pizza_Ordered_Count from Updated_customer_orders
group by DATEPART(hour, order_time);
-- 10.	What was the volume of orders for each day of the week?
select DATENAME(WEEKDAY, order_time), count(*) Pizza_Ordered_Count from Updated_customer_orders
group by DATENAME(WEEKDAY, order_time);

-- B) Runner and Customer Experience
-- 1.	How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select case 
	WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN '2021-01-01'
    WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-14' THEN '2021-01-08'
    WHEN registration_date BETWEEN '2021-01-15' AND '2021-01-21' THEN '2021-01-15'
  END AS "Week Start Period",count(runner_id) as cnt 
from runners
group by case 
	WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN '2021-01-01'
    WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-14' THEN '2021-01-08'
    WHEN registration_date BETWEEN '2021-01-15' AND '2021-01-21' THEN '2021-01-15'
  END;
-- 2.	What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select runner_id, avg(datepart(minute,pickup_time-order_time)) avg_time from updated_runner_orders r
join Updated_customer_orders o on o.order_id=r.order_id
where duration is not null
group by runner_id;
-- 3.	Is there any relationship between the number of pizzas and how long the order takes to prepare?
with preparetime as(select r.order_id, datepart(minute,pickup_time-order_time) time from updated_runner_orders r
join Updated_customer_orders o on o.order_id=r.order_id
where pickup_time is not null),
ordertime as(select order_id, order_time, count(pizza_id) amount from Updated_customer_orders
group by order_id,order_time)
select amount, avg(time) avg_pre_time from preparetime p
join ordertime o on p.order_id=o.order_id
group by amount;
-- 4.	What was the average distance travelled for each customer?
select customer_id, avg(distance) avg_distance from Updated_customer_orders c
join updated_runner_orders r on c.order_id=r.order_id
group by customer_id;
-- 5.	What was the difference between the longest and shortest delivery times for all orders?
select max(duration)-min(duration) "difference between the longest and shortest delivery times for all orders"from updated_runner_orders;
-- 6.	What was the average speed for each runner for each delivery and do you notice any trend for these values?
with ordertime as (select order_id, order_time, count(pizza_id) amount from Updated_customer_orders
group by order_id, order_time)
,speed as(select order_id, runner_id, round((60* distance/ duration),2) speed_km from updated_runner_orders where cancellation is null)
select runner_id, amount, speed_km, avg(speed_km) over (partition by runner_id) avg_time_runner from speed r
join ordertime o on o.order_id=r.order_id;
-- 7.	What is the successful delivery percentage for each runner?
select runner_id, round(100*count(pickup_time)/count(order_id),0) "successful delivery percentage" from updated_runner_orders
group by runner_id;


select * from [dbo].[runners];
select * from [dbo].[Updated_customer_orders];
select * from [dbo].[updated_runner_orders];
select * from [dbo].[pizza_names] ;
select * from [dbo].[pizza_recipes];
select * from [dbo].[pizza_toppings];

-- C. Ingredient Optimisation
-- 1.	What are the standard ingredients for each pizza?
with cte as(select pizza_id,value as topping_id
		 from pizza_recipes
		cross apply string_split (toppings,',')),
		irg as( select pizza_id, topping_name from pizza_toppings pt
		join cte on cte.topping_id=pt.topping_id)
select pizza_name, STRING_AGG(topping_name,',') as topping_name from pizza_names pn
join irg on irg.pizza_id= pn.pizza_id
group by pizza_name;
-- 2.	What was the most commonly added extra?
with extra as(select value as topping_id from Updated_customer_orders
				cross apply string_split(extras,','))
select top 1 topping_name, count(extra.topping_id) added_extras_count from pizza_toppings pt
join extra on extra.topping_id=pt.topping_id
group by topping_name
order by added_extras_count desc;
-- 3.	What was the most common exclusion?
with extra as(select value as topping_id from Updated_customer_orders
				cross apply string_split(exclusions,','))
select top 1 topping_name, count(extra.topping_id) added_extras_count from pizza_toppings pt
join extra on extra.topping_id=pt.topping_id
group by topping_name
order by added_extras_count desc;
-- 4.	Generate an order item for each record in the customers_orders table in the format of one of the following:
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
-- a.	Meat Lovers
-- b.	Meat Lovers - Exclude Beef
-- c.	Meat Lovers - Extra Bacon
-- d.	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


-- 5.	Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- a.	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
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


-- 6.	What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
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



--D. Pricing and Ratings

select * from [dbo].[runners];
select * from [dbo].[Updated_customer_orders];
select * from [dbo].[updated_runner_orders];
select * from [dbo].[pizza_names] ;
select * from [dbo].[pizza_recipes];
select * from [dbo].[pizza_toppings];
-- 1.	If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
select sum(case when pizza_name='Meatlovers' then 12 else 10 end) cost from Updated_customer_orders c
join pizza_names pn on pn.pizza_id=c.pizza_id
join updated_runner_orders r on r.order_id=c.order_id and cancellation is null;

-- 2.	What if there was an additional $1 charge for any pizza extras?
-- a.	Add cheese is $1 extra
with  cte1 as (select *, case when pizza_name='Meatlovers' then 12 else 10 end as cost from pizza_names),
	  cte2 as (select pizza_name, case when extras='' then cost else cost + len(REPLACE(extras,', ','')) end as cost_add  from cte1
				join pizza_recipes pr on pr.pizza_id=cte1.pizza_id 
				join Updated_customer_orders c on c.pizza_id=cte1.pizza_id)
select sum(cost_add) all_cost from cte2
-- 3.	The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS ratings
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

 SELECT *
 FROM ratings;
-- 4.	Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- a.	customer_id
-- b.	order_id
-- c.	runner_id
-- d.	rating
-- e.	order_time
-- f.	pickup_time
-- g.	Time between order and pickup
-- h.	Delivery duration
-- i.	Average speed
-- j.	Total number of pizzas

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
-- 5.	If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
with cte as( select c.order_id ,sum(case when pizza_name='Meatlovers' then 12 else 10 end) revenue from Updated_customer_orders c
join pizza_names pn on pn.pizza_id=c.pizza_id
join updated_runner_orders r on r.order_id=c.order_id and cancellation is null
group by c.order_id)
select sum(revenue),  sum(distance*0.3) dis_cost, sum(revenue)- sum(distance*0.3) from updated_runner_orders r
join cte on cte.order_id=r.order_id;

