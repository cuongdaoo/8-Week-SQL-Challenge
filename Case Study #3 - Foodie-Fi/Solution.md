# Challenge Case Study 3 - Foodie-Fi

# **Relationship Diagram**
![image](https://github.com/user-attachments/assets/5e092dcc-8f2f-472e-bd79-df69fac8411a)

# **Data preview**
![image](https://github.com/user-attachments/assets/e7fdecba-0218-451c-8e33-3a1c258ed6ad)
![image](https://github.com/user-attachments/assets/adc788cf-1315-4fab-a031-3c456eea034c)
# **Solution**
## A. Customer Journey

## B. Data Analysis Questions
**1. How many customers has Foodie-Fi ever had?**  
Idea: Count distinct `customer_id` values to get the total number of unique customers.  
```sql
SELECT COUNT(DISTINCT customer_id) AS unique_customers 
FROM subscriptions;
```
Output:
\
![image](https://github.com/user-attachments/assets/b78f5ca1-719a-432f-bba0-64052763fdca)


**2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value**  
Idea: Extract the month from the `start_date` and group by it while filtering for the trial plan.  
```sql
SELECT MONTH(start_date) AS month, COUNT(price) AS monthly_distribute 
FROM subscriptions s 
JOIN plans p ON p.plan_id = s.plan_id 
WHERE plan_name = 'trial' 
GROUP BY MONTH(start_date);
```
Output:  
\
![image](https://github.com/user-attachments/assets/830173d4-5f47-4e5a-a1b0-5db2268fecfa)

**3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name**  
Idea: Filter `start_date` for values after 2020 and group by `plan_name` for the count.  
```sql
SELECT plan_name, COUNT(*) AS distribute 
FROM subscriptions s 
JOIN plans p ON p.plan_id = s.plan_id 
WHERE YEAR(start_date) > 2020 
GROUP BY plan_name;
```
Output:  
\
![image](https://github.com/user-attachments/assets/61077039-feb4-4bac-a36a-7f6619d648e2)


**4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?**  
Idea: Filter for churned customers, count them, and calculate the percentage against all unique customers.  
```sql
SELECT plan_name, 
       COUNT(*) AS distribute, 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS "percentage of customers" 
FROM subscriptions s 
JOIN plans p ON p.plan_id = s.plan_id 
WHERE plan_name = 'churn' 
GROUP BY plan_name;
```
Output:  
\
![image](https://github.com/user-attachments/assets/1450580b-2d78-4124-9b3c-b41731a69017)

**5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?**  
Idea: Use a window function to identify customers whose next plan after the trial is churn and calculate their percentage.  
```sql
WITH cte AS (
    SELECT s.customer_id, 
           p.plan_name, 
           LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.plan_id) AS next_plan 
    FROM subscriptions s 
    JOIN plans p ON s.plan_id = p.plan_id
)
SELECT COUNT(*) AS "customers have churned straight after their initial free trial", 
       ROUND(100 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) AS "percentage of customers" 
FROM cte 
WHERE plan_name = 'trial' AND next_plan = 'churn';
```
Output:  
\
![image](https://github.com/user-attachments/assets/0fe3d63b-83ec-4f58-99fc-b7ff7a3a06e5)

**6. What is the number and percentage of customer plans after their initial free trial?**  
Idea: Use a window function to identify plans that follow a trial and group by those plans.  
```sql
WITH cte AS (
    SELECT s.customer_id, 
           p.plan_name, 
           LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.plan_id) AS next_plan 
    FROM subscriptions s 
    JOIN plans p ON s.plan_id = p.plan_id
)
SELECT next_plan, 
       COUNT(*) AS "customers after their initial free trial", 
       ROUND(100 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) AS "percentage of customers" 
FROM cte 
WHERE plan_name = 'trial' AND next_plan IS NOT NULL 
GROUP BY next_plan;
```
Output:  
\
![image](https://github.com/user-attachments/assets/2d5691b4-14cc-4f49-8a54-f97fcb2fc2d0)

**7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?**  
Idea: Use window functions to track active plans and group by `plan_name` before or after the cutoff date.  
```sql
WITH cte AS (
    SELECT s.customer_id, 
           p.plan_name, 
           LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date 
    FROM subscriptions s 
    JOIN plans p ON s.plan_id = p.plan_id
)
SELECT plan_name, 
       COUNT(*) AS customers, 
       ROUND(CAST(100 * COUNT(*) AS FLOAT) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS percentage 
FROM cte 
WHERE (next_date IS NOT NULL AND (start_date < '2020-12-31' AND next_date > '2020-12-31')) 
   OR (next_date IS NULL AND start_date > '2020-12-31') 
GROUP BY plan_name;
```
Output:  
\
![image](https://github.com/user-attachments/assets/25d4c558-1300-448b-9bd8-fcef3d1d079a)

**8. How many customers have upgraded to an annual plan in 2020?**  
Idea: Filter for customers with `pro annual` plans starting in 2020 and count them.  
```sql
SELECT COUNT(DISTINCT customer_id) AS customer_2020_proannual 
FROM subscriptions s 
JOIN plans p ON p.plan_id = s.plan_id 
WHERE plan_name = 'pro annual' AND YEAR(start_date) = 2020;
```
Output:  
\
![image](https://github.com/user-attachments/assets/90d35f34-1c3a-49a2-9992-7fb3b929513f)

**9. How many days on average does it take for a customer to move to an annual plan from the day they join Foodie-Fi?**  
Idea: Calculate the date difference between trial and annual plans for each customer and compute the average.  
```sql
WITH trialplan AS (
    SELECT customer_id, start_date AS trial_date 
    FROM subscriptions s 
    JOIN plans p ON p.plan_id = s.plan_id 
    WHERE plan_name = 'trial'
), 
annualplan AS (
    SELECT customer_id, start_date AS annual_date 
    FROM subscriptions s 
    JOIN plans p ON p.plan_id = s.plan_id 
    WHERE plan_name = 'pro annual'
)
SELECT AVG(CAST(DATEDIFF(D, trial_date, annual_date) AS FLOAT)) AS avg_date 
FROM trialplan t 
JOIN annualplan a ON t.customer_id = a.customer_id;
```
Output:  
\
![image](https://github.com/user-attachments/assets/f7931e6d-d21f-40e7-aacb-585876dd5448)

**10. Can you further breakdown this average value into 30-day periods (i.e., 0-30 days, 31-60 days, etc.)?**  
Idea: Use recursive CTE to define 30-day periods and join with date differences to count customers in each range.  
```sql
WITH trialplan AS (
    SELECT customer_id, start_date AS trial_date 
    FROM subscriptions s 
    JOIN plans p ON p.plan_id = s.plan_id 
    WHERE plan_name = 'trial'
), 
annualplan AS (
    SELECT customer_id, start_date AS annual_date 
    FROM subscriptions s 
    JOIN plans p ON p.plan_id = s.plan_id 
    WHERE plan_name = 'pro annual'
), 
dateif AS (
    SELECT t.customer_id, DATEDIFF(D, trial_date, annual_date) AS diff 
    FROM trialplan t 
    JOIN annualplan a ON t.customer_id = a.customer_id
), 
cte AS (
    SELECT 0 AS start_period, 30 AS end_period 
    UNION ALL 
    SELECT end_period + 1 AS start_period, end_period + 30 AS end_period 
    FROM cte 
    WHERE end_period < 360
)
SELECT start_period, end_period, COUNT(*) AS amount 
FROM cte 
JOIN dateif d ON d.diff >= start_period AND d.diff <= end_period 
GROUP BY start_period, end_period;
```
Output:  
\
![image](https://github.com/user-attachments/assets/5202f084-dc10-4b30-b9d3-41ce70e96d13)

**11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?**  
Idea: Match customers transitioning from `pro monthly` to `basic monthly` and count them.  
```sql
WITH pro_month AS (
    SELECT customer_id, start_date AS pro_month_date 
    FROM subscriptions s 
    JOIN plans p ON p.plan_id = s.plan_id 
    WHERE plan_name = 'pro monthly'
), 
basic_month AS (
    SELECT customer_id, start_date AS basic_month_date 
    FROM subscriptions s 
    JOIN plans p ON p.plan_id = s.plan_id 
    WHERE plan_name = 'basic monthly'
)
SELECT COUNT(*) AS pro_to_basic_monthly 
FROM pro_month p 
JOIN basic_month b ON p.customer_id = b.customer_id AND pro_month_date < basic_month_date 
WHERE YEAR(pro_month_date) = 2020 AND YEAR(basic_month_date) = 2020;
```
Output:  
\
![image](https://github.com/user-attachments/assets/4d10bff9-bb65-40cb-b830-ca46852c2a7c)
