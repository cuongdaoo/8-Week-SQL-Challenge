# Challenge Case Study #7 - Balanced Tree Clothing Co

### High Level Sales Analysis

**1. What was the total quantity sold for all products?**  
**Explanation:**  
To calculate the total quantity sold, we sum the `qty` column from the `sales` table. This aggregates all units sold across all transactions and products.  

**SQL Code:**  
```sql
SELECT 
  SUM(qty) AS total_quantity_sold 
FROM 
  sales;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/0298099a-3a26-45ac-9d7c-38357882f812)

---  

---

**2. What is the total generated revenue for all products before discounts?**  
**Explanation:**  
Revenue before discounts is calculated by multiplying `qty` and `price` for each transaction and summing the results.  

**SQL Code:**  
```sql
SELECT 
  SUM(qty * price) AS total_revenue 
FROM 
  sales;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/1f362d50-6d92-44ca-a826-5e78c89cb037)

---  

---

**3. What was the total discount amount for all products?**  
**Explanation:**  
The discount amount is computed by applying the discount percentage to the product of `qty` and `price`, then summing across all transactions. The `discount` column is cast to a float to handle percentage calculations.  

**SQL Code:**  
```sql
SELECT 
  SUM(qty * price * (CAST(discount AS FLOAT) / 100)) AS total_discount 
FROM 
  sales;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/2806d683-e3d4-49ec-a34c-9677995d4748)

---  

---

### Transaction Analysis  

**1. How many unique transactions were there?**  
**Explanation:**  
We count the distinct `txn_id` values in the `sales` table to determine the number of unique transactions.  

**SQL Code:**  
```sql
SELECT 
  COUNT(DISTINCT txn_id) AS total_unique_transaction 
FROM 
  sales;
```

**Answer:**
![image](https://github.com/user-attachments/assets/184830f1-6155-4263-b315-29efaf62ffc2)

---  

---

**2. What is the average unique products purchased in each transaction?**  
**Explanation:**  
The average is calculated by dividing the total quantity sold by the number of unique transactions.  

**SQL Code:**  
```sql
SELECT 
  COUNT(qty) / COUNT(DISTINCT txn_id) AS avg_product 
FROM 
  sales;
```

**Answer:**
![image](https://github.com/user-attachments/assets/d4e60087-45d9-429b-9fd1-19ba397628fd)
  
---  

---

**3. What are the 25th, 50th, and 75th percentile values for the revenue per transaction?**  
**Explanation:**  
1. A CTE calculates revenue per transaction by summing `qty * price` for each `txn_id`.  
2. `PERCENTILE_CONT` is used with windowing to compute the percentiles over the ordered revenue values.  

**SQL Code:**  
```sql
WITH cte AS (
  SELECT 
    DISTINCT txn_id, 
    SUM(qty * price) AS revenue 
  FROM 
    sales 
  GROUP BY 
    txn_id
)
SELECT 
  DISTINCT 
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) OVER () AS pct_25th,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue) OVER () AS pct_50th,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) OVER () AS pct_75th
FROM 
  cte;
```

**Answer:** 
![image](https://github.com/user-attachments/assets/700683f9-40b6-48de-9746-ccc5d5f8196a)

---  

---

**4. What is the average discount value per transaction?**  
**Explanation:**  
Total discount amount (as calculated earlier) is divided by the number of unique transactions.  

**SQL Code:**  
```sql
SELECT 
  SUM(qty * price * (CAST(discount AS FLOAT) / 100)) / COUNT(DISTINCT txn_id) AS avg_discount 
FROM 
  sales;
```

**Answer:** 
![image](https://github.com/user-attachments/assets/60b633fb-b9a2-4301-a47f-36bf1b5e5ca3)

---  

---

**5. What is the percentage split of all transactions for members vs non-members?**  
**Explanation:**  
1. Use `CASE` statements to count transactions where `member` is `t` (member) or `f` (non-member).  
2. Calculate the percentage by dividing each count by the total number of transactions.  

**SQL Code:**  
```sql
SELECT 
  ROUND(CAST(COUNT(DISTINCT CASE WHEN member = 't' THEN txn_id END) * 100.00 / COUNT(DISTINCT txn_id) AS FLOAT), 2) AS is_member,
  ROUND(CAST(COUNT(DISTINCT CASE WHEN member = 'f' THEN txn_id END) * 100.00 / COUNT(DISTINCT txn_id) AS FLOAT), 2) AS non_member
FROM 
  sales;
```

**Answer:** 
![image](https://github.com/user-attachments/assets/f03b5c0e-a9fb-443e-aa34-38340481a2af)

---  

---

**6. What is the average revenue for member transactions and non-member transactions?**  
**Explanation:**  
1. A CTE calculates revenue per transaction, grouped by `txn_id` and `member`.  
2. Average revenue is computed separately for members and non-members.  

**SQL Code:**  
```sql
WITH cte AS (
  SELECT 
    DISTINCT txn_id, 
    member, 
    SUM(qty * price) AS revenue 
  FROM 
    sales 
  GROUP BY 
    txn_id, 
    member
)
SELECT 
  member, 
  CAST(AVG(revenue * 1.0) AS FLOAT) AS avg_revenue 
FROM 
  cte 
GROUP BY 
  member;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/1baaee27-d048-4d85-b15b-10385dcda8d1)

---  

---

### Product Analysis  

**1. What are the top 3 products by total revenue before discount?**  
**Explanation:**  
1. Join `sales` with `product_details` to get product names.  
2. Sum revenue (`qty * price`) grouped by product and sort descendingly.  

**SQL Code:**  
```sql
SELECT TOP 3 
  pd.product_name, 
  SUM(s.qty * s.price) AS revenue 
FROM 
  product_details pd 
  JOIN sales s ON pd.product_id = s.prod_id 
GROUP BY 
  pd.product_name 
ORDER BY 
  revenue DESC;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/476bf7cb-124c-4d84-be5b-37d1fded66b7)

---  

---

**2. What is the total quantity, revenue, and discount for each segment?**  
**Explanation:**  
1. Join tables to link products to segments.  
2. Aggregate `qty`, revenue, and discount by `segment_name`.  

**SQL Code:**  
```sql
SELECT 
  pd.segment_name, 
  SUM(s.qty) AS total_quantity, 
  SUM(s.qty * s.price) AS revenue, 
  SUM(s.qty * s.price * (CAST(discount AS FLOAT) / 100)) AS total_discount 
FROM 
  product_details pd 
  JOIN sales s ON pd.product_id = s.prod_id 
GROUP BY 
  pd.segment_name;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/362208c3-ba1b-42ee-bd80-cf4eff78a0d8)


---  

---

**3. What is the top selling product for each segment?**  
**Explanation:**  
1. A CTE calculates total quantity sold per product and segment.  
2. Another CTE ranks products within each segment by quantity sold.  
3. Filter to retain only the top-ranked product in each segment.  

**SQL Code:**  
```sql
WITH cte AS (
  SELECT 
    pd.segment_name, 
    pd.product_name, 
    SUM(s.qty) AS total_quantity, 
    SUM(s.qty * s.price) AS revenue 
  FROM 
    product_details pd 
    JOIN sales s ON pd.product_id = s.prod_id 
  GROUP BY 
    pd.segment_name, 
    pd.product_name
),
cte_rank AS (
  SELECT 
    *, 
    RANK() OVER (PARTITION BY segment_name ORDER BY total_quantity DESC) AS rank_qty 
  FROM 
    cte
)
SELECT 
  segment_name, 
  product_name, 
  total_quantity 
FROM 
  cte_rank 
WHERE 
  rank_qty = 1;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/6874c4d1-f5b2-4b4b-a76b-3efc2848b473)



---  

---

**4. What is the total quantity, revenue, and discount for each category?**  
**Explanation:**  
Aggregate data by `category_name` after joining the tables.  

**SQL Code:**  
```sql
SELECT 
  pd.category_name, 
  SUM(s.qty) AS total_quantity, 
  SUM(s.qty * s.price) AS revenue, 
  SUM(s.qty * s.price * (CAST(discount AS FLOAT) / 100) AS total_discount 
FROM 
  product_details pd 
  JOIN sales s ON pd.product_id = s.prod_id 
GROUP BY 
  pd.category_name;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/2c4b813f-dc91-41e1-990e-e959f8f26519)

---  

---

**6. What is the percentage split of revenue by product for each segment?**  
**Explanation:**  
1. Compute revenue per product and segment.  
2. Use a window function to calculate the percentage contribution of each product within its segment.  

**SQL Code:**  
```sql
WITH cte AS (
  SELECT 
    pd.segment_name, 
    pd.product_name, 
    SUM(s.qty * s.price) AS revenue 
  FROM 
    product_details pd 
    JOIN sales s ON pd.product_id = s.prod_id 
  GROUP BY 
    pd.segment_name, 
    pd.product_name
)
SELECT 
  segment_name, 
  product_name, 
  ROUND(CAST(revenue * 100.0 / SUM(revenue) OVER (PARTITION BY segment_name) AS FLOAT), 2) AS per_revenue 
FROM 
  cte;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/5d3bb414-b1fe-431c-b39c-f095e0947095)

---  

---

**7. What is the percentage split of revenue by segment for each category?**  
**Explanation:**  
Similar to the previous question but aggregated at the category-segment level.  

**SQL Code:**  
```sql
WITH cte AS (
  SELECT 
    pd.category_name, 
    pd.segment_name, 
    SUM(s.qty * s.price) AS revenue 
  FROM 
    product_details pd 
    JOIN sales s ON pd.product_id = s.prod_id 
  GROUP BY 
    pd.category_name, 
    pd.segment_name
)
SELECT 
  category_name, 
  segment_name, 
  ROUND(CAST(revenue * 100.0 / SUM(revenue) OVER (PARTITION BY category_name) AS FLOAT), 2) AS per_revenue 
FROM 
  cte;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/e4c09233-b44f-4bb5-8c88-ed215ca453bd)

---  

---

**8. What is the percentage split of total revenue by category?**  
**Explanation:**  
1. Calculate total revenue per category.  
2. Compute each category’s percentage of the overall revenue.  

**SQL Code:**  
```sql
with cte as (select category_name,sum(s.qty) total_quantity,sum(s.qty*s.price) revenue, sum(s.qty*s.price* (cast(discount as float)/100)) total_discount from product_details pd
join sales s on pd.product_id=s.prod_id
group by category_name)
select category_name, round(cast(revenue*100.0/(select sum(qty*price) from sales) as float),2) as per_revenue ,
	sum(revenue) over (partition by category_name order by category_name) as total_revenue
from cte;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/d98982cc-d636-4c67-b0f6-cdd9782d7dbc)


---  

---

**9. What is the total transaction “penetration” for each product?**  
**Explanation:**  
Penetration is the percentage of transactions containing a product.  
1. Count distinct transactions per product.  
2. Divide by the total number of transactions and convert to a percentage.  

**SQL Code:**  
```sql
WITH cte AS (
  SELECT 
    s.prod_id, 
    pd.product_name, 
    COUNT(DISTINCT s.txn_id) AS product_txn, 
    (SELECT COUNT(DISTINCT txn_id) FROM sales) AS total_txn 
  FROM 
    sales s 
    JOIN product_details pd ON s.prod_id = pd.product_id 
  GROUP BY 
    s.prod_id, 
    pd.product_name
)
SELECT 
  *, 
  ROUND(CAST((100.0 * product_txn) / total_txn AS FLOAT), 2) AS penetration 
FROM 
  cte;
```

**Answer:** 
![image](https://github.com/user-attachments/assets/b0a14731-7746-4abc-b33d-48c97b4ac493)

---  

---

**10. What is the most common combination of at least 1 quantity of any 3 products in a single transaction?**  
**Explanation:**  
1. Use a CTE to list products per transaction.  
2. Self-join the CTE three times to find combinations of 3 products in the same transaction.  
3. Count occurrences and return the top combination.  

**SQL Code:**  
```sql
WITH CTE AS (
  SELECT 
    txn_id, 
    p1.product_name 
  FROM 
    sales s 
    LEFT JOIN product_details p1 ON s.prod_id = p1.product_id
)
SELECT TOP 1
  C1.product_name AS product_1,
  C2.product_name AS product_2,
  C3.product_name AS product_3,
  COUNT(*) AS time_trans
FROM 
  CTE c1 
  LEFT JOIN CTE C2 ON C1.txn_id = C2.txn_id AND C1.product_name < C2.product_name
  LEFT JOIN CTE C3 ON C1.txn_id = C3.txn_id AND C1.product_name < C3.product_name AND C2.product_name < C3.product_name
WHERE 
  C1.product_name IS NOT NULL 
  AND C2.product_name IS NOT NULL 
  AND C3.product_name IS NOT NULL
GROUP BY 
  C1.product_name, 
  C2.product_name, 
  C3.product_name
ORDER BY 
  time_trans DESC;
```

**Answer:**  
![image](https://github.com/user-attachments/assets/bc5e1f93-1da7-4933-842a-6ebe32cbfe4a)

---  

---

### Bonus Challenge  

**Transform `product_hierarchy` and `product_prices` into `product_details`:**  
**Explanation:**  
1. Join `product_hierarchy` three times to link style, segment, and category.  
2. Concatenate `level_text` values to form the product name.  

**SQL Code:**  
```sql
SELECT 
  pp.product_id, 
  pp.price,  
  CONCAT(ph.level_text, ' ', ph2.level_text, ' - ', ph3.level_text) AS product_name,
  ph3.id AS category_id,
  ph2.id AS segment_id,
  ph.id AS style_id,
  ph3.level_text AS category_name,
  ph2.level_text AS segment_name,
  ph.level_text AS style_name
FROM 
  product_hierarchy ph
  JOIN product_hierarchy ph2 ON ph2.id = ph.parent_id
  JOIN product_hierarchy ph3 ON ph3.id = ph2.parent_id
  JOIN product_prices pp ON pp.id = ph.id;
```

**Answer:**  

---
