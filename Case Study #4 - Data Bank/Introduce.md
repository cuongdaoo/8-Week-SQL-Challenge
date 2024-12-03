# Case Study #4 - Data Bank
<p align="center">
<img src="https://github.com/user-attachments/assets/916a6e24-6692-4639-b0d8-1952abb45de3" align="center" width="400" height="400" >

A summary table that captures the applied methods and techniques for different aspects of the SQL analysis:

| **Category**            | **Objective**                                                              | **SQL Method/Technique Applied**                                                                 |
|--------------------------|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| **A.Customer Nodes Exploration** |                                                                                     |                                                                                                   |
|1. Unique Nodes Count       | Determine the total unique nodes in the system                             | `COUNT(DISTINCT)` to count unique `node_id`                                                      |
|2. Nodes Per Region         | Count the number of nodes allocated to each region                        | `JOIN`, `GROUP BY`, and `ORDER BY`                                                               |
|3. Customers Per Region     | Count distinct customers in each region                                   | `COUNT(DISTINCT)` combined with `JOIN`, `GROUP BY`, and `ORDER BY`                               |
|4. Average Reallocation Days| Calculate average days customers are reallocated                         | Use of `WITH` CTE, `LEAD` window function, and `DATEDIFF` for date difference calculation        |
|5. Percentiles Per Region   | Calculate median, 80th, and 95th percentiles for reallocation days        | `PERCENTILE_CONT` with `OVER(PARTITION BY)` for percentile calculations                          |
| **B.Customer Transactions** |                                                                                     |                                                                                                   |
|1. Transaction Summary      | Determine unique transaction counts and total amounts by type            | `COUNT`, `SUM`, and `GROUP BY` based on `txn_type`                                               |
|2. Average Deposit Metrics  | Compute average deposit count and amount for customers                   | `AVG`, `COUNT`, and `WITH` CTE for grouping customer-level data                                  |
|3. Monthly Active Customers | Count customers meeting specific transaction thresholds per month        | Conditional aggregation using `CASE`, and `GROUP BY` with logical filtering                      |
|4. Closing Balances         | Compute monthly closing balances for each customer                       | `WITH` CTE, conditional aggregation with `CASE`, and `LAG` for previous balance tracking         |
|5. Balance Growth Analysis  | Determine percentage of customers with >5% closing balance growth        | Window functions (`FIRST_VALUE`, `LAST_VALUE`) and percentage growth calculation with filtering |

