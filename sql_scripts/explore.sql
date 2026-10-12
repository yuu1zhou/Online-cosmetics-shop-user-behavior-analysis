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