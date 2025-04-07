## Case Study #7 - Balanced Tree Clothing Co.
<p align="center">
<img src="https://github.com/user-attachments/assets/188f817e-864a-41ae-9611-f7b32e8188ad" align="center" width="400" height="400" >

A structured summary table capturing the SQL methods and techniques applied for each objective across categories:

---

### **Summary Table: Applied SQL Methods/Techniques**

| **Category**               | **Objective**                                                                         | **SQL Method/Technique Applied**                                                                                      |
|----------------------------|---------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| **High Level Sales Analysis** | 1. Total quantity sold for all products                                               | `SUM()` aggregation                                                                                                   |
|                             | 2. Total revenue before discounts                                                     | `SUM()` with arithmetic operations (`qty * price`)                                                                    |
|                             | 3. Total discount amount for all products                                             | `SUM()` with arithmetic operations and type casting (`CAST(discount AS FLOAT)`)                                       |
| **Transaction Analysis**      | 1. Unique transaction count                                                           | `COUNT(DISTINCT txn_id)`                                                                                              |
|                             | 2. Average unique products per transaction                                            | Division of `COUNT(qty)` by `COUNT(DISTINCT txn_id)`                                                                  |
|                             | 3. 25th/50th/75th revenue percentiles per transaction                                 | CTE with `PERCENTILE_CONT()` and window functions (`WITHIN GROUP ... OVER()`)                                         |
|                             | 4. Average discount per transaction                                                   | `SUM()` with arithmetic operations divided by `COUNT(DISTINCT txn_id)`                                                |
|                             | 5. Percentage split of transactions (members vs non-members)                          | Conditional `CASE` statements with `COUNT(DISTINCT)` and percentage calculations                                      |
|                             | 6. Average revenue for member/non-member transactions                                 | CTE with `GROUP BY` and `AVG()` aggregation                                                                           |
| **Product Analysis**          | 1. Top 3 products by revenue                                                          | `JOIN` tables, `SUM()` with `GROUP BY`, and `ORDER BY ... DESC` with `TOP` clause                                     |
|                             | 2. Total quantity, revenue, and discount per segment                                  | `JOIN` tables and `SUM()` with `GROUP BY` segment                                                                      |
|                             | 3. Top-selling product per segment                                                    | CTE with `RANK()` window function partitioned by segment                                                              |
|                             | 4. Total quantity, revenue, and discount per category                                 | `JOIN` tables and `SUM()` with `GROUP BY` category                                                                     |
|                             | 6. Percentage revenue split by product within segments                                | CTE with window functions (`SUM() OVER(PARTITION BY)`) for percentage calculations                                    |
|                             | 7. Percentage revenue split by segment within categories                              | CTE with window functions (`SUM() OVER(PARTITION BY)`) for percentage calculations                                    |
|                             | 8. Percentage revenue split by category                                               | Subquery in `SELECT` clause for total revenue reference                                                               |
|                             | 9. Transaction penetration per product                                                | Subquery for total transactions and `COUNT(DISTINCT txn_id)` with percentage calculation                               |
|                             | 10. Most common 3-product combination in transactions                                 | Self-joining CTE thrice with `<` conditions to avoid duplicates, `COUNT(*)` for frequency                             |
| **Bonus Challenge**           | Transform `product_hierarchy` and `product_prices` into `product_details`             | Recursive joins on `product_hierarchy` (3x) to link style-segment-category, `CONCAT()` for product names              |

---


This table provides a concise overview of the analytical approaches and SQL tools employed to address each business question.
