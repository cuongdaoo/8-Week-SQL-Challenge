select * from sales;
select * from menu;
select * from members;

-- 1.	What is the total amount each customer spent at the restaurant?
select customer_id, sum(price) total from sales s
join menu m on s.product_id=m.product_id
group by customer_id;

-- 2.	How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) visit from sales
group by customer_id;

-- 3.	What was the first item from the menu purchased by each customer?
with list as (select customer_id, product_name, row_number() over(partition by customer_id order by order_date asc) list_food from sales s
join menu m on s.product_id=m.product_id)

select customer_id, product_name from list
where list_food=1;

-- 4.	What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 s.product_id, product_name,COUNT(s.product_id) amount from sales s
join menu m on s.product_id=m.product_id
group by s.product_id, product_name
order by amount desc;

-- 5.	Which item was the most popular for each customer?
with rank_food as (select s.customer_id, product_name,COUNT(s.product_id) amount, rank() over (partition by s.customer_id order by COUNT(s.product_id) desc) rank_popular from sales s
join menu m on s.product_id=m.product_id
group by s.customer_id, product_name)

select customer_id, product_name,amount from rank_food
where rank_popular=1;

-- 6.	Which item was purchased first by the customer after they became a member?
with list as (select s.customer_id, product_name, row_number() over(partition by s.customer_id order by order_date asc) list_food from sales s
join menu m on s.product_id=m.product_id
join members me on me.customer_id=s.customer_id and me.join_date<=s.order_date)

select customer_id, product_name from list
where list_food=1;

-- 7.	Which item was purchased just before the customer became a member?

with list as (select s.customer_id, product_name, row_number() over(partition by s.customer_id order by order_date desc) list_food from sales s
join menu m on s.product_id=m.product_id
join members me on me.join_date>s.order_date)

select customer_id, product_name from list
where list_food=1;
-- 8.	What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id, 
    COUNT(s.product_id) AS total_items, 
    SUM(m.price) AS total_amount_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id
WHERE s.order_date < COALESCE(me.join_date, '9999-12-31')  -- Conditions only apply before becoming a member or if not a member yet
GROUP BY s.customer_id;

-- 9.	If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with s as (select customer_id, case when product_name='sushi' then price*2 else price*1 end as total from sales s
join menu m on s.product_id=m.product_id)
select customer_id, sum(total)*10 total from s
group by customer_id;
-- 10.	In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with s as (select s.customer_id, price*2*10 total from sales s
join menu m on s.product_id=m.product_id
join members me on me.customer_id=s.customer_id 
where order_date between join_date and DATEADD(day,7,join_date) and month(order_date)<2)
select customer_id, sum(total) from s
group by customer_id;

select 
s.customer_id, 
sum(
(case
when me.product_name = 'sushi' then me.price*2*10
when s.order_date >= m.join_date and  s.order_date < DATEADD(day, 7, m.join_date ) then me.price*2*10
else  me.price*10
end)) as point
from sales as s 
inner join  menu as me
on s.product_id = me.product_id 
inner join members as m
on s.customer_id = m.customer_id  
where s.customer_id in ('A','B') and month(s.order_date) <2
group by s.customer_id
