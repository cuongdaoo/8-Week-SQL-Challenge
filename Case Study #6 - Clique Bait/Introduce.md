This table summarizes the key SQL techniques used to analyze different aspects of the dataset.

| Category | Objective | SQL Method/Technique Applied |
|----------|-----------|-----------------------------|
| **B. Digital Analysis** | | |
| User Count | Calculate the total number of unique users | COUNT(DISTINCT user_id) |
| Cookies Per User | Determine the average number of cookies per user | COUNT, CAST, and division for average calculation |
| Unique Visits Per Month | Count the unique visits per month | DATEPART(MONTH), COUNT(DISTINCT visit_id), GROUP BY |
| Event Count by Type | Count occurrences of each event type | JOIN, GROUP BY, COUNT |
| Purchase Event Percentage | Calculate the percentage of visits with a purchase event | COUNT, CAST, division, and filtering with WHERE |
| Checkout Page Without Purchase | Calculate the percentage of checkout visits without a purchase | WITH CTE, SUM, CASE WHEN, and arithmetic operations |
| Top 3 Most Viewed Pages | Identify the three most visited pages | TOP 3, JOIN, COUNT, GROUP BY, ORDER BY DESC |
| Views and Cart Adds by Category | Count product views and cart additions by category | SUM, CASE WHEN, JOIN, GROUP BY |
| Top 3 Purchased Products | Identify the three most purchased products | WITH CTE, COUNT, JOIN, GROUP BY, ORDER BY DESC |
| **C. Product Funnel Analysis** | | |
| Product Views | Count the number of times each product was viewed | COUNT, GROUP BY, JOIN |
| Product Cart Additions | Count the number of times each product was added to the cart | COUNT, GROUP BY, JOIN |
| Cart Abandonment | Count the number of cart additions without purchase | WITH CTE, COUNT, LEFT JOIN, arithmetic operations |
| Product Purchases | Count the number of times each product was purchased | COUNT, RIGHT JOIN, GROUP BY |
| Product Category Aggregation | Aggregate product status data by category | SUM, GROUP BY |
| **D. Campaigns Analysis** | | |
| Unique Visit Summary | Create a table with user visit details including campaign mapping | SELECT with multiple SUM, COUNT, MIN, CASE WHEN, STRING_AGG, GROUP BY |
| Campaign Effectiveness | Identify campaign engagement through impressions and clicks | SUM, CASE WHEN, JOIN campaign data with event timestamps |
| Cart Products Tracking | Track products added to the cart during a visit | STRING_AGG, ORDER BY sequence_number |



