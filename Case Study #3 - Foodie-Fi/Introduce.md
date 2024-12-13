## 🥑 Case Study #3 - Foodie-Fi
<p align="center">
<img src="https://github.com/qanhnn12/8-Week-SQL-Challenge/blob/main/IMG/3.png" align="center" width="400" height="400" >

The summary table based on your SQL analysis tasks:  

| **Category**               | **Objective**                                                                                     | **SQL Method/Technique Applied**                                                                                   |
|----------------------------|--------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| **A. Customer Journey**    | Provide a brief description of each customer's onboarding journey based on the subscriptions table. | Join `subscriptions` with other tables to gather details; used `LEAD()` for sequential plan details.               |
| **B. Data Analysis Questions** |                                                                                              |                                                                                                                    |
| 1. Customer Count          | Count distinct customers ever in Foodie-Fi.                                                     | `SELECT COUNT(DISTINCT customer_id)`                                                                               |
| 2. Monthly Trial Plan Distribution | Group trial plan start dates by month.                                                           | Join `subscriptions` with `plans`, `GROUP BY MONTH(start_date)`.                                                  |
| 3. Post-2020 Plan Distribution | Count plan start events after 2020, grouped by plan.                                               | Join `subscriptions` with `plans`, filter `YEAR(start_date) > 2020`, `GROUP BY plan_name`.                         |
| 4. Churned Customer Count  | Calculate churned customers and percentage.                                                      | Filter `plan_name = 'churn'`, calculate percentage with total customers.                                           |
| 5. Churn After Trial       | Count and percentage of customers who churned after the free trial.                              | Use `LEAD()` to track plan transitions, filter `plan_name = 'trial'` and `next_plan = 'churn'`.                    |
| 6. Post-Trial Plan Distribution | Count and percentage of plans customers transitioned to after the trial.                          | Use `LEAD()` for next plans, filter `plan_name = 'trial'` and `next_plan IS NOT NULL`.                             |
| 7. 2020 Plan Breakdown     | Count and percentage breakdown of all plans at 2020-12-31.                                       | Use `LEAD()` to identify active plans around 2020-12-31.                                                           |
| 8. Annual Plan Upgrades    | Count customers upgrading to annual plans in 2020.                                              | Filter `plan_name = 'pro annual'` and `YEAR(start_date) = 2020`.                                                   |
| 9. Days to Annual Plan     | Calculate average days from joining to upgrading to an annual plan.                              | Use `DATEDIFF()` between trial and annual plan dates, compute average.                                             |
| 10. Average Days Breakdown | Breakdown average days to annual plan into 30-day intervals.                                     | Use `DATEDIFF()` for differences, create intervals using recursive `CTE`, count customers per interval.            |
| 11. Downgrade Analysis     | Count customers downgrading from pro monthly to basic monthly in 2020.                          | Filter transitions from `pro monthly` to `basic monthly`, check `YEAR(start_date) = 2020` for both plans.          |
| 12. Payment Details        | Track customer payments, including recurring payments.                                          | Recursive `CTE` to calculate monthly payments until the last payment date.                                         |
