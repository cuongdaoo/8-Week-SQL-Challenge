# Case Study #1 - Danny's Diner
![image](https://github.com/user-attachments/assets/04f69f55-715c-485e-86d0-c9c2bf2bb25f)

A summary table of the applied methods and SQL techniques for each query:

| **#** | **Query**                                                         | **Method**                                                     | **SQL Techniques**                                                                                  |
|-------|--------------------------------------------------------------------|----------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| 1     | Total amount each customer spent                                   | Summing (`SUM`) the price of items each customer purchased      | `JOIN`, `GROUP BY`, `SUM`                                                                            |
| 2     | Number of days each customer visited the restaurant                | Counting distinct days (`COUNT(DISTINCT)`) each customer visited | `GROUP BY`, `COUNT(DISTINCT)`                                                                        |
| 3     | First item purchased by each customer                              | Using window function (`ROW_NUMBER()`) to find the first item   | CTE, `ROW_NUMBER()`, `PARTITION BY`, `ORDER BY`                                                      |
| 4     | Most purchased item on the menu and number of times purchased      | Counting the number of times each item was purchased and selecting the most popular | `JOIN`, `GROUP BY`, `ORDER BY`, `TOP 1`                                                              |
| 5     | Most popular item for each customer                                | Using ranking function (`RANK()`) to determine the most purchased item for each customer | `RANK()`, `PARTITION BY`, `GROUP BY`, `ORDER BY`                                                     |
| 6     | First item purchased after becoming a member                       | Using window function to find the first purchase after membership join date | CTE, `ROW_NUMBER()`, `JOIN`, `PARTITION BY`, `ORDER BY`                                              |
| 7     | Item purchased before becoming a member                            | Identifying the last item purchased before membership           | CTE, `ROW_NUMBER()`, `JOIN`, `ORDER BY DESC`                                                         |
| 8     | Total items and amount spent before becoming a member              | Summing the total number of items and amount spent before membership | `JOIN`, `LEFT JOIN`, `COUNT`, `SUM`, `GROUP BY`                                                      |
| 9     | Points calculation with sushi multiplier                           | Calculating points for each purchase, with a 2x multiplier for sushi | `CASE WHEN`, `JOIN`, `GROUP BY`, `SUM`                                                               |
| 10    | Points for customers A and B with 2x points in the first week after joining | Applying a 2x multiplier for all purchases in the first week after joining | `CASE WHEN`, `DATEADD()`, `JOIN`, `GROUP BY`, `SUM`                                                  |

This table summarizes the queries, methods, and SQL techniques used to solve each specific task.
