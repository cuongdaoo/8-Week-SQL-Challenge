select * from [dbo].[interest_metrics];
select * from [dbo].[interest_map];
select * from [dbo].[json_data];


---Data Exploration and Cleansing
---1.	Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
update interest_metrics
set month_year= CONVERT(date,'01-'+month_year,105)
alter table interest_metrics
alter column month_year DATE;

SELECT * FROM interest_metrics;
---2.	What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
select month_year, count(*) record from interest_metrics
group by month_year
order by month_year asc;
---3.	What do you think we should do with these null values in the fresh_segments.interest_metrics
---We should drop these null values because these contain 8 % of total values, it would not affect much to final result. 
select 100.0* count(*)/(select count(*) from interest_metrics) per_null_value
from interest_metrics
where month_year is null;
---4.	How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
--Exist in interest_metrics but not in interest_map
select count(distinct interest_id) from interest_metrics
where interest_id not in (select distinct id from interest_map) and interest_id is not null;
--Exist in interest_map but not in interest_metrics
select count(distinct id) from interest_map
where id not in (select distinct interest_id from interest_metrics where interest_id is not null);
---5.	Summarise the id values in the fresh_segments.interest_map by its total record count in this table
select count(*) count_id from interest_map;
---6.	What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
/*
We should perform LEFT JOIN between table interest_metrics and table interest_map in our analysis because only available interest_id in table interest_metrics are meaningful.*/

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
---7.	Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
/*
There are 188 month_year values ​​before the created_at value. However, it is possible that those 188 created_at values ​​were created in the same month as the month_year value. This is because the month_year value is set to the first day of the month by default in Question 1.
*/
SELECT 
  COUNT(*) count_record
FROM interest_metrics metrics
LEFT JOIN interest_map map
  ON metrics.interest_id = map.id
  where month_year<created_at;

---Interest Analysis
---1.	Which interests have been present in all month_year dates in our dataset?
select interest_name, count(month_year) id_count from interest_metrics met
left join interest_map map on met.interest_id=map.id
WHERE month_year IS NOT NULL
group by interest_name
having count(month_year) >= (select count(distinct month_year) from interest_metrics)
order by id_count desc;
      

---2.	Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
/*Interests with total months of 6 and above received a 90% and above cumulative percentage. Interests below 6 months should be investigated to improve their clicks and customer interactions.
*/
with cte as (select interest_id, count(month_year) id_count from interest_metrics 
WHERE month_year IS NOT NULL
group by interest_id),
	cte2 as (select id_count as total_months, count(interest_id) interest_count from cte
				group by id_count)
select *, round(cast(sum(interest_count) over (order by total_months desc)*100.0/(select sum(interest_count) from cte2) as float),2) cumulative_percent 
from cte2
order by total_months desc;
---3.	If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
with cte as (select interest_id, count(month_year) id_count from interest_metrics 
WHERE month_year IS NOT NULL
group by interest_id)

select count(interest_id) interest, count(distinct interest_id) unique_interest from interest_metrics
where interest_id in (select interest_id from cte where id_count <6);


---4.	Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
/*From the data results, we can see that the percentage of deleted months and years with a cumulative percentage lower than 90% is very low and insignificant. So it is okay to delete these months and years.
*/

with cte as (select interest_id, count(month_year) id_count from interest_metrics 
WHERE month_year IS NOT NULL
group by interest_id
having count(month_year)<6),
  remove_month as(select month_year, count(*) total_remove from interest_metrics met
right join cte on met.interest_id=cte.interest_id
group by month_year),
	total_cte as(select month_year, count(*) total_org from interest_metrics met
WHERE month_year IS NOT NULL
group by month_year)

select re.month_year, total_remove, total_org, round(cast(total_remove*100.0/total_org as float),2) per_remove from remove_month re
join total_cte total on re.month_year=total.month_year
order by month_year asc;

---5.	After removing these interests - how many unique interests are there for each month?
with cte as (select interest_id, count(month_year) id_count from interest_metrics 
WHERE month_year IS NOT NULL
group by interest_id
having count(month_year)>=6)
select month_year, count(distinct cte.interest_id) total_remove from interest_metrics met
right join cte on met.interest_id=cte.interest_id
WHERE month_year IS NOT NULL
group by month_year
order by month_year;


---Segment Analysis
---1.	Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
with cte as (select interest_id, count(month_year) id_count from interest_metrics 
WHERE month_year IS NOT NULL
group by interest_id
having count(month_year)<6)

select *
into sub_interest_metrics
from interest_metrics
where interest_id not in (select interest_id from cte);

select * from sub_interest_metrics;
---top10
select top 10 month_year, interest_id, composition from sub_interest_metrics sub_met
left join interest_map map on sub_met.interest_id=map.id
where month_year is not null
order by composition desc;
---bottom 10
select top 10 month_year, interest_id, composition from sub_interest_metrics sub_met
left join interest_map map on sub_met.interest_id=map.id
where month_year is not null
order by composition asc;
---2.	Which 5 interests had the lowest average ranking value?
select top 5 interest_id, round(cast(avg(ranking*1.0) as float),2) avg_rank from sub_interest_metrics sub_met
left join interest_map map on sub_met.interest_id=map.id
where month_year is not null
group by interest_id
order by avg_rank asc;
---3.	Which 5 interests had the largest standard deviation in their percentile_ranking value?
select top 5 interest_id, round(cast(stdev(percentile_ranking*1.0) as float),2) std_per_ranking from sub_interest_metrics sub_met
left join interest_map map on sub_met.interest_id=map.id
where month_year is not null
group by interest_id
order by std_per_ranking desc;
---4.	For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
/*
Beause 5 interests had the largest standard deviation in their percentile_ranking value, the gap from max_value to min_value is so large*/

with std_cte as (select top 5 interest_id, round(cast(stdev(percentile_ranking*1.0) as float),2) std_per_ranking from sub_interest_metrics sub_met
left join interest_map map on sub_met.interest_id=map.id
where month_year is not null
group by interest_id
order by std_per_ranking desc),
	maxmin_cte as (
select month_year, interest_name, percentile_ranking,
	max(percentile_ranking) over (partition by interest_id) max_percentile_ranking,
	min(percentile_ranking) over (partition by interest_id) min_percentile_ranking
from sub_interest_metrics sub_met
left join interest_map map on sub_met.interest_id=map.id
where interest_id in(select interest_id from std_cte))

select month_year, interest_name, percentile_ranking
from maxmin_cte
where percentile_ranking = max_percentile_ranking or percentile_ranking = min_percentile_ranking
order by interest_name, percentile_ranking desc;
---5.	How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

---Index Analysis
/*
The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.*/
---1.	What is the top 10 interests by the average composition for each month?
with cte as (select month_year, interest_id, round(cast(composition/index_value as float),2) as avg_com from interest_metrics met
left join interest_map map on met.interest_id=map.id
where month_year is not null),
	cte2 as(
select *, rank() over (partition by month_year order by avg_com desc) rank_avg_com
from cte)
select * from cte2
where rank_avg_com <=10;
---2.	For all of these top 10 interests - which interest appears the most often?
with cte as (select month_year, interest_name, round(cast(composition/index_value as float),2) as avg_com from interest_metrics met
left join interest_map map on met.interest_id=map.id
where month_year is not null),
	cte2 as(
select *, rank() over (partition by month_year order by avg_com desc) rank_avg_com
from cte)

select interest_name, count(*) count_id from cte2
where rank_avg_com <=10
group by interest_name
order by count_id desc;

---3.	What is the average of the average composition for the top 10 interests for each month?
with cte as (select month_year, interest_name, round(cast(composition/index_value as float),2) as avg_com from interest_metrics met
left join interest_map map on met.interest_id=map.id
where month_year is not null),
	cte2 as(
select *, rank() over (partition by month_year order by avg_com desc) rank_avg_com
from cte)

select month_year, avg(avg_com) count_id from cte2
where rank_avg_com <=10
group by month_year
order by month_year;


---4.	What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
with cte as (select month_year, interest_name, round(cast(composition/index_value as float),2) as avg_com from interest_metrics met
left join interest_map map on met.interest_id=map.id
where month_year is not null),
	cte2 as(
select *, rank() over (partition by month_year order by avg_com desc) rank_avg_com
from cte),
	cte3 as( select month_year, interest_name, avg(avg_com) max_avg_id from cte2
where rank_avg_com =1
group by month_year, interest_name),
	cte4 as (
select *, round(avg(max_avg_id) over (order by month_year rows between 2 preceding and  current row),2) moving_3_month  from cte3),
	lag_cte as (
select *, round(lag(max_avg_id,1) over (order by month_year),2) as m_1,
		round(lag(max_avg_id,2) over (order by month_year),2) as m_2,
		concat(lag(interest_name,1) over (order by month_year),':',round(lag(max_avg_id,1) over (order by month_year),2)) as '1_month_ago',
		concat(lag(interest_name,2) over (order by month_year),':',round(lag(max_avg_id,2) over (order by month_year),2)) as '2_month_ago'
from cte4)

select month_year, interest_name, max_avg_id, moving_3_month, [1_month_ago], [2_month_ago] from lag_cte
where month_year between '2018-09-01' and '2019-08-01';
---5.	Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

/*
Possible Reason for Month-to-Month Changes:
Seasonal Behavior Shifts: Certain interest segments like “Alabama Trip Planners” or “Las Vegas Trip Planners” may spike during specific times of the year (e.g., summer or holidays), affecting the monthly composition.*/
