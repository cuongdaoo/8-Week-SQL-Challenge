# Challenge Case Study #6 - Clique Bait

# B. Digital Analysis

## 1. How many users are there?
**Explanation:** Calculate the total number of unique users in the `users` table.
```sql
SELECT COUNT(DISTINCT user_id) AS total_users FROM users;
```
**Answer:** ![image](https://github.com/user-attachments/assets/ce8a16fe-9531-43b7-9a50-400ed7d8fc20)


## 2. How many cookies does each user have on average?
**Explanation:** Calculate the average number of cookies per user.
```sql
SELECT COUNT(DISTINCT user_id) AS total_users, 
       COUNT(cookie_id) AS total_cookies, 
       CAST(COUNT(cookie_id) AS FLOAT) / CAST(COUNT(DISTINCT user_id) AS FLOAT) AS avg_cookies
FROM users;
```
**Answer:** ![image](https://github.com/user-attachments/assets/54002817-8a43-43e5-94b7-b482093153dc)


## 3. What is the unique number of visits by all users per month?
**Explanation:** Count the number of unique visits by all users per month.
```sql
SELECT DATEPART(MONTH, event_time) AS month, 
       COUNT(DISTINCT visit_id) AS total_visit 
FROM events
GROUP BY DATEPART(MONTH, event_time)
ORDER BY total_visit DESC;
```
**Answer:** ![image](https://github.com/user-attachments/assets/99ca5a17-9f1d-4f82-8c1e-d872fbb2d9d1)


## 4. What is the number of events for each event type?
**Explanation:** Count the occurrences of each event type.
```sql
SELECT event_name, 
       COUNT(e.event_type) AS amount_event 
FROM events e
JOIN event_identifier ei ON e.event_type = ei.event_type
GROUP BY event_name
ORDER BY amount_event DESC;
```
**Answer:** ![image](https://github.com/user-attachments/assets/c0462147-f206-468d-82c9-1984d3ec97ef)


## 5. What is the percentage of visits that have a purchase event?
**Explanation:** Calculate the percentage of visits that include a purchase event.
```sql
SELECT event_name, 
       100 * CAST(COUNT(e.visit_id) AS FLOAT) / CAST((SELECT COUNT(DISTINCT visit_id) FROM events) AS FLOAT) AS amount_visit
FROM events e
JOIN event_identifier ei ON e.event_type = ei.event_type
WHERE event_name = 'Purchase'
GROUP BY event_name;
```
**Answer:** ![image](https://github.com/user-attachments/assets/484f17cd-d650-440c-9d14-380ce91809cc)

## 6. What is the percentage of visits that view the checkout page but do not have a purchase event?
**Explanation:** Calculate the percentage of users who visit the checkout page but do not make a purchase.
```sql
WITH cte AS (
    SELECT SUM(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END) AS amount_purchase,
           SUM(CASE WHEN page_name = 'Checkout' THEN 1 ELSE 0 END) AS amount_checkout
    FROM events e
    JOIN event_identifier ei ON e.event_type = ei.event_type
    JOIN page_hierarchy p ON p.page_id = e.page_id
    WHERE event_name = 'Purchase' OR page_name = 'Checkout'
)
SELECT 100 * (CAST((amount_checkout - amount_purchase) AS FLOAT) / CAST(amount_checkout AS FLOAT)) AS percent_not_purchase 
FROM cte;
```
**Answer:** ![image](https://github.com/user-attachments/assets/a18c468d-06af-416a-bb7e-d08a867abb7a)

## 7. Top 3 Most Viewed Pages
   - **Explanation:** Retrieves the three most visited pages.
   - **SQL Code:**
     ```sql
     SELECT TOP 3 page_name, 
                   COUNT(e.page_id) AS views 
     FROM events e 
     JOIN page_hierarchy p ON p.page_id = e.page_id 
     GROUP BY page_name 
     ORDER BY views DESC;
     ```
   - **Answer:** ![image](https://github.com/user-attachments/assets/41703829-d779-4301-828e-6de182d7f333)


## 8. Views and Cart Adds by Product Category
   - **Explanation:** Calculates product views and cart additions by category.
   - **SQL Code:**
     ```sql
     SELECT product_category, 
            SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views, 
            SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds 
     FROM page_hierarchy p 
     JOIN events e ON p.page_id = e.page_id 
     JOIN event_identifier ei ON e.event_type = ei.event_type 
     WHERE product_category IS NOT NULL 
     GROUP BY product_category;
     ```
   - **Answer:** ![image](https://github.com/user-attachments/assets/1942ce88-1feb-4c17-9071-ce0fbd0da746)


## 9. Top 3 Purchased Products
   - **Explanation:** Determines the most frequently purchased products.
   - **SQL Code:**
     ```sql
     WITH cte AS (
         SELECT visit_id FROM events e 
         JOIN event_identifier ei ON ei.event_type = e.event_type 
         WHERE event_name = 'Purchase'
     )
     SELECT TOP 3 page_name, 
                   product_category, 
                   COUNT(e.visit_id) AS purchase_count 
     FROM page_hierarchy ph 
     JOIN events e ON ph.page_id = e.page_id 
     JOIN event_identifier ei ON e.event_type = ei.event_type 
     WHERE event_name = 'Add to Cart' AND e.visit_id IN (SELECT visit_id FROM cte) 
     GROUP BY page_name, product_category 
     ORDER BY purchase_count DESC;
     ```
   - **Answer:** ![image](https://github.com/user-attachments/assets/544e4f2b-e02c-45f9-b7aa-04b6d6f1488f)



# C. Product Funnel Analysis

## How many times was each product viewed?
## How many times was each product added to cart?
## How many times was each product added to a cart but not purchased (abandoned)?
## How many times was each product purchased?
**Explanation:** Analyze the number of views, cart additions, abandonments, and purchases for each product.
```sql
WITH view_table AS (
    SELECT page_name, product_category, COUNT(page_name) AS total_view 
    FROM page_hierarchy ph
    JOIN events e ON ph.page_id = e.page_id
    JOIN event_identifier ei ON e.event_type = ei.event_type
    WHERE product_category IS NOT NULL AND event_name = 'Page View'
    GROUP BY page_name, product_category
),
added_table AS (
    SELECT page_name, product_category, COUNT(page_name) AS total_add 
    FROM page_hierarchy ph
    JOIN events e ON ph.page_id = e.page_id
    JOIN event_identifier ei ON e.event_type = ei.event_type
    WHERE product_category IS NOT NULL AND event_name = 'Add to Cart'
    GROUP BY page_name, product_category
),
purchase_table AS (
    SELECT visit_id 
    FROM events e
    JOIN event_identifier ei ON e.event_type = ei.event_type
    WHERE event_name = 'Purchase'
),
purchase_table_2 AS (
    SELECT page_name, product_category, COUNT(page_name) AS total_purchase 
    FROM page_hierarchy ph
    JOIN events e ON ph.page_id = e.page_id
    JOIN event_identifier ei ON e.event_type = ei.event_type
    RIGHT JOIN purchase_table p ON e.visit_id = p.visit_id
    WHERE product_category IS NOT NULL AND event_name = 'Add to Cart'
    GROUP BY page_name, product_category
)
SELECT view_table.page_name, view_table.product_category, total_view, total_add, total_purchase, 
       total_add - total_purchase AS total_abandoned 
INTO product_status
FROM view_table
LEFT JOIN added_table ON view_table.page_name = added_table.page_name
LEFT JOIN purchase_table_2 ON view_table.page_name = purchase_table_2.page_name;
```
**Answer:** 
![image](https://github.com/user-attachments/assets/4d8f06bc-8791-42c3-b29c-4099e801c9e7)

Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

```sql
select product_category, sum(total_view) total_view, sum(total_add) total_add, sum(total_purchase) total_purchase, sum(total_abounded) total_abounded 
into product_category_status
from product_status
group by product_category;
```
**Answer:** 
![image](https://github.com/user-attachments/assets/57b0ca29-10a7-409d-80d4-50f4bc94ddc2)

# D. Campaigns Analysis

## Generate a table that has 1 single row for every unique visit_id record and has the following columns:
- `user_id`
- `visit_id`
- `visit_start_time`: the earliest event_time for each visit
- `page_views`: count of page views for each visit
- `cart_adds`: count of product cart add events for each visit
- `purchase`: 1/0 flag if a purchase event exists for each visit
- `campaign_name`: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- `impression`: count of ad impressions for each visit
- `click`: count of ad clicks for each visit
- (Optional column) `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

**Explanation:** Create a table containing information about each unique visit, including campaign details.
```sql
SELECT u.user_id, e.visit_id, MIN(event_time) AS visit_start_time, 
       SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
       SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
       SUM(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END) AS purchase,
       ci.campaign_name,
       SUM(CASE WHEN event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impression,
       SUM(CASE WHEN event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
       STRING_AGG(CASE WHEN event_name = 'Add to Cart' AND ph.product_category IS NOT NULL 
                       THEN ph.page_name ELSE NULL END, ', ') WITHIN GROUP (ORDER BY sequence_number ASC) AS cart_products
FROM users u
JOIN events e ON u.cookie_id = e.cookie_id
JOIN event_identifier ei ON e.event_type = ei.event_type
JOIN campaign_identifier ci ON e.event_time BETWEEN ci.start_date AND ci.end_date
JOIN page_hierarchy ph ON e.page_id = ph.page_id
GROUP BY user_id, visit_id, ci.campaign_name;
```
**Answer:** 
![image](https://github.com/user-attachments/assets/e225e981-00ab-45d1-89aa-aeb81c12bd4c)



