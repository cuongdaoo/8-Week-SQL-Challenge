# Case Study #8 - Fresh Segments
<p align="center">
<img src="https://github.com/user-attachments/assets/9d1dbbaa-218f-4eb7-9136-f76f32da65e0" align="center" width="400" height="400" >

A structured summary table capturing the SQL methods and techniques applied for each objective across categories:
Here's the summary table capturing the applied methods and techniques for each aspect of the SQL analysis:

### Summary of SQL Methods and Techniques

| Category                  | Objective                                                                 | SQL Method/Technique Applied                                                                 |
|---------------------------|---------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| **Data Exploration**      | Convert month_year to DATE type                                           | `CONVERT()` with style code 105, `ALTER COLUMN`                                             |
|                           | Count records by month_year                                               | `COUNT()` with `GROUP BY` and `ORDER BY`                                                    |
|                           | Handle NULL values                                                        | Subquery percentage calculation                                                             |
|                           | Identify interest_id discrepancies                                        | `NOT IN` with subqueries, `DISTINCT` counts                                                 |
|                           | Count records in interest_map                                             | Simple `COUNT(*)` aggregation                                                               |
|                           | Determine optimal join approach                                           | `LEFT JOIN` demonstration with column selection                                             |
|                           | Validate temporal consistency                                             | Date comparison with `COUNT()`                                                              |
| **Interest Analysis**     | Find interests present in all months                                      | `COUNT()` with `HAVING` and subquery for total months                                       |
|                           | Calculate cumulative percentage by tenure                                 | CTEs with window functions (`SUM() OVER`)                                                   |
|                           | Assess impact of removing low-tenure interests                           | Filtered counts using CTE results                                                           |
|                           | Business decision validation                                             | Percentage impact calculation with joined CTEs                                              |
|                           | Count unique interests per month post-filter                             | Filtered dataset with `COUNT(DISTINCT)`                                                     |
| **Segment Analysis**      | Create filtered dataset                                                  | Temporary table creation with `SELECT INTO` from CTE                                        |
|                           | Identify top/bottom composition values                                   | `TOP 10` with `ORDER BY` (ASC/DESC)                                                         |
|                           | Find lowest average rankings                                             | `AVG()` with `ROUND(CAST())` and `TOP 5`                                                    |
|                           | Identify volatile interests                                              | `STDEV()` calculation with rounding                                                         |
|                           | Analyze min/max percentile rankings                                      | Window functions (`MAX/MIN OVER`) with CTEs                                                 |
|                           | Make customer segment recommendations                                    | Business interpretation of composition/ranking patterns                                    |
| **Index Analysis**        | Calculate average composition                                            | Division operation (`composition/index_value`)                                              |
|                           | Rank interests monthly                                                   | `RANK() OVER(PARTITION BY month_year)`                                                      |
|                           | Find most frequent top performers                                        | `COUNT()` with `GROUP BY` on ranked results                                                 |
|                           | Calculate monthly averages of top 10                                     | `AVG()` on filtered ranked data                                                             |
|                           | Compute 3-month rolling averages                                        | Window frame (`ROWS BETWEEN 2 PRECEDING`), `LAG()` for prior values                         |
|                           | Format historical references                                             | `CONCAT()` with `LAG()` for combined name/value display                                     |
|  | Explain composition changes                                            | Seasonal pattern analysis based on interest types and timing                                |
