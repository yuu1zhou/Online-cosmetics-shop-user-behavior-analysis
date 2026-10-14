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