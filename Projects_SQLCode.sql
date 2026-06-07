
--====================================================================
--PROJECT: TELECOM REVENUE AND CUSTOMER CHURN ANALYSIS
--DEVELOPER: MOHINI JAYBHAYE
--====================================================================

--DROP Old view--

drop view if exists vw_customer_clean;
go

drop view if exists vw_recharge_clean ;
go

drop view if exists vw_usage_clean;
go

drop view if exists vw_date_clean;
go

--clean customer view--
CREATE VIEW vw_customer_clean AS
select customer_id,try_convert(date,join_date,105)as join_date,isnull(nullif(region,'null'),'Unknown')as region,
case when state like '%MAHar%' then 'Maharashtra' else state end as state,
isnull(nullif(segment,'null'),'Unknown')as segment from dim_customer;
GO

--clean recharge view--
CREATE VIEW vw_recharge_clean AS
with dedup as(select*,row_number()over(partition by customer_id,recharge_date,amount order by recharge_id )as rn from fact_recharge)
select  recharge_id,customer_id,try_convert(date,recharge_date,105)as recharge_date,try_convert(decimal(18,2),amount)as amount,
plan_name ,lower(plan_type)as plan_type  from dedup where rn=1   and try_convert(decimal(18,2),amount)is not null ;
go


--clean usage view--
CREATE VIEW  vw_usage_clean AS
select customer_id,usage_id,try_convert(date,usage_date)as usage_date,
try_convert(int,data_mb)as data_mb,try_convert(int,call_minutes)as call_minutes from fact_usage 
where try_convert(int,data_mb)is not null and try_convert(int,call_minutes)is not null;
GO

--clean date view--
CREATE VIEW vw_date_clean AS
select TRY_CONVERT(date,date,105)as date,TRY_CONVERT(int,year)as year,TRY_CONVERT(int,month)as month_number,month_name,quarter,week_day 
from dim_date;
go

--validation--

--compare raw vs clean count--

 select 'customer_raw' as t ,count(*) from dim_customer UNION ALL 
 select 'customer_clean',count(*)from vw_customer_clean;

 select 'recharge_raw',count(*)from fact_recharge union all
 select 'recharge_clean',count(*)from vw_recharge_clean;

 select 'usage_raw',count(*) from fact_usage union all 
 select 'usage_clean',count(*) from vw_usage_clean;

 --Q)why union all?
-- I used UNION ALL to combine results without removing duplicates, ensuring accurate comparison between raw and cleaned data.

--null checks--

select *from vw_customer_clean where segment = 'null';
select *from vw_customer_clean where region ='null';

select * from vw_recharge_clean where amount is null;
select *from vw_recharge_clean where recharge_date is null;

select*from vw_usage_clean where data_mb is null;
select * from vw_usage_clean where call_minutes is null;

--data types sanity--

SELECT MIN(amount) AS min_amt, MAX(amount) AS max_amt FROM vw_recharge_clean;

SELECT MIN(data_mb) AS min_mb, MAX(data_mb) AS max_mb FROM vw_usage_clean;

select min(call_minutes)as min_call,MAX(call_minutes)as max_call from vw_usage_clean;

select min(year) as min ,max(year)as max from vw_date_clean;

select min(month_number)as min,max(month_number)as max from vw_date_clean;


--check duplicates--

select recharge_id,customer_id,recharge_date,amount ,count(*)as duplicate from vw_recharge_clean
group by recharge_id,customer_id,recharge_date,amount having count(*)>1;

--standardization check--

select state,count(*) from vw_customer_clean group by state order by 2 desc;

select plan_type,count(*) from vw_recharge_clean group by plan_type;

--business sanity(raw vs clean revenue)--

select sum(TRY_CONVERT(decimal(18,2),amount))as raw_revenue from fact_recharge ;

select sum(amount)as clean_revenue from vw_recharge_clean;

--join test--

select top 20 * from vw_customer_clean c join vw_recharge_clean r on c.customer_id=r.customer_id;

--I validated cleaned views using row count comparison, null checks, duplicate checks, and business sanity checks on aggregates.



