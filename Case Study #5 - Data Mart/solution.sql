select * from [dbo].[weekly_sales];

-- 1. Data Cleansing Steps
select CONVERT(datetime,week_date,3) week_date,
		datepart(week, CONVERT(datetime,week_date,3)) week_number,
		datepart(month, CONVERT(datetime,week_date,3)) month_number,
		datepart(year, CONVERT(datetime,week_date,3)) calendar_year,
		CASE WHEN SUBSTRING(segment,2,1) = '1' THEN 'Young Adults'
			WHEN SUBSTRING(segment,2,1) = '2' THEN  'Middle Aged'
			WHEN SUBSTRING(segment,2,1) = '3' or SUBSTRING(segment,1,1) = '4' THEN 'Retirees'
			ELSE 'unknown' 
			END AS age_band,
		CASE WHEN SUBSTRING(segment,1,1) = 'C' THEN 'Couples'
			WHEN SUBSTRING(segment,1,1) = 'F' THEN  'Families'
			ELSE 'unknown'
			END AS demographic,
		region,
        platform,
        customer_type,
        transactions,
        sales,
        cast (cast(sales as float)/transactions as decimal(10,2)) as avg_transaction 
INTO clean_weekly_sales
from weekly_sales;

--2. Data Exploration
select * from clean_weekly_sales;
-- 1.	What day of the week is used for each week_date value?
select distinct datename(WEEKDAY,week_date) week_day from clean_weekly_sales;
-- 2.	What range of week numbers are missing from the dataset?
with numbers_week as (SELECT 52 as week_number_year
      UNION all
      SELECT week_number_year - 1
      FROM numbers_week
      WHERE week_number_year > 1)
select count(week_number_year) missing_weeks from numbers_week n
left join clean_weekly_sales c on c.week_number=n.week_number_year
where week_number is null;
-- 3.	How many total transactions were there for each year in the dataset?
select calendar_year, sum(transactions) total_trans from clean_weekly_sales
group by calendar_year
order by calendar_year;

-- 4.	What is the total sales for each region for each month?
ALTER TABLE clean_weekly_sales
ALTER COLUMN sales BIGINT

select region, month_number, sum(sales) total_sales from clean_weekly_sales
group by region, month_number
order by region,month_number;
-- 5.	What is the total count of transactions for each platform
select platform,
        COUNT(transactions) as total_transaction
from clean_weekly_sales
group by platform;
-- 6.	What is the percentage of sales for Retail vs Shopify for each month?
with cte as (select calendar_year, month_number, platform, sum(sales) monthly_sales from clean_weekly_sales
group by calendar_year, month_number, platform)
select calendar_year, month_number, round(cast(max(case when platform='Retail' then monthly_sales end) as float)*100/ cast(sum(monthly_sales) as float),2) as pct_retail,
									round(cast(max(case when platform='Shopify' then monthly_sales end) as float)*100/ cast(sum(monthly_sales) as float),2) as pct_shopify
from cte
group by calendar_year, month_number
ORDER BY calendar_year, month_number;
-- 7.	What is the percentage of sales by demographic for each year in the dataset?
with cte as (select calendar_year, demographic, sum(sales) yearly_sales from clean_weekly_sales
group by calendar_year, demographic)
select calendar_year, round(cast(max(case when demographic='Couples' then yearly_sales end) as float)*100/ cast(sum(yearly_sales) as float),2) as pct_couples,
									round(cast(max(case when demographic='Families' then yearly_sales end) as float)*100/ cast(sum(yearly_sales) as float),2) as pct_families,
									round(cast(max(case when demographic='unknown' then yearly_sales end) as float)*100/ cast(sum(yearly_sales) as float),2) as pct_families
from cte
group by calendar_year
ORDER BY calendar_year;
-- 8.	Which age_band and demographic values contribute the most to Retail sales?
select age_band, demographic, sum(sales) sales, round(100*cast(sum(sales)as float)/ CAST((SELECT sum(sales) from clean_weekly_sales where platform='Retail') as float),2) as contribution from clean_weekly_sales
where platform='Retail'
group by age_band, demographic
order by contribution desc;
-- 9.	Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT 
  calendar_year, 
  platform, 
  SUM(sales) / SUM(transactions) AS avg_transaction_group
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;
/*
Khái niệm chính trong giải thích
avg_transaction_row:

Được tính bằng ROUND(AVG(avg_transaction), 0).
Phương pháp này lấy trung bình của cột avg_transaction theo từng hàng, sau đó tính trung bình của các giá trị trung bình này cho từng nhóm (calendar_year, platform).
Phương pháp này không chính xác khi muốn tìm giá trị trung bình thực sự của kích thước giao dịch cho từng năm và từng nền tảng, vì nó đối xử với tất cả các hàng như nhau mà không quan tâm đến mức độ quan trọng (doanh thu hoặc số giao dịch) của từng hàng.
avg_transaction_group:

Được tính bằng công thức SUM(sales) / SUM(transactions) cho từng nhóm.
Công thức này cho ra giá trị trung bình thực sự của kích thước giao dịch bằng cách tính tổng doanh thu và tổng số giao dịch cho cả nhóm (nền tảng và năm).
Cách tiếp cận này đảm bảo rằng các hàng có doanh thu hoặc giao dịch cao hơn sẽ có ảnh hưởng lớn hơn trong việc tính toán.
Tại sao nên sử dụng avg_transaction_group?
Sử dụng avg_transaction_group sẽ cho kết quả chính xác hơn về kích thước trung bình của giao dịch vì:

Nó xem xét tổng doanh thu và tổng số giao dịch của toàn bộ nhóm.
Tránh sự sai lệch do việc tính trung bình theo từng hàng (avg_transaction_row), vốn không cân nhắc đến tầm quan trọng của từng hàng.
*/

-- 3.Before & After Analysis
-- 1.	What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with cte as (select sum(case when week_number between datepart(WEEK,'2020-06-15')-4 and datepart(WEEK,'2020-06-15')-1 then sales end) as sale_before_4w,
		sum(case when week_number between datepart(WEEK,'2020-06-15') and datepart(WEEK,'2020-06-15')+3 then sales end) as sale_after_4w
from clean_weekly_sales
where calendar_year=2020 and week_number between datepart(WEEK,'2020-06-15')-4 and datepart(WEEK,'2020-06-15')+3)
select *,  (sale_after_4w-sale_before_4w) as changed, round(100*cast((sale_after_4w-sale_before_4w) as float)/cast(sale_before_4w as float),2) as change_rate
from cte;
-- 2.	What about the entire 12 weeks before and after?
with cte as (select sum(case when week_number between datepart(WEEK,'2020-06-15')-12 and datepart(WEEK,'2020-06-15')-1 then sales end) as sale_before_12w,
		sum(case when week_number between datepart(WEEK,'2020-06-15') and datepart(WEEK,'2020-06-15')+11 then sales end) as sale_after_12w
from clean_weekly_sales
where calendar_year=2020 and week_number between datepart(WEEK,'2020-06-15')-12 and datepart(WEEK,'2020-06-15')+11)
select *,  (sale_after_12w-sale_before_12w) as changed, round(100*cast((sale_after_12w-sale_before_12w) as float)/cast(sale_before_12w as float),2) as change_rate
from cte;
-- 3.	How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
--part 1
with cte as (select calendar_year, sum(case when week_number between datepart(WEEK,'2020-06-15')-4 and datepart(WEEK,'2020-06-15')-1 then sales end) as sale_before_4w,
								sum(case when week_number between datepart(WEEK,'2020-06-15') and datepart(WEEK,'2020-06-15')+3 then sales end) as sale_after_4w
from clean_weekly_sales
group by calendar_year)

select *, (sale_after_4w-sale_before_4w) as changed, 
		round(100*cast((sale_after_4w-sale_before_4w) as float)/cast(sale_before_4w as float),2) as change_rate  
from cte
order by calendar_year;

--part 2
with cte as (select calendar_year, sum(case when week_number between datepart(WEEK,'2020-06-15')-12 and datepart(WEEK,'2020-06-15')-1 then sales end) as sale_before_12w,
								sum(case when week_number between datepart(WEEK,'2020-06-15') and datepart(WEEK,'2020-06-15')+11 then sales end) as sale_after_12w
from clean_weekly_sales
group by calendar_year)

select *, (sale_after_12w-sale_before_12w) as changed, 
		round(100*cast((sale_after_12w-sale_before_12w) as float)/cast(sale_before_12w as float),2) as change_rate  
from cte
order by calendar_year;

-- D. Bonus
with region_change as (
    select 
        region, 
        sum(case when week_number between datepart(WEEK, '2020-06-15') - 12 and datepart(WEEK, '2020-06-15') - 1 then sales end) as sale_before_12w,
        sum(case when week_number between datepart(WEEK, '2020-06-15') and datepart(WEEK, '2020-06-15') + 11 then sales end) as sale_after_12w
    from clean_weekly_sales
    group by region
)
select 
    *, 
    (sale_after_12w - sale_before_12w) as changed, 
    round(100 * cast((sale_after_12w - sale_before_12w) as float) / cast(sale_before_12w as float), 2) as change_rate  
from region_change
order by region;
with platformChanges as (
    select 
        platform, 
        sum(case when week_number between datepart(WEEK, '2020-06-15') - 12 and datepart(WEEK, '2020-06-15') - 1 then sales end) as sale_before_12w,
        sum(case when week_number between datepart(WEEK, '2020-06-15') and datepart(WEEK, '2020-06-15') + 11 then sales end) as sale_after_12w
    from clean_weekly_sales
    group by platform
)
select 
    *, 
    (sale_after_12w - sale_before_12w) as changed, 
    round(100 * cast((sale_after_12w - sale_before_12w) as float) / cast(sale_before_12w as float), 2) as change_rate  
from platformChanges
order by platform;
with ageBandChanges as (
    select 
        age_band, 
        sum(case when week_number between datepart(WEEK, '2020-06-15') - 12 and datepart(WEEK, '2020-06-15') - 1 then sales end) as sale_before_12w,
        sum(case when week_number between datepart(WEEK, '2020-06-15') and datepart(WEEK, '2020-06-15') + 11 then sales end) as sale_after_12w
    from clean_weekly_sales
    group by age_band
)
select 
    *, 
    (sale_after_12w - sale_before_12w) as changed, 
    round(100 * cast((sale_after_12w - sale_before_12w) as float) / cast(sale_before_12w as float), 2) as change_rate  
from ageBandChanges
order by age_band;
with demographicChanges as (
    select 
        demographic, 
        sum(case when week_number between datepart(WEEK, '2020-06-15') - 12 and datepart(WEEK, '2020-06-15') - 1 then sales end) as sale_before_12w,
        sum(case when week_number between datepart(WEEK, '2020-06-15') and datepart(WEEK, '2020-06-15') + 11 then sales end) as sale_after_12w
    from clean_weekly_sales
    group by demographic
)
select 
    *, 
    (sale_after_12w - sale_before_12w) as changed, 
    round(100 * cast((sale_after_12w - sale_before_12w) as float) / cast(sale_before_12w as float), 2) as change_rate  
from demographicChanges
order by demographic;
with customerTypeChanges as (
    select 
        customer_type, 
        sum(case when week_number between datepart(WEEK, '2020-06-15') - 12 and datepart(WEEK, '2020-06-15') - 1 then sales end) as sale_before_12w,
        sum(case when week_number between datepart(WEEK, '2020-06-15') and datepart(WEEK, '2020-06-15') + 11 then sales end) as sale_after_12w
    from clean_weekly_sales
    group by customer_type
)
select 
    *, 
    (sale_after_12w - sale_before_12w) as changed, 
    round(100 * cast((sale_after_12w - sale_before_12w) as float) / cast(sale_before_12w as float), 2) as change_rate  
from customerTypeChanges
order by customer_type;



