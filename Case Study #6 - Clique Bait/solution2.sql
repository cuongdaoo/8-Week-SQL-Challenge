select * from [dbo].[users];
select * from [dbo].[events];
select * from [dbo].[event_identifier];
select * from [dbo].[campaign_identifier];
select * from [dbo].[page_hierarchy];

-- B. Digital Analysis
-- 1.	How many users are there?
select count(distinct user_id) total_users from users;

-- 2.	How many cookies does each user have on average?
select count(distinct user_id) total_users, count(cookie_id) total_cookies, cast(count(cookie_id) as float)/cast(count(distinct user_id) as float) avg_cookies
from users;

-- 3.	What is the unique number of visits by all users per month?
select DATEPART(month, event_time) as month, count(distinct visit_id) total_visit from events
group by  DATEPART(month, event_time)
order by total_visit desc;
-- 4.	What is the number of events for each event type?
select event_name, count(e.event_type) amout_event from events e
join event_identifier ei on e.event_type=ei.event_type
group by event_name
order by amout_event desc;
-- 5.	What is the percentage of visits which have a purchase event?
select event_name, 100*cast(count(e.visit_id) as float)/ cast((select count(distinct visit_id) from events) as float) amount_visit
from events e
join event_identifier ei on e.event_type=ei.event_type
where event_name='Purchase'
group by event_name;
-- 6.	What is the percentage of visits which view the checkout page but do not have a purchase event?
with cte as (select sum(case when event_name='Purchase' then 1 else 0 end) amount_purchase,
							sum(case when page_name='Checkout' then 1 else 0 end) amount_checkout
from events e
join event_identifier ei on e.event_type=ei.event_type
join page_hierarchy p on p.page_id=e.page_id
where event_name='Purchase' or page_name='Checkout')
select 100*(cast((amount_checkout-amount_purchase) as float)/ cast(amount_checkout as float)) percent_not_purchase from cte;
-- 7.	What are the top 3 pages by number of views?
select top 3 page_name, count(e.page_id) views
from events e
join page_hierarchy p on p.page_id=e.page_id 
group by page_name
order by views desc;
-- 8.	What is the number of views and cart adds for each product category?
select product_category, sum(case when event_name='Page View' then 1 else 0 end) pageview, sum(case when event_name='Add to Cart' then 1 else 0 end) cartview from page_hierarchy p
join events e on p.page_id=e.page_id
join event_identifier ei on e.event_type=ei.event_type
where product_category is not null
group by product_category;

-- 9.	What are the top 3 products by purchases?
with cte as (select visit_id from events e
join event_identifier ei on ei.event_type=e.event_type
where event_name='Purchase')

select top 3 page_name, product_category, count(e.visit_id) amount from page_hierarchy ph
join events e on ph.page_id=e.page_id
join event_identifier ei on e.event_type=ei.event_type
where event_name ='Add to Cart' and e.visit_id in (select visit_id from cte)
group by page_name, product_category
order by amount desc;

--C. Product Funnel Analysis
--How many times was each product viewed?
--How many times was each product added to cart?
--How many times was each product added to a cart but not purchased (abandoned)?
--How many times was each product purchased?


with view_table as (select page_name, product_category, count(page_name) total_view from page_hierarchy ph
					join events e on ph.page_id=e.page_id
					join event_identifier ei on e.event_type=ei.event_type
					where product_category is not null and event_name='Page View'
					group by page_name, product_category),
	added_table as (select page_name, product_category, count(page_name) total_add from page_hierarchy ph
					join events e on ph.page_id=e.page_id
					join event_identifier ei on e.event_type=ei.event_type
					where product_category is not null and event_name='Add to Cart'
					group by page_name, product_category),
	purchase_table as (select visit_id from  events e
					join event_identifier ei on e.event_type=ei.event_type
					where event_name='Purchase'),
	purchase_table_2 as (select page_name, product_category, count(page_name) total_purchase from page_hierarchy ph
					join events e on ph.page_id=e.page_id
					join event_identifier ei on e.event_type=ei.event_type
					right join purchase_table p on e.visit_id=p.visit_id
					where product_category is not null and event_name='Add to Cart'
					group by page_name, product_category)
select view_table.page_name, view_table.product_category, total_view, total_add, total_purchase, total_add-total_purchase as total_abounded 
into product_status
from view_table
left join added_table on view_table.page_name= added_table.page_name
left join purchase_table_2 on view_table.page_name= purchase_table_2.page_name;

select * from product_status;

---Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
select product_category, sum(total_view) total_view, sum(total_add) total_add, sum(total_purchase) total_purchase, sum(total_abounded) total_abounded 
into product_category_status
from product_status
group by product_category;

---Use your 2 new output tables - answer the following questions:
---1.	Which product had the most views, cart adds and purchases?
with cte as (select *,
		rank() over (order by total_view desc) rank_view,
		rank() over (order by total_add desc) rank_add,
		rank() over (order by total_purchase desc) rank_purchase
from product_status)

select * from cte
where rank_view=1 or rank_add=1 or rank_purchase=1;
---2.	Which product was most likely to be abandoned?
select top 1 page_name, product_category, total_abounded from product_status
order by total_abounded desc;
---3.	Which product had the highest view to purchase percentage?
with cte as (select page_name, product_category, total_purchase*100.00/total_view as percent_purchase from product_status)

select top 1 * from cte
order by percent_purchase desc;
---4.	What is the average conversion rate from view to cart add?
select 100*avg(cast(total_add as float)/total_view) as rate_view_add from product_status;
---5.	What is the average conversion rate from cart add to purchase?
select 100*avg(cast(total_purchase as float)/total_add) as rate_add_purchase from product_status;


---D. Campaigns Analysis
/*
---Generate a table that has 1 single row for every unique visit_id record and has the following columns:

user_id
visit_id
visit_start_time: the earliest event_time for each visit
page_views: count of page views for each visit
cart_adds: count of product cart add events for each visit
purchase: 1/0 flag if a purchase event exists for each visit
campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
impression: count of ad impressions for each visit
click: count of ad clicks for each visit
(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
*/

select u.user_id, e.visit_id, min(event_time) visit_start_time, 
		sum(case when event_name='Page View' then 1 else 0 end) page_views,
		sum(case when event_name='Add to Cart' then 1 else 0 end) cart_adds,
		sum(case when event_name='Purchase' then 1 else 0 end) purchase,
		ci.campaign_name,
		sum(case when event_name='Ad Impression' then 1 else 0 end) impression,
		sum(case when event_name='Ad Click' then 1 else 0 end) click,
		STRING_AGG(case when event_name='Add to Cart' and ph.product_category is not NULL then ph.page_name else NULL end, ', ') within group(order by sequence_number asc) cart_products
		from users u
join events e on u.cookie_id=e.cookie_id
join event_identifier ei on e.event_type=ei.event_type
join campaign_identifier ci on e.event_time between ci.start_date and ci.end_date
join page_hierarchy ph on e.page_id=ph.page_id
group by user_id, visit_id, ci.campaign_name;
