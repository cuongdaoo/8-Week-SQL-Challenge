# Challenge Case Study #4 - Data Bank

# **Relationship Diagram**
![image](https://github.com/user-attachments/assets/57062e59-24e1-47d1-af2b-58e51b78a431)



# **Data preview**
Regions table:
\
![image](https://github.com/user-attachments/assets/cbef8802-b7f1-42af-baff-cbe20ecf7475)
\
Customer_nodes table:
\
![image](https://github.com/user-attachments/assets/baa85a1a-c777-499b-ba31-8d4cd09fbd5f)
\
Customer_transactions table:
\
![image](https://github.com/user-attachments/assets/48514fed-390e-41a7-91f6-a813e10a3240)
\
# **Solutions**

## **A. Customer Nodes Exploration**

**1. How many unique nodes are there on the Data Bank system?**  
**Idea:** Count the unique node IDs in the `customer_nodes` table.  

```sql
select count(distinct node_id) unique_node 
from customer_nodes;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/30700dc2-bf11-41e0-bf01-c5984887bc18)

---

**2. What is the number of nodes per region?**  
**Idea:** Group nodes by region and count the total nodes for each region.  

```sql
select region_name, count(node_id) node 
from customer_nodes c
join regions r on c.region_id = r.region_id
group by region_name
order by node desc;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/5520de68-dbf6-46f8-9632-5f5cb08a7c55)

---

**3. How many customers are allocated to each region?**  
**Idea:** Count distinct customers for each region.  

```sql
select region_name, count(distinct customer_id) cus 
from customer_nodes c
join regions r on c.region_id = r.region_id
group by region_name
order by cus desc;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/cd3d4b83-f0d3-42fe-be18-c197b33d6338)

---

**4. How many days on average are customers reallocated to a different node?**  
**Idea:** Calculate the average days customers are reallocated from one node to another.  

```sql
with first_date_table as (
    select customer_id, region_id, node_id, min(start_date) first_date 
    from customer_nodes
    group by customer_id, region_id, node_id
),
reallocated_table as (
    select customer_id, region_id, node_id, first_date, 
           DATEDIFF(day, first_date, lead(first_date) over (partition by customer_id order by first_date)) as moving_date  
    from first_date_table
)
select avg(moving_date * 1.00) avg_moving_days  
from reallocated_table;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/f1b31a24-3f43-491b-b8ef-7269f5120985)


---

**5. What is the median, 80th, and 95th percentile for this same reallocation days metric for each region?**  
**Idea:** Compute statistical metrics (median, 80th, and 95th percentiles) of reallocation days by region.  

```sql
with first_date_table as (
    select customer_id, region_id, node_id, min(start_date) first_date 
    from customer_nodes
    group by customer_id, region_id, node_id
),
reallocated_table as (
    select customer_id, region_id, node_id, first_date, 
           DATEDIFF(day, first_date, lead(first_date) over (partition by customer_id order by first_date)) as moving_date  
    from first_date_table
)
select distinct region_name, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY moving_date) OVER (partition by reallocated_table.region_id) as median,
       PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY moving_date) OVER (partition by reallocated_table.region_id) as per_80th,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY moving_date) OVER (partition by reallocated_table.region_id) as per_95th
from reallocated_table
join regions on reallocated_table.region_id = regions.region_id;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/03cb6016-5038-4f5c-b36f-ff4a54df1023)


---

## **B. Customer Transactions**

**1. What is the unique count and total amount for each transaction type?**  
**Idea:** Count transactions and sum amounts grouped by transaction type.  

```sql
select txn_type, count(txn_type) unique_count, sum(txn_amount) total_amount
from customer_transactions
group by txn_type;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/125497a9-d73c-443b-ba1d-6fb60e405ca5)

---

**2. What is the average total historical deposit counts and amounts for all customers?**  
**Idea:** Calculate the average deposit count and amount per customer.  

```sql
with cte as (
    select customer_id, count(customer_id) txn_count, avg(txn_amount) avg_amount
    from customer_transactions
    where txn_type = 'deposit'
    group by customer_id
)
select round(avg(txn_count) * 1.00, 2) avg_deposit_count,
       round(avg(avg_amount) * 1.00, 2) avg_deposit_amt
from cte;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/941f2c1f-06a9-4138-8f50-ce8af37e91eb)

---

**3. For each month, how many customers make more than 1 deposit and either 1 purchase or 1 withdrawal?**  
**Idea:** Count customers meeting the deposit and transaction criteria for each month.  

```sql
with cte as (
    select customer_id, DATEPART(month, txn_date) monthtx,
           sum(case when txn_type = 'deposit' then 1 else 0 end) de_amount,
           sum(case when txn_type = 'withdrawal' then 1 else 0 end) wi_amount,
           sum(case when txn_type = 'purchase' then 1 else 0 end) pu_amount
    from customer_transactions
    group by customer_id, DATEPART(month, txn_date)
)
select monthtx, count(*) amount_customer  
from cte
where de_amount > 1 and (pu_amount > 1 or wi_amount > 1)
group by monthtx;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/cc8d080a-bcdd-425f-aa41-5129afb8ea2d)

---

**4. What is the closing balance for each customer at the end of the month?**  
**Idea:** Calculate the closing balance for each customer and month.  

```sql
with cte as (
    select customer_id, DATEPART(month, txn_date) monthtx,
           sum(case when txn_type = 'deposit' then txn_amount else 0 end) de_amount,
           sum(case when txn_type = 'withdrawal' then -txn_amount else 0 end) wi_amount,
           sum(case when txn_type = 'purchase' then -txn_amount else 0 end) pu_amount
    from customer_transactions
    group by customer_id, DATEPART(month, txn_date)
),
cte2 as (
    select customer_id, monthtx, de_amount + pu_amount + wi_amount as amount_balance  
    from cte
),
cte3 as (
    select customer_id, monthtx, amount_balance, 
           lag(amount_balance) over (partition by customer_id order by customer_id) amount_pre_monthtx 
    from cte2
)
select customer_id, monthtx, amount_balance,
       case when amount_pre_monthtx is null then amount_balance else amount_balance - amount_pre_monthtx end as closing_balance
from cte3;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/14037f5c-ab3a-468d-a5df-46d6e90e1aaf)

---

**5. What is the percentage of customers who increase their closing balance by more than 5%?**  
**Idea:** Calculate the percentage of customers whose closing balance grew by more than 5%.  

```sql
with cte as (
    select customer_id, DATEPART(month, txn_date) monthtx,
           sum(case when txn_type = 'deposit' then txn_amount else 0 end) de_amount,
           sum(case when txn_type = 'withdrawal' then -txn_amount else 0 end) wi_amount,
           sum(case when txn_type = 'purchase' then -txn_amount else 0 end) pu_amount
    from customer_transactions
    group by customer_id, DATEPART(month, txn_date)
),
cte2 as (
    select customer_id, monthtx, de_amount + pu_amount + wi_amount as amount_balance  
    from cte
),
cte3 as (
    select customer_id, monthtx, amount_balance, 
           FIRST_VALUE(amount_balance) over (partition by customer_id order by customer_id) first_amount,
           LAST_VALUE(amount_balance) over (partition by customer_id order by customer_id) last_amount
    from cte2
),
cte4 as (
    select *, ((last_amount - first_amount) * 100 / abs(first_amount)) grow_rate 
    from cte3
    where ((last_amount - first_amount) * 100 / abs(first_amount)) > 5 and last_amount > first_amount
)
select cast(count(distinct customer_id) as float) * 100 / 
       (select cast(count(distinct customer_id) as float) from customer_transactions) 
       as "percentage of customers who increase their closing balance by more than 5%"  
from cte4;
```

**Output:**  
\
![image](https://github.com/user-attachments/assets/4f268ca9-fc58-4cc5-8195-1479e8a76986)
--- 
