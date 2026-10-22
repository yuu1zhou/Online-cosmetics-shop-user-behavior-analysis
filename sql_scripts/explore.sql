-- name: year revenue 
SELECT year(event_time) year, sum(price) total_revenue
from deduplicated_data
where event_type = 'purchase'
group by year(event_time)


-- name: month revenue 
SELECT month(event_time) month, sum(price) total_revenue
from deduplicated_data
where event_type = 'purchase'
group by month(event_time)

-- name: active users
SELECT year(event_time) year, month(event_time) month, count(distinct user_id) num_active_users 
from deduplicated_data
where event_type = 'view'
group by year(event_time), month(event_time)
order by year(event_time), month(event_time)


-- name: view + cart + purchase active user
(
    SELECT year(event_time) year, month(event_time) month, count(distinct user_id) num_active_users, 'view' type
from deduplicated_data
where event_type = 'view'
group by year(event_time), month(event_time)
order by year(event_time), month(event_time)
)
union all
(
    select year(event_time) year, month(event_time) month, count(distinct user_id) num_active_users, 'purchase' type
from deduplicated_data
where event_type = 'purchase'
group by year(event_time), month(event_time)
order by year(event_time), month(event_time)
)
union all
(
    select year(event_time) year, month(event_time) month, count(distinct user_id) num_active_users, 'cart' type
from deduplicated_data
where event_type = 'cart'
group by year(event_time), month(event_time)
order by year(event_time), month(event_time)
)

-- name: actual view + cart + purchase active
select year(event_time) year, month(event_time) month, count(*) num_action, 'view' type
from deduplicated_data
where event_type = 'view'
group by year(event_time), month(event_time)
union all
select year(event_time) year, month(event_time) month, count(*) num_action, 'purchase' type
from deduplicated_data
where event_type = 'purchase'
group by year(event_time), month(event_time)
union all
select year(event_time) year, month(event_time) month, count(*) num_action, 'cart' type
from deduplicated_data
where event_type = 'cart'
group by year(event_time), month(event_time)


-- name: avg action
select year(event_time) year, month(event_time) month, count(*) / count(distinct user_id) avg_num_action, 'view' type
from deduplicated_data
where event_type = 'view'
group by year(event_time), month(event_time)
union all
select year(event_time) year, month(event_time) month, count(*) / count(distinct user_id) avg_num_action, 'purchase' type
from deduplicated_data
where event_type = 'purchase'
group by year(event_time), month(event_time)
union all
select year(event_time) year, month(event_time) month, count(*) / count(distinct user_id) avg_num_action, 'cart' type
from deduplicated_data
where event_type = 'cart'
group by year(event_time), month(event_time)

-- name: revenue mom
SELECT '11月环比' month, sum(price) / (SELECT sum(price) from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 10 and event_type = 'purchase') - 1 mom 
from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'purchase'
union all
SELECT '12月环比' month, sum(price) / (SELECT sum(price) from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'purchase') - 1 mom
from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 12 and event_type = 'purchase'
union all
SELECT '1月环比' month, sum(price) / (SELECT sum(price) from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 12 and event_type = 'purchase') - 1 mom
from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'purchase'
union all
SELECT '2月环比' month, sum(price) / (SELECT sum(price) from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'purchase') - 1 mom
from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 2 and event_type = 'purchase'

-- name: 1 vs. 11 revenue mom
select 'Jan/20 vs. Nov/19' mom, (select sum(price) from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'purchase') * 100 / sum(price) - 100 value
from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'purchase'

-- name: 1 vs. 11 active user
SELECT 'Jan/20 vs. Nov/19' mom, (select count(distinct user_id) from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'view') * 100 / count(distinct user_id) - 100 value
from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'view'


-- name: 11 metrics
with t1 as (
    select '11' month, count(distinct user_id) total_users
from deduplicated_data
where year(event_time)=2019 and month(event_time) = 11 and event_type = 'view'
),

t2 as (
    select '11' month, (select count(distinct user_id) from deduplicated_data
where year(event_time)=2019 and month(event_time) = 11 and event_type = 'purchase') / count(distinct user_id) crt
from deduplicated_data
where year(event_time)=2019 and month(event_time) = 11 and event_type = 'view'
),

t3 as (
    select '11' month, count(*) / count(distinct user_id) avg_transactions
from deduplicated_data
where year(event_time)=2019 and month(event_time) = 11 and event_type = 'purchase'
),

t4 as (
    select '11' month, sum(price) / count(*) avg_transaction_value
from deduplicated_data
where year(event_time)=2019 and month(event_time) = 11 and event_type = 'purchase'
)

select t1.*, t2.crt, t3.avg_transactions items_user, t4.avg_transaction_value avg_item_value
from t1 inner join t2 on t1.month = t2.month
inner join t3 on t3.month = t2.month
inner join t4 on t4.month = t2.month

-- name: 1 metrics
with t1 as (
    select '1' month, count(distinct user_id) total_users
from deduplicated_data
where year(event_time)=2020 and month(event_time) = 1 and event_type = 'view'
),

t2 as (
    select '1' month, (select count(distinct user_id) from deduplicated_data
where year(event_time)=2020 and month(event_time) = 1 and event_type = 'purchase') / count(distinct user_id) crt
from deduplicated_data
where year(event_time)=2020 and month(event_time) = 1 and event_type = 'view'
),

t3 as (
    select '1' month, count(*) / count(distinct user_id) avg_transactions
from deduplicated_data
where year(event_time)=2020 and month(event_time) = 1 and event_type = 'purchase'
),

t4 as (
    select '1' month, sum(price) / count(*) avg_transaction_value
from deduplicated_data
where year(event_time)=2020 and month(event_time) = 1 and event_type = 'purchase'
)

select t1.*, t2.crt, t3.avg_transactions items_user, t4.avg_transaction_value avg_item_value
from t1 inner join t2 on t1.month = t2.month
inner join t3 on t3.month = t2.month
inner join t4 on t4.month = t2.month

-- name: 11 vs. 1 revenue mom
select 'Nov/19 vs. Jan/20' mom, (select sum(price) from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'purchase') * 100 / sum(price) - 100 value
from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'purchase'

-- name: 11 vs. 1 active user
SELECT 'Nov/19 vs. Jan/20' mom, (select count(distinct user_id) from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'view') * 100 / count(distinct user_id) - 100 value
from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'view'


-- name: 11: view cart remove_from_cart purchase
with t1 as (
    select 'view' type, count(distinct user_id) num_users
from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'view'
union all
select 'cart' type, count(distinct user_id) num_users
from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'cart'
union all
select 'purchase' type, count(distinct user_id) num_users
from deduplicated_data
where year(event_time) = 2019 and month(event_time) = 11 and event_type = 'purchase'
),

t2 as (
    select *, lag(num_users) over (order by num_users desc) last_type_users
from t1
)

select *, num_users * 100 / last_type_users crt
from t2

-- name: 1: view cart remove_from_cart purchase
with t1 as (
    select 'view' type, count(distinct user_id) num_users
from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'view'
union all
select 'cart' type, count(distinct user_id) num_users
from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'cart'
union all
select 'purchase' type, count(distinct user_id) num_users
from deduplicated_data
where year(event_time) = 2020 and month(event_time) = 1 and event_type = 'purchase'
),

t2 as (
    select *, lag(num_users) over (order by num_users desc) last_type_users
from t1
)

select *, num_users * 100 / last_type_users crt
from t2

-- name: find collapsed user (1 month diff)
with 10_view_user as (
    select distinct '10' month, user_id 
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 10
),

11_view_user as (
    select distinct '11' month, user_id
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 11
),

12_view_user as (
    select distinct '12' month, user_id
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 12
),

1_view_user as (
    select distinct '1' month, user_id
from deduplicated_data
where event_type = 'view' and year(event_time) = 2020 and month(event_time) = 1
),

2_view_user as (
    select distinct '2' month, user_id
from deduplicated_data
where event_type = 'view' and year(event_time) = 2020 and month(event_time) = 2
),

11_retained_user as (
    select '10 vs. 11' months, count(distinct user_id) collapsed_user
from 11_view_user
where user_id in (select user_id from 10_view_user)
),

12_retained_user as (
    select '11 vs. 12' months, count(distinct user_id) collapsed_user
from 12_view_user
where user_id in (select user_id from 11_view_user)
),

1_retained_user as (
    select '1 vs. 12' months, count(distinct user_id) collapsed_user
from 1_view_user
where user_id in (select user_id from 12_view_user)
),

2_retained_user as (
    select '2 vs. 1' months, count(distinct user_id) collapsed_user
from 2_view_user
where user_id in (select user_id from 1_view_user)
)

select a.months, c.previous_month_view_user, a.current_month_view_user, b.collapsed_user
from (select '10 vs. 11' months, count(distinct user_id) current_month_view_user from 11_view_user) a
inner join (select '10 vs. 11' months, count(distinct user_id) previous_month_view_user from 10_view_user) c on a.months = c.months
inner join 11_retained_user b on a.months = b.months
union all 
select a.months, c.previous_month_view_user, a.current_month_view_user, b.collapsed_user
from (select '11 vs. 12' months, count(distinct user_id) current_month_view_user from 12_view_user) a
inner join (select '11 vs. 12' months, count(distinct user_id) previous_month_view_user from 11_view_user) c on a.months = c.months
inner join 12_retained_user b on a.months = b.months
union all 
select a.months, c.previous_month_view_user, a.current_month_view_user, b.collapsed_user
from (select '1 vs. 12' months, count(distinct user_id) current_month_view_user from 1_view_user) a
inner join (select '1 vs. 12' months, count(distinct user_id) previous_month_view_user from 12_view_user) c on a.months = c.months
inner join 1_retained_user b on a.months = b.months
union all 
select a.months, c.previous_month_view_user, a.current_month_view_user, b.collapsed_user
from (select '2 vs. 1' months, count(distinct user_id) current_month_view_user from 2_view_user) a
inner join (select '2 vs. 1' months, count(distinct user_id) previous_month_view_user from 1_view_user) c on a.months = c.months
inner join 2_retained_user b on a.months = b.months

-- name: find collapsed user (cumulate month diff)
with 10_view_user as (
    select distinct '10' month, user_id 
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 10
),

11_view_user as (
    select distinct '11' month, user_id
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 11
),

12_view_user as (
    select distinct '12' month, user_id
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 12
),

1_view_user as (
    select distinct '1' month, user_id
from deduplicated_data
where event_type = 'view' and year(event_time) = 2020 and month(event_time) = 1
),

2_view_user as (
    select distinct '2' month, user_id
from deduplicated_data
where event_type = 'view' and year(event_time) = 2020 and month(event_time) = 2
),

11_retained_user as (
    select '10 vs. 11' months, count(distinct user_id) collapsed_user
from 11_view_user
where user_id in (select user_id from 10_view_user)
),

12_retained_user as (
    select '11 vs. 12' months, count(distinct user_id) collapsed_user
from 12_view_user
where user_id in (select user_id from 11_view_user UNION select user_id from 10_view_user)
),

1_retained_user as (
    select '1 vs. 12' months, count(distinct user_id) collapsed_user
from 1_view_user
where user_id in (select user_id from 12_view_user union select user_id from 11_view_user UNION select user_id from 10_view_user)
),

2_retained_user as (
    select '2 vs. 1' months, count(distinct user_id) collapsed_user
from 2_view_user
where user_id in (select user_id from 1_view_user union select user_id from 12_view_user union select user_id from 11_view_user UNION select user_id from 10_view_user)
)

select a.months, c.previous_month_view_user, a.current_month_view_user, b.collapsed_user
from (select '10 vs. 11' months, count(distinct user_id) current_month_view_user from 11_view_user) a
inner join (select '10 vs. 11' months, count(distinct user_id) previous_month_view_user from 10_view_user) c on a.months = c.months
inner join 11_retained_user b on a.months = b.months
union all 
select a.months, c.previous_month_view_user, a.current_month_view_user, b.collapsed_user
from (select '11 vs. 12' months, count(distinct user_id) current_month_view_user from 12_view_user) a
inner join (select '11 vs. 12' months, count(distinct user_id) previous_month_view_user from 11_view_user) c on a.months = c.months
inner join 12_retained_user b on a.months = b.months
union all 
select a.months, c.previous_month_view_user, a.current_month_view_user, b.collapsed_user
from (select '1 vs. 12' months, count(distinct user_id) current_month_view_user from 1_view_user) a
inner join (select '1 vs. 12' months, count(distinct user_id) previous_month_view_user from 12_view_user) c on a.months = c.months
inner join 1_retained_user b on a.months = b.months
union all 
select a.months, c.previous_month_view_user, a.current_month_view_user, b.collapsed_user
from (select '2 vs. 1' months, count(distinct user_id) current_month_view_user from 2_view_user) a
inner join (select '2 vs. 1' months, count(distinct user_id) previous_month_view_user from 1_view_user) c on a.months = c.months
inner join 2_retained_user b on a.months = b.months

-- name: find collapsed user (cumulate month diff, optimized)
WITH
periods AS (
    SELECT DATE('2019-11-01') AS month_start
    UNION ALL SELECT DATE('2019-12-01')
    UNION ALL SELECT DATE('2020-01-01')
    UNION ALL SELECT DATE('2020-02-01')
),

monthly_views AS (
    SELECT DISTINCT
        DATE_SUB(DATE(event_time), INTERVAL (DAYOFMONTH(event_time) - 1) DAY) AS month_start,
        user_id
    FROM deduplicated_data
    WHERE event_type = 'view'
      AND event_time >= '2019-10-01'
      AND event_time <  '2020-03-01'
),

first_seen AS (
    SELECT
        user_id,
        MIN(month_start) AS first_month
    FROM monthly_views
    GROUP BY user_id
),

monthly_stats AS (
    SELECT
        mv.month_start,
        COUNT(*) AS current_month_view_user,
        SUM(fs.first_month < mv.month_start) AS collapsed_user
    FROM monthly_views mv
    JOIN first_seen fs
      ON fs.user_id = mv.user_id
    GROUP BY mv.month_start
)

SELECT
    CONCAT(
        DATE_FORMAT(DATE_SUB(p.month_start, INTERVAL 1 MONTH), '%Y-%m'),
        ' vs. ',
        DATE_FORMAT(p.month_start, '%Y-%m')
    ) AS months,
    COALESCE(prev.current_month_view_user, 0) AS previous_month_view_user,
    COALESCE(curr.current_month_view_user, 0) AS current_month_view_user,
    COALESCE(curr.collapsed_user, 0) AS collapsed_user
FROM periods p
LEFT JOIN monthly_stats curr
  ON curr.month_start = p.month_start
LEFT JOIN monthly_stats prev
  ON prev.month_start = DATE_SUB(p.month_start, INTERVAL 1 MONTH)
ORDER BY p.month_start;

-- 10/15
-- name: 2 purchase user view
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 2
)

SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where user_id in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2020 and month(event_time) = 2
group by user_id

-- name: 2 non-purchase user view
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 2
)

SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where user_id not in (SELECT user_id from purchase_user) and event_type = 'view'
and year(event_time) = 2020 and month(event_time) = 2
group by user_id

-- name: 11 purchase user view
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2019 and month(event_time) = 11
)

SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where user_id in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2019 and month(event_time) = 11
group by user_id

-- name: 11 non-purchase user view
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2019 and month(event_time) = 11
)

SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where user_id not in (SELECT user_id from purchase_user) and event_type = 'view'
and year(event_time) = 2019 and month(event_time) = 11
group by user_id

-- name: 1 purchase user view
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 1
)

SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where user_id in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2020 and month(event_time) = 1
group by user_id

-- name: 1 non-purchase user view
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 1
)

SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where user_id not in (SELECT user_id from purchase_user) and event_type = 'view'
and year(event_time) = 2020 and month(event_time) = 1
group by user_id

-- name: 2 purchase user view / session
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 2
)

SELECT user_id, count(*) / count(distinct user_session) monthly_view_per_session
from deduplicated_data
where user_id in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2020 and month(event_time) = 2
group by user_id

-- name: 2 non-purchase average view / session
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 2
)

SELECT user_id, count(*) / count(distinct user_session) monthly_view_per_session
from deduplicated_data
where user_id not in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2020 and month(event_time) = 2
group by user_id


-- name: 11 purchase average view / session
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2019 and month(event_time) = 11
)

SELECT user_id, count(*) / count(distinct user_session) monthly_view_per_session
from deduplicated_data
where user_id in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2019 and month(event_time) = 11
group by user_id

-- name: 11 non-purchase average view / session
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2019 and month(event_time) = 11
)

SELECT user_id, count(*) / count(distinct user_session) monthly_view_per_session
from deduplicated_data
where user_id not in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2019 and month(event_time) = 11
group by user_id

-- name: 1 purchase average view / session
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 1
)

SELECT user_id, count(*) / count(distinct user_session) monthly_view_per_session
from deduplicated_data
where user_id in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2020 and month(event_time) = 1
group by user_id

-- name: 1 non-purchase average view / session
with purchase_user as (
    select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 1
)

SELECT user_id, count(*) / count(distinct user_session) monthly_view_per_session
from deduplicated_data
where user_id not in (SELECT user_id from purchase_user) and event_type = 'view' 
and year(event_time) = 2020 and month(event_time) = 1
group by user_id

-- 10/16
-- name: 11. last month user, months before last month, and current month new
with purchase_user as (
select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2019 and month(event_time) = 11
),

11_valid_user as (
    select distinct user_id
from deduplicated_data 
where user_id in (select distinct user_id from purchase_user) and year(event_time) = 2019 and month(event_time) = 11 and event_type = 'view'
),

last_month_active_user as (
    select user_id, 1 last_month_active
from deduplicated_data
where (event_time between '2019-10-01 00:00:00' and '2019-10-31 23:59:59') 
and event_type = 'view' and user_id in (select distinct user_id from 11_valid_user)
group by user_id
),

earlier_months_active as (
    select user_id, 1 earlier_months_active
from deduplicated_data
where event_time < '2019-10-01 00:00:00' and event_type = 'view' and user_id in (select distinct user_id from 11_valid_user)
group by user_id
)

select a.user_id, coalesce(b.last_month_active, 0) last_month_active, coalesce(c.earlier_months_active, 0) earlier_months_active,
(case when b.last_month_active is null and c.earlier_months_active is null then 1 else 0 end) first_visit
from 11_valid_user a
left join last_month_active_user b on a.user_id = b.user_id
left join earlier_months_active c on a.user_id = c.user_id

-- name: 1. last month user, months before last month, and current month new
with purchase_user as (
select distinct user_id
from deduplicated_data
where event_type = 'purchase' and year(event_time) = 2020 and month(event_time) = 1
),

1_valid_user as (
    select distinct user_id
from deduplicated_data 
where user_id in (select distinct user_id from purchase_user) and year(event_time) = 2020 and month(event_time) = 1 and event_type = 'view'
),

last_month_active_user as (
    select user_id, 1 last_month_active
from deduplicated_data
where (event_time between '2019-12-01 00:00:00' and '2019-12-31 23:59:59') 
and event_type = 'view' and user_id in (select distinct user_id from 1_valid_user)
group by user_id
),

earlier_months_active as (
    select user_id, 1 earlier_months_active
from deduplicated_data
where event_time < '2019-12-01 00:00:00' and event_type = 'view' and user_id in (select distinct user_id from 1_valid_user)
group by user_id
)

select a.user_id, coalesce(b.last_month_active, 0) last_month_active, coalesce(c.earlier_months_active, 0) earlier_months_active,
(case when b.last_month_active is null and c.earlier_months_active is null then 1 else 0 end) first_visit
from 1_valid_user a
left join last_month_active_user b on a.user_id = b.user_id
left join earlier_months_active c on a.user_id = c.user_id

-- 10/17 + 10/18
-- name: feb product category
select category_id, sum(price) monthly_total_revenue, count(*) total_items_sold, 
sum(price) / count(*) avg_price
from deduplicated_data
where event_time between '2020-02-01 00:00:00' and '2020-02-28 23:59:59'
and event_type = 'purchase'
group by category_id
order by monthly_total_revenue desc, avg_price desc

-- name: feb product category + category
select category_id, sum(price) monthly_total_revenue, count(*) total_items_sold, 
sum(price) / count(*) avg_price, (CASE 
    WHEN sum(price) / count(*) <= 3 THEN 'level 1'
    WHEN sum(price) / count(*) > 3 and sum(price) / count(*) <= 5.3 THEN 'level 2'
    WHEN sum(price) / count(*) > 5.3 and sum(price) / count(*) <= 8.3 THEN 'level 3'
    WHEN sum(price) / count(*) > 8.3 and sum(price) / count(*) <= 16 THEN 'level 4'
    WHEN sum(price) / count(*) > 16 and sum(price) / count(*) <= 30 THEN 'level 5'
    WHEN sum(price) / count(*) > 30 and sum(price) / count(*) <= 100 THEN 'level 6'
    ELSE 'level 7'
END) price_tier
from deduplicated_data
where event_time between '2020-02-01 00:00:00' and '2020-02-28 23:59:59'
and event_type = 'purchase'
group by category_id
order by monthly_total_revenue desc, avg_price desc

-- name: 11. total views 3-100 segment
with level_3_user as (
SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 11
group by user_id
having count(*) <= 100 and count(*) > 3
),

category_pivot as (
    select category_id, sum(price) monthly_total_revenue, count(*) total_items_sold, 
sum(price) / count(*) avg_price, (CASE 
    WHEN sum(price) / count(*) <= 3 THEN 'level 1'
    WHEN sum(price) / count(*) > 3 and sum(price) / count(*) <= 8.3 THEN 'level 2'
    WHEN sum(price) / count(*) > 8.3 and sum(price) / count(*) <= 16 THEN 'level 3'
    WHEN sum(price) / count(*) > 16 and sum(price) / count(*) <= 30 THEN 'level 4'
    WHEN sum(price) / count(*) > 30 and sum(price) / count(*) <= 100 THEN 'level 5'
    ELSE 'level 6'
END) price_tier
from deduplicated_data
where event_time between '2020-02-01 00:00:00' and '2020-02-28 23:59:59'
and event_type = 'purchase'
group by category_id
order by monthly_total_revenue desc, avg_price desc
)

select u.user_id, d.category_id, d.event_type, c.price_tier 
from level_3_user u
inner join deduplicated_data d on u.user_id = d.user_id 
inner join category_pivot c on c.category_id = d.category_id
and d.event_time between '2019-11-01 00:00:00' and '2019-11-30 23:59:59'
where d.event_type = 'view'

-- name: 1. total views 3-100 segment
with level_3_user as (
SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where event_type = 'view' and year(event_time) = 2020 and month(event_time) = 1
group by user_id
having count(*) <= 100 and count(*) > 3
),

category_pivot as (
    select category_id, sum(price) monthly_total_revenue, count(*) total_items_sold, 
sum(price) / count(*) avg_price, (CASE 
    WHEN sum(price) / count(*) <= 3 THEN 'level 1'
    WHEN sum(price) / count(*) > 3 and sum(price) / count(*) <= 8.3 THEN 'level 2'
    WHEN sum(price) / count(*) > 8.3 and sum(price) / count(*) <= 16 THEN 'level 3'
    WHEN sum(price) / count(*) > 16 and sum(price) / count(*) <= 30 THEN 'level 4'
    WHEN sum(price) / count(*) > 30 and sum(price) / count(*) <= 100 THEN 'level 5'
    ELSE 'level 6'
END) price_tier
from deduplicated_data
where event_time between '2020-02-01 00:00:00' and '2020-02-28 23:59:59'
and event_type = 'purchase'
group by category_id
order by monthly_total_revenue desc, avg_price desc
)

select u.user_id, d.category_id, d.event_type, c.price_tier 
from level_3_user u
inner join deduplicated_data d on u.user_id = d.user_id 
inner join category_pivot c on c.category_id = d.category_id
and d.event_time between '2020-01-01 00:00:00' and '2020-01-31 23:59:59'
where d.event_type = 'view'


-- name: v2_11. total views 3-100 segment
with level_3_user as (
SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 11
group by user_id
having count(*) <= 100 and count(*) > 3
),

t1 as (
    select u.user_id, d.category_id, count(*) category_total_view
from level_3_user u
inner join deduplicated_data d on u.user_id = d.user_id
where d.event_time between '2019-11-01 00:00:00' and '2019-11-30 23:59:59' and d.event_type = 'view'
group by u.user_id, d.category_id
),

t2 as (
    select *, row_number() over (partition by user_id order by category_total_view desc) r
from t1
),

t3 as (
    select user_id, category_id, category_total_view
from t2
where r = 1
),

t4 AS (
    SELECT
        u.user_id,
        MAX(CASE WHEN d.event_type = 'purchase'
                 THEN 1 ELSE 0 END) AS is_buyer
    FROM t3 u
    LEFT JOIN deduplicated_data d
      ON d.user_id = u.user_id
     AND (d.event_time between '2019-11-01 00:00:00' AND '2019-11-30 23:59:59')
    GROUP BY u.user_id
),

t5 as (
    select t4.user_id, t3.category_id, t4.is_buyer
from t4 inner join t3 on t4.user_id = t3.user_id
)

select category_id main_category, count(user_id) user_viewd, 
count(user_id) / (select count(*) from level_3_user) portion,
sum(is_buyer) total_buyer,
sum(is_buyer) / (select count(*) from level_3_user) buyer_rate
from t5
group by category_id
order by user_viewd desc

-- name: v2_1. total views 3-100 segment
with level_3_user as (
SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where event_type = 'view' and year(event_time) = 2020 and month(event_time) = 1
group by user_id
having count(*) <= 100 and count(*) > 3
),

t1 as (
    select u.user_id, d.category_id, count(*) category_total_view
from level_3_user u
inner join deduplicated_data d on u.user_id = d.user_id
where d.event_time between '2020-1-01 00:00:00' and '2020-1-31 23:59:59' and d.event_type = 'view'
group by u.user_id, d.category_id
),

t2 as (
    select *, row_number() over (partition by user_id order by category_total_view desc) r
from t1
),

t3 as (
    select user_id, category_id, category_total_view
from t2
where r = 1
),

t4 AS (
    SELECT
        u.user_id,
        MAX(CASE WHEN d.event_type = 'purchase'
                 THEN 1 ELSE 0 END) AS is_buyer
    FROM t3 u
    LEFT JOIN deduplicated_data d
      ON d.user_id = u.user_id
     AND (d.event_time between '2020-01-01 00:00:00' AND '2020-01-31 23:59:59')
    GROUP BY u.user_id
),

t5 as (
    select t4.user_id, t3.category_id, t4.is_buyer
from t4 inner join t3 on t4.user_id = t3.user_id
)

select category_id main_category, count(user_id) user_viewd, 
count(user_id) / (select count(*) from level_3_user) portion,
sum(is_buyer) total_buyer,
sum(is_buyer) / (select count(*) from level_3_user) buyer_rate
from t5
group by category_id
order by user_viewd desc

-- 10/19
-- name: over all months avg price
select category_id, avg(price) avg_price_item, COUNT(*) purchase_records
from deduplicated_data
where event_type = 'purchase' AND category_id IS NOT NULL
AND price IS NOT NULL
group by category_id

-- name: v3_11. total views 3-100 segment
with level_3_user as (
SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where event_type = 'view' and year(event_time) = 2019 and month(event_time) = 11
group by user_id
having count(*) <= 100 and count(*) > 3
),

t1 as (
    select u.user_id, d.category_id, count(*) category_total_view
from level_3_user u
inner join deduplicated_data d on u.user_id = d.user_id
where d.event_time between '2019-11-01 00:00:00' and '2019-11-30 23:59:59' and d.event_type = 'view'
group by u.user_id, d.category_id
),

t2 as (
    select *, row_number() over (partition by user_id order by category_total_view desc) r
from t1
),

t3 as (
    select user_id, category_id, category_total_view
from t2
where r = 1
),

t4 AS (
    SELECT
        u.user_id,
        MAX(CASE WHEN d.event_type = 'purchase'
                 THEN 1 ELSE 0 END) AS is_buyer
    FROM t3 u
    LEFT JOIN deduplicated_data d
      ON d.user_id = u.user_id
     AND (d.event_time between '2019-11-01 00:00:00' AND '2019-11-30 23:59:59')
    GROUP BY u.user_id
),

t5 as (
    select t4.user_id, t3.category_id, t4.is_buyer
from t4 inner join t3 on t4.user_id = t3.user_id
)

select category_id main_category, count(user_id) total_user_viewd, 
sum(is_buyer) total_buyer
from t5
group by category_id
order by total_user_viewd desc

-- name: v3_1. total views 3-100 segment
with level_3_user as (
SELECT user_id, count(*) monthly_total_views
from deduplicated_data
where event_type = 'view' and year(event_time) = 2020 and month(event_time) = 1
group by user_id
having count(*) <= 100 and count(*) > 3
),

t1 as (
    select u.user_id, d.category_id, count(*) category_total_view
from level_3_user u
inner join deduplicated_data d on u.user_id = d.user_id
where d.event_time between '2020-1-01 00:00:00' and '2020-1-31 23:59:59' and d.event_type = 'view'
group by u.user_id, d.category_id
),

t2 as (
    select *, row_number() over (partition by user_id order by category_total_view desc) r
from t1
),

t3 as (
    select user_id, category_id, category_total_view
from t2
where r = 1
),

t4 AS (
    SELECT
        u.user_id,
        MAX(CASE WHEN d.event_type = 'purchase'
                 THEN 1 ELSE 0 END) AS is_buyer
    FROM t3 u
    LEFT JOIN deduplicated_data d
      ON d.user_id = u.user_id
     AND (d.event_time between '2020-01-01 00:00:00' AND '2020-01-31 23:59:59')
    GROUP BY u.user_id
),

t5 as (
    select t4.user_id, t3.category_id, t4.is_buyer
from t4 inner join t3 on t4.user_id = t3.user_id
)

select category_id main_category, count(user_id) total_user_viewd, 
sum(is_buyer) total_buyer
from t5
group by category_id
order by total_user_viewd desc

-- 10/20
-- name: 11. highest price tier category user viewd
WITH level_3_user AS (
    SELECT user_id, COUNT(*) monthly_total_views
    FROM deduplicated_data
    WHERE event_type = 'view'
      AND YEAR(event_time) = 2019
      AND MONTH(event_time) = 11
    GROUP BY user_id
    HAVING COUNT(*) <= 100 AND COUNT(*) > 3
),

t1 AS (
    SELECT u.user_id, d.category_id, MAX(d.price) category_max_price
    FROM level_3_user u
    INNER JOIN deduplicated_data d ON u.user_id = d.user_id
    WHERE d.event_time >= '2019-11-01 00:00:00'
      AND d.event_time < '2019-12-01 00:00:00'
      AND d.event_type = 'view'
    GROUP BY u.user_id, d.category_id
),

t2 AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY category_max_price DESC, category_id
           ) r
    FROM t1
),

t3 AS (
    SELECT user_id, category_id, category_max_price
    FROM t2
    WHERE r = 1
),

t4 AS (
    SELECT u.user_id,
           MAX(
               CASE WHEN d.event_type = 'purchase'
                    THEN 1 ELSE 0 END
           ) is_buyer
    FROM t3 u
    LEFT JOIN deduplicated_data d
      ON d.user_id = u.user_id
     AND d.event_time >= '2019-11-01 00:00:00'
     AND d.event_time < '2019-12-01 00:00:00'
    GROUP BY u.user_id
),

t5 AS (
    SELECT t4.user_id, t3.category_id, t4.is_buyer
    FROM t4
    INNER JOIN t3 ON t4.user_id = t3.user_id
)

SELECT category_id main_category,
       COUNT(user_id) total_user_viewd,
       SUM(is_buyer) total_buyer
FROM t5
GROUP BY category_id
ORDER BY total_user_viewd DESC;

-- name: 1. highest price tier category user viewd
WITH level_3_user AS (
    SELECT user_id, COUNT(*) monthly_total_views
    FROM deduplicated_data
    WHERE event_type = 'view'
      AND YEAR(event_time) = 2020
      AND MONTH(event_time) = 1
    GROUP BY user_id
    HAVING COUNT(*) <= 100 AND COUNT(*) > 3
),

t1 AS (
    SELECT u.user_id, d.category_id, MAX(d.price) category_max_price
    FROM level_3_user u
    INNER JOIN deduplicated_data d ON u.user_id = d.user_id
    WHERE d.event_time >= '2020-01-01 00:00:00'
      AND d.event_time < '2020-02-01 00:00:00'
      AND d.event_type = 'view'
    GROUP BY u.user_id, d.category_id
),

t2 AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY category_max_price DESC, category_id
           ) r
    FROM t1
),

t3 AS (
    SELECT user_id, category_id, category_max_price
    FROM t2
    WHERE r = 1
),

t4 AS (
    SELECT u.user_id,
           MAX(
               CASE WHEN d.event_type = 'purchase'
                    THEN 1 ELSE 0 END
           ) is_buyer
    FROM t3 u
    LEFT JOIN deduplicated_data d
      ON d.user_id = u.user_id
     AND d.event_time >= '2020-01-01 00:00:00'
     AND d.event_time < '2020-02-01 00:00:00'
    GROUP BY u.user_id
),

t5 AS (
    SELECT t4.user_id, t3.category_id, t4.is_buyer
    FROM t4
    INNER JOIN t3 ON t4.user_id = t3.user_id
)

SELECT category_id main_category,
       COUNT(user_id) total_user_viewd,
       SUM(is_buyer) total_buyer
FROM t5
GROUP BY category_id
ORDER BY total_user_viewd DESC;

-- name: 11. cross category user viewed
WITH level_3_user AS (
    SELECT user_id, COUNT(*) monthly_total_views
    FROM deduplicated_data
    WHERE event_type = 'view'
      AND YEAR(event_time) = 2019
      AND MONTH(event_time) = 11
    GROUP BY user_id
    HAVING COUNT(*) <= 100 AND COUNT(*) > 3
),

t1 AS (
    SELECT u.user_id,
           COUNT(DISTINCT d.category_id) total_categories_viewed
    FROM level_3_user u
    INNER JOIN deduplicated_data d ON u.user_id = d.user_id
    WHERE d.event_time >= '2019-11-01 00:00:00'
      AND d.event_time < '2019-12-01 00:00:00'
      AND d.event_type = 'view'
    GROUP BY u.user_id
),

t2 AS (
    SELECT u.user_id,
           MAX(
               CASE WHEN d.event_type = 'purchase'
                    THEN 1 ELSE 0 END
           ) is_buyer
    FROM level_3_user u
    LEFT JOIN deduplicated_data d
      ON d.user_id = u.user_id
     AND d.event_time >= '2019-11-01 00:00:00'
     AND d.event_time < '2019-12-01 00:00:00'
    GROUP BY u.user_id
),

t3 as (
    SELECT u.user_id,
       u.monthly_total_views,
       t1.total_categories_viewed,
       t2.is_buyer
FROM level_3_user u
INNER JOIN t1 ON u.user_id = t1.user_id
INNER JOIN t2 ON u.user_id = t2.user_id
ORDER BY t1.total_categories_viewed DESC
)

SELECT
    CASE
        WHEN total_categories_viewed >= 1
         AND total_categories_viewed <= 10 THEN '(1, 10]'
        WHEN total_categories_viewed <= 20 THEN '(10, 20]'
        WHEN total_categories_viewed <= 30 THEN '(20, 30]'
        WHEN total_categories_viewed <= 40 THEN '(30, 40]'
        WHEN total_categories_viewed <= 50 THEN '(40, 50]'
        WHEN total_categories_viewed <= 60 THEN '(50, 60]'
        WHEN total_categories_viewed <= 70 THEN '(60, 70]'
    END categories_viewed_range,
    COUNT(*) total_base,
    SUM(is_buyer) total_buyer
FROM t3
GROUP BY categories_viewed_range
ORDER BY MIN(total_categories_viewed)

-- name: 1. cross category user viewed
WITH level_3_user AS (
    SELECT user_id, COUNT(*) monthly_total_views
    FROM deduplicated_data
    WHERE event_type = 'view'
      AND YEAR(event_time) = 2020
      AND MONTH(event_time) = 1
    GROUP BY user_id
    HAVING COUNT(*) <= 100 AND COUNT(*) > 3
),

t1 AS (
    SELECT u.user_id,
           COUNT(DISTINCT d.category_id) total_categories_viewed
    FROM level_3_user u
    INNER JOIN deduplicated_data d ON u.user_id = d.user_id
    WHERE d.event_time >= '2020-01-01 00:00:00'
      AND d.event_time < '2020-02-01 00:00:00'
      AND d.event_type = 'view'
    GROUP BY u.user_id
),

t2 AS (
    SELECT u.user_id,
           MAX(
               CASE WHEN d.event_type = 'purchase'
                    THEN 1 ELSE 0 END
           ) is_buyer
    FROM level_3_user u
    LEFT JOIN deduplicated_data d
      ON d.user_id = u.user_id
     AND d.event_time >= '2020-01-01 00:00:00'
     AND d.event_time < '2020-02-01 00:00:00'
    GROUP BY u.user_id
),

t3 as (
    SELECT u.user_id,
       u.monthly_total_views,
       t1.total_categories_viewed,
       t2.is_buyer
FROM level_3_user u
INNER JOIN t1 ON u.user_id = t1.user_id
INNER JOIN t2 ON u.user_id = t2.user_id
ORDER BY t1.total_categories_viewed DESC
)

SELECT
    CASE
        WHEN total_categories_viewed >= 1
         AND total_categories_viewed <= 10 THEN '(1, 10]'
        WHEN total_categories_viewed <= 20 THEN '(10, 20]'
        WHEN total_categories_viewed <= 30 THEN '(20, 30]'
        WHEN total_categories_viewed <= 40 THEN '(30, 40]'
        WHEN total_categories_viewed <= 50 THEN '(40, 50]'
        WHEN total_categories_viewed <= 60 THEN '(50, 60]'
        WHEN total_categories_viewed <= 70 THEN '(60, 70]'
    END categories_viewed_range,
    COUNT(*) total_base,
    SUM(is_buyer) total_buyer
FROM t3
GROUP BY categories_viewed_range
ORDER BY MIN(total_categories_viewed)

-- name: test
WITH level_3_user_11 AS (
    SELECT 11 month, user_id, COUNT(*) monthly_total_views
    FROM deduplicated_data
    WHERE event_type = 'view'
      AND YEAR(event_time) = 2019
      AND MONTH(event_time) = 11
    GROUP BY user_id
    HAVING COUNT(*) <= 100 AND COUNT(*) > 3
),

level_3_user_1 AS (
    SELECT 1 month, user_id, COUNT(*) monthly_total_views
    FROM deduplicated_data
    WHERE event_type = 'view'
      AND YEAR(event_time) = 2020
      AND MONTH(event_time) = 1
    GROUP BY user_id
    HAVING COUNT(*) <= 100 AND COUNT(*) > 3
)

select * from level_3_user_11
union all
select * from level_3_user_1