

# Data Exploration and Cleansing

### 1. Update the month_year column to a date data type
**Explanation:**  
We need to convert the `month_year` column from a string format to a proper DATE data type. The original format appears to be 'MM-YYYY', so we'll prepend '01-' to make it a valid date (first day of each month). The CONVERT function with style code 105 handles the 'DD-MM-YYYY' format. After updating the values, we alter the column's data type to DATE.

**SQL Code:**
```sql
UPDATE interest_metrics
SET month_year = CONVERT(DATE, '01-' + month_year, 105);

ALTER TABLE interest_metrics
ALTER COLUMN month_year DATE;

SELECT * FROM interest_metrics;
```

**Answer:**

---

### 2. Count of records for each month_year value
**Explanation:**  
This query counts records grouped by month_year to understand data distribution over time. We sort chronologically with NULL values first to identify any missing data periods. The COUNT(*) function aggregates records per month, while ORDER BY ensures proper temporal sequence.

**SQL Code:**
```sql
SELECT 
    month_year, 
    COUNT(*) AS record_count 
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year ASC;
```

**Answer:**

---

### 3. Handling null values in interest_metrics
**Explanation:**  
We analyze the proportion of NULL values in month_year to determine appropriate handling. The subquery calculates total records, while the main query computes the percentage of NULLs. With 8% NULL values, removing them would have minimal impact on analysis while improving data quality.

**SQL Code:**
```sql
SELECT 
    100.0 * COUNT(*) / (SELECT COUNT(*) FROM interest_metrics) AS percent_null_values
FROM interest_metrics
WHERE month_year IS NULL;
```

**Answer:**  
We should drop these null values because they contain 8% of total values, which would not significantly affect the final results.

---

### 4. Interest_id discrepancies between tables
**Explanation:**  
We identify data consistency issues by checking:
1. Interest_ids in metrics not found in map table (orphaned records)
2. IDs in map table not referenced in metrics (unused definitions)

The NOT IN clauses with subqueries find these discrepancies, while DISTINCT ensures unique counts.

**SQL Code:**
```sql
-- Exist in interest_metrics but not in interest_map
SELECT COUNT(DISTINCT interest_id) 
FROM interest_metrics
WHERE interest_id NOT IN (SELECT DISTINCT id FROM interest_map) 
  AND interest_id IS NOT NULL;

-- Exist in interest_map but not in interest_metrics
SELECT COUNT(DISTINCT id) 
FROM interest_map
WHERE id NOT IN (
    SELECT DISTINCT interest_id 
    FROM interest_metrics 
    WHERE interest_id IS NOT NULL
);
```

**Answer:**

---

### 5. Summary of id values in interest_map
**Explanation:**  
This simple aggregation counts all records in the interest_map table, providing a baseline for understanding the total number of interest definitions available in the dataset.

**SQL Code:**
```sql
SELECT COUNT(*) AS count_id 
FROM interest_map;
```

**Answer:**

---

### 6. Optimal table join for analysis
**Explanation:**  
A LEFT JOIN preserves all valid interest_id records from the metrics table while bringing in supplemental information from the map table. We exclude the redundant id column from the map table. The WHERE clause demonstrates the join logic for a specific interest_id.

**SQL Code:**
```sql
SELECT 
    metrics.*,
    map.interest_name,
    map.interest_summary,
    map.created_at,
    map.last_modified
FROM interest_metrics metrics
LEFT JOIN interest_map map
    ON metrics.interest_id = map.id
WHERE metrics.interest_id = 21246;
```

**Answer:**  
We should perform LEFT JOIN between interest_metrics and interest_map because only available interest_id in the metrics table are meaningful for analysis.

---

### 7. Records with month_year before created_at
**Explanation:**  
We validate temporal consistency by checking if any recorded metrics exist before the interest was defined. The COUNT reveals how many records have this anomaly. The 188 affected records might be valid if created in the same month (due to first-day month_year values).

**SQL Code:**
```sql
SELECT COUNT(*) AS count_record
FROM interest_metrics metrics
LEFT JOIN interest_map map
    ON metrics.interest_id = map.id
WHERE month_year < created_at;
```

**Answer:**  
There are 188 month_year values before created_at dates. These may be valid if created in the same month, since month_year uses first-day values.

---

# Interest Analysis

### 1. Interests present in all month_year dates
**Explanation:**  
This query identifies "complete" interests by counting distinct months per interest and comparing to the total available months. The HAVING clause filters for interests present in all months, while the JOIN connects IDs to names.

**SQL Code:**
```sql
SELECT 
    interest_name, 
    COUNT(month_year) AS id_count 
FROM interest_metrics met
LEFT JOIN interest_map map 
    ON met.interest_id = map.id
WHERE month_year IS NOT NULL
GROUP BY interest_name
HAVING COUNT(month_year) >= (
    SELECT COUNT(DISTINCT month_year) 
    FROM interest_metrics
)
ORDER BY id_count DESC;
```

**Answer:**

---

### 2. Cumulative percentage by total_months
**Explanation:**  
The CTE pipeline:
1. Counts months per interest
2. Aggregates interest counts by total_months
3. Calculates running percentage
We identify where the cumulative percentage crosses 90% to find the cutoff point for meaningful data.

**SQL Code:**
```sql
WITH cte AS (
    SELECT 
        interest_id, 
        COUNT(month_year) AS id_count 
    FROM interest_metrics 
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
),
cte2 AS (
    SELECT 
        id_count AS total_months, 
        COUNT(interest_id) AS interest_count 
    FROM cte
    GROUP BY id_count
)
SELECT 
    *,
    ROUND(
        CAST(SUM(interest_count) OVER (
            ORDER BY total_months DESC
        ) * 100.0 / (SELECT SUM(interest_count) FROM cte2) AS FLOAT
    , 2) AS cumulative_percent 
FROM cte2
ORDER BY total_months DESC;
```

**Answer:**  
Interests with ≥6 months reach 90% cumulative percentage. Lower-duration interests should be investigated for improvement.

# Segment Analysis  

### 1. Top 10 and Bottom 10 Interests by Maximum Composition  
**Explanation:**  
After filtering out interests with less than 6 months of data, we identify the highest and lowest composition values. The `sub_interest_metrics` table is created to store filtered data. We then query the top and bottom 10 records based on `composition`, retaining their corresponding `month_year`.  

**SQL Code:**  
```sql
-- Create filtered dataset (interests with ≥6 months of data)  
WITH cte AS (  
    SELECT interest_id, COUNT(month_year) AS id_count  
    FROM interest_metrics  
    WHERE month_year IS NOT NULL  
    GROUP BY interest_id  
    HAVING COUNT(month_year) < 6  
)  

SELECT *  
INTO sub_interest_metrics  
FROM interest_metrics  
WHERE interest_id NOT IN (SELECT interest_id FROM cte);  

-- Top 10  
SELECT TOP 10  
    month_year,  
    interest_id,  
    composition  
FROM sub_interest_metrics sub_met  
LEFT JOIN interest_map map   
    ON sub_met.interest_id = map.id  
WHERE month_year IS NOT NULL  
ORDER BY composition DESC;  

-- Bottom 10  
SELECT TOP 10  
    month_year,  
    interest_id,  
    composition  
FROM sub_interest_metrics sub_met  
LEFT JOIN interest_map map   
    ON sub_met.interest_id = map.id  
WHERE month_year IS NOT NULL  
ORDER BY composition ASC;  
```  

**Answer:**  

---  

### 2. 5 Interests with Lowest Average Ranking  
**Explanation:**  
We calculate the average `ranking` for each interest and identify the 5 with the lowest values (indicating better performance). The `ROUND(CAST(...))` ensures clean numeric formatting.  

**SQL Code:**  
```sql
SELECT TOP 5  
    interest_id,  
    ROUND(CAST(AVG(ranking * 1.0) AS FLOAT), 2) AS avg_rank  
FROM sub_interest_metrics sub_met  
LEFT JOIN interest_map map   
    ON sub_met.interest_id = map.id  
WHERE month_year IS NOT NULL  
GROUP BY interest_id  
ORDER BY avg_rank ASC;  
```  

**Answer:**  

---  

### 3. 5 Interests with Largest Standard Deviation in Percentile Ranking  
**Explanation:**  
High standard deviation in `percentile_ranking` indicates volatile performance. We use `STDEV()` to measure variability and return the top 5 interests.  

**SQL Code:**  
```sql
SELECT TOP 5  
    interest_id,  
    ROUND(CAST(STDEV(percentile_ranking * 1.0) AS FLOAT), 2) AS std_per_ranking  
FROM sub_interest_metrics sub_met  
LEFT JOIN interest_map map   
    ON sub_met.interest_id = map.id  
WHERE month_year IS NOT NULL  
GROUP BY interest_id  
ORDER BY std_per_ranking DESC;  
```  

**Answer:**  

---  

### 4. Min/Max Percentile Rankings for Volatile Interests  
**Explanation:**  
For the 5 interests identified in Q3, we find their extreme `percentile_ranking` values and corresponding months. Window functions (`MAX() OVER` and `MIN() OVER`) efficiently compute these without multiple queries.  

**SQL Code:**  
```sql
WITH std_cte AS (  
    SELECT TOP 5  
        interest_id,  
        ROUND(CAST(STDEV(percentile_ranking * 1.0) AS FLOAT), 2) AS std_per_ranking  
    FROM sub_interest_metrics sub_met  
    LEFT JOIN interest_map map   
        ON sub_met.interest_id = map.id  
    WHERE month_year IS NOT NULL  
    GROUP BY interest_id  
    ORDER BY std_per_ranking DESC  
),  
maxmin_cte AS (  
    SELECT  
        month_year,  
        interest_name,  
        percentile_ranking,  
        MAX(percentile_ranking) OVER (PARTITION BY interest_id) AS max_percentile_ranking,  
        MIN(percentile_ranking) OVER (PARTITION BY interest_id) AS min_percentile_ranking  
    FROM sub_interest_metrics sub_met  
    LEFT JOIN interest_map map   
        ON sub_met.interest_id = map.id  
    WHERE interest_id IN (SELECT interest_id FROM std_cte)  
)  

SELECT  
    month_year,  
    interest_name,  
    percentile_ranking  
FROM maxmin_cte  
WHERE percentile_ranking = max_percentile_ranking   
    OR percentile_ranking = min_percentile_ranking  
ORDER BY interest_name, percentile_ranking DESC;  
```  

**Answer:**  
Because these 5 interests had the largest standard deviation, the gap between their max and min percentile rankings is significant, indicating highly variable performance over time.  

---  

### 5. Customer Segment Recommendations  
**Explanation:**  
Based on composition and ranking trends, we should:  
- **Promote:** Products/services aligned with consistently high-ranking interests (e.g., travel planners during peak seasons).  
- **Avoid:** Items related to interests with volatile rankings or low composition values.  

**Answer:**  

---  

# Index Analysis  

### 1. Top 10 Interests by Average Composition per Month  
**Explanation:**  
The average composition is derived by dividing `composition` by `index_value`. We rank interests monthly using `RANK()`, then filter the top 10 per month.  

**SQL Code:**  
```sql
WITH cte AS (  
    SELECT  
        month_year,  
        interest_id,  
        ROUND(CAST(composition / index_value AS FLOAT), 2) AS avg_com  
    FROM interest_metrics met  
    LEFT JOIN interest_map map   
        ON met.interest_id = map.id  
    WHERE month_year IS NOT NULL  
),  
cte2 AS (  
    SELECT  
        *,  
        RANK() OVER (PARTITION BY month_year ORDER BY avg_com DESC) AS rank_avg_com  
    FROM cte  
)  

SELECT * FROM cte2  
WHERE rank_avg_com <= 10;  
```  

**Answer:**  

---  

### 2. Most Frequent Top 10 Interest  
**Explanation:**  
We count how often each interest appears in the monthly top 10 lists. The `interest_name` is included for clarity.  

**SQL Code:**  
```sql
WITH cte AS (  
    SELECT  
        month_year,  
        interest_name,  
        ROUND(CAST(composition / index_value AS FLOAT), 2) AS avg_com  
    FROM interest_metrics met  
    LEFT JOIN interest_map map   
        ON met.interest_id = map.id  
    WHERE month_year IS NOT NULL  
),  
cte2 AS (  
    SELECT  
        *,  
        RANK() OVER (PARTITION BY month_year ORDER BY avg_com DESC) AS rank_avg_com  
    FROM cte  
)  

SELECT  
    interest_name,  
    COUNT(*) AS count_id  
FROM cte2  
WHERE rank_avg_com <= 10  
GROUP BY interest_name  
ORDER BY count_id DESC;  
```  

**Answer:**  

---  

### 3. Average of Top 10 Compositions per Month  
**Explanation:**  
For each month, we calculate the mean average composition across its top 10 interests. This shows overall engagement trends.  

**SQL Code:**  
```sql
WITH cte AS (  
    SELECT  
        month_year,  
        interest_name,  
        ROUND(CAST(composition / index_value AS FLOAT), 2) AS avg_com  
    FROM interest_metrics met  
    LEFT JOIN interest_map map   
        ON met.interest_id = map.id  
    WHERE month_year IS NOT NULL  
),  
cte2 AS (  
    SELECT  
        *,  
        RANK() OVER (PARTITION BY month_year ORDER BY avg_com DESC) AS rank_avg_com  
    FROM cte  
)  

SELECT  
    month_year,  
    AVG(avg_com) AS avg_top_10_composition  
FROM cte2  
WHERE rank_avg_com <= 10  
GROUP BY month_year  
ORDER BY month_year;  
```  

**Answer:**  

---  

### 4. 3-Month Rolling Average of Max Composition (Sep 2018–Aug 2019)  
**Explanation:**  
This complex query:  
1. Identifies the top interest per month by average composition.  
2. Computes a 3-month rolling average using window functions.  
3. Uses `LAG()` to reference previous months' top interests and values.  

**SQL Code:**  
```sql
WITH cte AS (  
    SELECT  
        month_year,  
        interest_name,  
        ROUND(CAST(composition / index_value AS FLOAT), 2) AS avg_com  
    FROM interest_metrics met  
    LEFT JOIN interest_map map   
        ON met.interest_id = map.id  
    WHERE month_year IS NOT NULL  
),  
cte2 AS (  
    SELECT  
        *,  
        RANK() OVER (PARTITION BY month_year ORDER BY avg_com DESC) AS rank_avg_com  
    FROM cte  
),  
cte3 AS (  
    SELECT  
        month_year,  
        interest_name,  
        AVG(avg_com) AS max_avg_composition  
    FROM cte2  
    WHERE rank_avg_com = 1  
    GROUP BY month_year, interest_name  
),  
cte4 AS (  
    SELECT  
        *,  
        ROUND(AVG(max_avg_composition) OVER (  
            ORDER BY month_year  
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW  
        ), 2) AS moving_3_month_avg  
    FROM cte3  
),  
lag_cte AS (  
    SELECT  
        *,  
        ROUND(LAG(max_avg_composition, 1) OVER (ORDER BY month_year), 2) AS m_1,  
        ROUND(LAG(max_avg_composition, 2) OVER (ORDER BY month_year), 2) AS m_2,  
        CONCAT(  
            LAG(interest_name, 1) OVER (ORDER BY month_year),  
            ':',  
            ROUND(LAG(max_avg_composition, 1) OVER (ORDER BY month_year), 2)  
        ) AS '1_month_ago',  
        CONCAT(  
            LAG(interest_name, 2) OVER (ORDER BY month_year),  
            ':',  
            ROUND(LAG(max_avg_composition, 2) OVER (ORDER BY month_year), 2)  
        ) AS '2_month_ago'  
    FROM cte4  
)  

SELECT  
    month_year,  
    interest_name,  
    max_avg_composition,  
    moving_3_month_avg,  
    [1_month_ago],  
    [2_month_ago]  
FROM lag_cte  
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';  
```  

**Answer:**  

---  

### 5. Business Implications of Changing Max Composition  
**Explanation:**  
Possible Reason for Month-to-Month Changes:
Seasonal Behavior Shifts: Certain interest segments like “Alabama Trip Planners” or “Las Vegas Trip Planners” may spike during specific times of the year (e.g., summer or holidays), affecting the monthly composition.
