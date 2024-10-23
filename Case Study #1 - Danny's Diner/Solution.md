# Challenge Case Study 1 - Danny’s Diner

# **Relationship Diagram**
![image](https://github.com/user-attachments/assets/9a4b8564-9b93-444a-aa5b-c05bb9d74a00)


# **Data preview**
Sales table:
\
![image](https://github.com/user-attachments/assets/c057a972-4f1f-4856-877b-1dbe9a2b875e)
\
Menu table:
\
![image](https://github.com/user-attachments/assets/0b3b07de-bcbc-45a0-a52c-a9b0d59c1886)
\
Members table:
\
![image](https://github.com/user-attachments/assets/d984dcac-2fe2-436e-a9e6-6ad8ca0642ee)
\
# **Solutions**
**1. What is the total amount each customer spent at the restaurant?**  
Idea: Calculate the total amount spent by each customer by summing the price of items they purchased.

```sql
select customer_id, sum(price) total from sales s
join menu m on s.product_id=m.product_id
group by customer_id;
```
Output:  
\
![image](https://github.com/user-attachments/assets/7c4707e7-82e9-4249-b22d-1a79f3e41d87)

---

**2. How many days has each customer visited the restaurant?**  
Idea: Count the distinct days each customer visited the restaurant based on their order dates.

```sql
select customer_id, count(distinct order_date) visit from sales
group by customer_id;
```
Output:  
\
![image](https://github.com/user-attachments/assets/6303278d-33a2-49df-b551-1b447f16c44c)

---

**3. What was the first item from the menu purchased by each customer?**  
Idea: Use a window function to find the first item purchased by each customer in order of purchase date.

```sql
with list as (select customer_id, product_name, row_number() over(partition by customer_id order by order_date asc) list_food from sales s
join menu m on s.product_id=m.product_id)

select customer_id, product_name from list
where list_food=1;
```
Output:  
\
![image](https://github.com/user-attachments/assets/40824173-abf2-4622-b354-0801520027ab)

---

**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**  
Idea: Count the total number of times each item was purchased, then sort to find the most popular.

```sql
select top 1 s.product_id, product_name,COUNT(s.product_id) amount from sales s
join menu m on s.product_id=m.product_id
group by s.product_id, product_name
order by amount desc;
```
Output:  
\
![image](https://github.com/user-attachments/assets/d1156e43-11f8-4011-8712-178a8115d381)

---

**5. Which item was the most popular for each customer?**  
Idea: Use a ranking function to determine the most purchased item for each customer.

```sql
with rank_food as (select s.customer_id, product_name,COUNT(s.product_id) amount, rank() over (partition by s.customer_id order by COUNT(s.product_id) desc) rank_popular from sales s
join menu m on s.product_id=m.product_id
group by s.customer_id, product_name)

select customer_id, product_name,amount from rank_food
where rank_popular=1;
```
Output:  
\
![image](https://github.com/user-attachments/assets/62aad45e-a8b9-4ec5-b36b-7281206adea7)

---

**6. Which item was purchased first by the customer after they became a member?**  
Idea: Find the first item a customer purchased after becoming a member by comparing order and join dates.

```sql
with list as (select s.customer_id, product_name, row_number() over(partition by s.customer_id order by order_date asc) list_food from sales s
join menu m on s.product_id=m.product_id
join members me on me.customer_id=s.customer_id and me.join_date<=s.order_date)

select customer_id, product_name from list
where list_food=1;
```
Output:  
\
![image](https://github.com/user-attachments/assets/f9619a87-e95d-439c-91e6-aafc7b5fee0c)

---

**7. Which item was purchased just before the customer became a member?**  
Idea: Identify the last item purchased by a customer just before they joined the membership program.

```sql
with list as (select s.customer_id, product_name, row_number() over(partition by s.customer_id order by order_date desc) list_food from sales s
join menu m on s.product_id=m.product_id
join members me on me.join_date>s.order_date)

select customer_id, product_name from list
where list_food=1;
```
Output:  
\
![image](https://github.com/user-attachments/assets/c7a3dc95-0a84-4417-bf6a-e860ff001c72)

---

**8. What is the total items and amount spent for each member before they became a member?**  
Idea: Sum the total number of items and amount spent by customers before they joined the membership program.

```sql
SELECT 
    s.customer_id, 
    COUNT(s.product_id) AS total_items, 
    SUM(m.price) AS total_amount_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id
WHERE s.order_date < COALESCE(me.join_date, '9999-12-31')
GROUP BY s.customer_id;
```
Output:  
\
![image](https://github.com/user-attachments/assets/06c5989c-ec39-49b3-b8a4-2f2a97f4d6c5)

---

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**  
Idea: Calculate the total points for each customer based on their purchases, applying a 2x multiplier for sushi.

```sql
with s as (select customer_id, case when product_name='sushi' then price*2 else price*1 end as total from sales s
join menu m on s.product_id=m.product_id)
select customer_id, sum(total)*10 total from s
group by customer_id;
```
Output:  
\
![image](https://github.com/user-attachments/assets/fa4fa4fe-8b28-4d56-8129-78fb356e9ee7)

---

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**  
Idea: Calculate points for customers A and B, applying a 2x multiplier for the first week after joining and during January.

```sql
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
group by s.customer_id;
```
Output:  
\
![image](https://github.com/user-attachments/assets/e4c193a5-851d-4f57-9639-57ccf5b235b7)
