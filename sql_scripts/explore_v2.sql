-- name: test
select * from deduplicated_data

-- name: test_1
select * from deduplicated_data_processed

-- name: 01. monthly user activity
select * from v_monthly_user_activity


-- name: 02. monthly session activity
select * from v_monthly_session_activity 

-- name: 03. monthly active users
SELECT
    month_start,
    COUNT(*) mau
FROM v_monthly_user_activity
GROUP BY month_start
ORDER BY month_start;

-- name: 04. average sessions per user monthly
SELECT
    month_start,
    COUNT(*) total_users,
    SUM(total_sessions) total_sessions,
    AVG(total_sessions) avg_sessions_per_user
FROM v_monthly_user_activity
GROUP BY month_start
ORDER BY month_start;

-- name: 05. single versus multiple sessions monthly
SELECT
    month_start,
    COUNT(*) total_users,

    SUM(
        CASE WHEN total_sessions = 1 THEN 1 ELSE 0 END
    ) single_session_users,

    SUM(
        CASE WHEN total_sessions > 1 THEN 1 ELSE 0 END
    ) multi_session_users,

    SUM(
        CASE WHEN total_sessions = 1 THEN 1 ELSE 0 END
    ) / COUNT(*) single_session_user_share,

    SUM(
        CASE WHEN total_sessions > 1 THEN 1 ELSE 0 END
    ) / COUNT(*) multi_session_user_share

FROM v_monthly_user_activity
GROUP BY month_start
ORDER BY month_start;

-- name: 06. detailed monthly session frequency distribution
WITH t1 AS (
    SELECT
        month_start,
        user_id,

        CASE
            WHEN total_sessions = 1 THEN '1'
            WHEN total_sessions = 2 THEN '2'
            WHEN total_sessions <= 5 THEN '3-5'
            WHEN total_sessions <= 10 THEN '6-10'
            ELSE '11+'
        END session_segment,

        CASE
            WHEN total_sessions = 1 THEN 1
            WHEN total_sessions = 2 THEN 2
            WHEN total_sessions <= 5 THEN 3
            WHEN total_sessions <= 10 THEN 4
            ELSE 5
        END segment_order

    FROM v_monthly_user_activity
),

t2 AS (
    SELECT
        month_start,
        session_segment,
        segment_order,
        COUNT(*) total_users
    FROM t1
    GROUP BY month_start, session_segment, segment_order
)

SELECT
    month_start,
    session_segment,
    total_users,

    total_users / SUM(total_users) OVER (
        PARTITION BY month_start
    ) user_share

FROM t2
ORDER BY month_start, segment_order;

-- name: 07. average gap between sessions for multi-session users monthly
WITH t1 AS (
    SELECT
        month_start,
        user_id,
        user_session,
        monthly_session_start,

        LEAD(monthly_session_start) OVER (
            PARTITION BY month_start, user_id
            ORDER BY monthly_session_start
        ) next_session_start

    FROM v_monthly_session_activity
),

t2 AS (
    SELECT
        month_start,
        user_id,

        AVG(
            timestampdiff(minute, monthly_session_start, next_session_start)
        ) / (60 * 24) user_avg_gap_days

    FROM t1
    WHERE next_session_start IS NOT NULL
    GROUP BY month_start, user_id
),

t3 AS (
    SELECT DISTINCT month_start
    FROM v_monthly_user_activity
)

SELECT
    t3.month_start,
    COUNT(t2.user_id) multi_session_users,
    AVG(t2.user_avg_gap_days) avg_gap_days
FROM t3
LEFT JOIN t2 ON t3.month_start = t2.month_start
GROUP BY t3.month_start
ORDER BY t3.month_start;

-- name: 08. average active days per user monthly
SELECT
    month_start,
    COUNT(*) total_users,
    AVG(active_days) avg_active_days_per_user
FROM v_monthly_user_activity
GROUP BY month_start
ORDER BY month_start;

-- name: 09. average views carts purchases per user monthly
SELECT
    month_start,
    COUNT(*) total_users,
    AVG(total_views) avg_views_per_user,
    AVG(total_add_carts) avg_add_carts_per_user,
    AVG(total_purchases) avg_purchases_per_user
FROM v_monthly_user_activity
GROUP BY month_start
ORDER BY month_start;


-- name: 10. average distinct categories per user monthly
SELECT
    month_start,
    COUNT(*) total_users,
    AVG(total_categories_viewed) avg_categories_viewed_per_user,
    AVG(total_categories_added_cart) avg_categories_added_cart_per_user,
    AVG(total_categories_purchased) avg_categories_purchased_per_user
FROM v_monthly_user_activity
GROUP BY month_start
ORDER BY month_start;


-- name: 11. average actions per session monthly
SELECT
    month_start,
    COUNT(*) total_sessions,
    AVG(total_actions) avg_actions_per_session
FROM v_monthly_session_activity
GROUP BY month_start
ORDER BY month_start;


-- name: 12. average distinct categories interacted per session monthly
SELECT
    month_start,
    COUNT(*) total_sessions,
    AVG(total_categories_interacted) avg_categories_per_session
FROM v_monthly_session_activity
GROUP BY month_start
ORDER BY month_start;

-- name: monthly user activity link to is_buyer 
with t1 as (
    select month_start, user_id, max(
    CASE 
        WHEN event_type = 'purchase' THEN 1  
        ELSE 0
    END
) is_buyer
from deduplicated_data_processed
group by month_start, user_id
)

select m.*, t1.is_buyer
from t1
inner join v_monthly_user_activity m on t1.user_id = m.user_id 
and t1.month_start = m.month_start

-- name: monthly total revenue
select m.month_start, sum(u.price) total_revenue
from v_monthly_user_activity m 
inner join deduplicated_data_processed u on m.user_id = u.user_id
and m.month_start = u.month_start
where u.event_type ='purchase'
group by m.month_start

-- name: 11 metrics
WITH t1 AS (
    SELECT u.*
    FROM deduplicated_data_processed u
    WHERE EXISTS (
        SELECT 1
        FROM v_monthly_user_activity m
        WHERE m.user_id = u.user_id
          AND m.month_start = u.month_start
    )
),

t2 AS (
    SELECT
        month_start,

        COUNT(DISTINCT user_id) mau,

        COUNT(DISTINCT CASE
            WHEN event_type = 'purchase' THEN user_id
        END) total_buyers,

        SUM(
            CASE WHEN event_type = 'purchase'
                 THEN price ELSE 0 END
        ) gmv

    FROM t1
    GROUP BY month_start
)

SELECT
    month_start,
    mau,
    total_buyers,
    total_buyers / NULLIF(mau, 0) buyer_conversion,
    gmv / NULLIF(total_buyers, 0) gmv_per_buyer,
    gmv
FROM t2
ORDER BY month_start;


-- name: multi-active days, their first seesion action
with t1 as (
    select *, (CASE 
    WHEN active_days = 1 THEN '1_day_active'
    when active_days = 2 then '2_days_active'
    when active_days = 3 then '3_days_active'
    ELSE 'more_than_3_days_active'
END) active_group
from v_monthly_user_activity
),

t2 as (
    select month_start, user_id
from t1
where active_group != '1_day_active'
group by month_start, user_id
),

t3 as (
    select u.*, row_number() over(partition by t2.month_start, t2.user_id 
order by u.event_time) r
from t2 
inner join deduplicated_data_processed u on t2.user_id = u.user_id
and t2.month_start = u.month_start
)

select *
from t3
where r = 1
order by month_start, user_id

-- 10/25 + 10/26
-- name: buyer at first active day
with t1 as (
    select month_start, user_id, min(date(event_time)) first_active_date
from temporary_use
group by month_start, user_id
),

t2 as (
    select u.month_start, u.user_id, max(
    CASE 
        WHEN u.EVENT_type = 'purchase' THEN 1  
        ELSE 0
    END
) is_buyer_at_first_active_day
from t1 inner join temporary_use u on t1.first_active_date = date(u.event_time)
and t1.user_id = u.user_id
group by u.month_start, u.user_id
),

first_day_purchased as (
    select month_start, user_id
from t2
where is_buyer_at_first_active_day = 1
)

select a.month_start, a.user_id, count(distinct a.user_id) total_base, 
count(distinct
    CASE 
        WHEN b.user_id is not null THEN b.user_id  
    END
) is_buyer_first_day_total
from temporary_use a
left join first_day_purchased b on a.user_id = b.user_id
and a.month_start = b.month_start
group by a.month_start, a.user_id

-- name: active day groups between first active and first purchase dates
WITH t1 AS (
    SELECT
        month_start,
        user_id,
        MIN(DATE(event_time)) first_active_date,

        MIN(
            CASE WHEN event_type = 'purchase'
                 THEN DATE(event_time) END
        ) first_purchase_date

    FROM temporary_use
    GROUP BY month_start, user_id
),

user_base AS (
    SELECT
        month_start,
        user_id,
        first_active_date,
        first_purchase_date,

        CASE
            WHEN first_purchase_date IS NOT NULL THEN 1
            ELSE 0
        END is_buyer

    FROM t1
    WHERE first_purchase_date IS NULL
       OR first_purchase_date > first_active_date
),

t2 AS (
    SELECT
        b.month_start,
        b.user_id,
        COUNT(DISTINCT DATE(u.event_time)) total_active_days

    FROM user_base b
    INNER JOIN temporary_use u
      ON b.user_id = u.user_id
     AND b.month_start = u.month_start

    WHERE DATE(u.event_time) > b.first_active_date
      AND DATE(u.event_time) < b.first_purchase_date

    GROUP BY b.month_start, b.user_id
)

SELECT
    b.month_start,
    b.user_id,
    t2.total_active_days,

    CASE
        WHEN t2.total_active_days BETWEEN 1 AND 3 THEN '[1, 3]'
        WHEN t2.total_active_days BETWEEN 4 AND 6 THEN '[4, 6]'
        WHEN t2.total_active_days BETWEEN 7 AND 9 THEN '[7, 9]'
        WHEN t2.total_active_days > 9 THEN '(9, inf)'
    END active_days_group,

    b.is_buyer

FROM user_base b
LEFT JOIN t2
  ON b.user_id = t2.user_id
 AND b.month_start = t2.month_start

ORDER BY b.month_start, b.user_id;

-- name: test_7
select *

-- name: logs from first active day to first purchase day
WITH t1 AS (
    SELECT
        month_start,
        user_id,
        MIN(DATE(event_time)) first_active_date,

        MIN(
            CASE WHEN event_type = 'purchase'
                 THEN DATE(event_time) END
        ) first_purchase_date

    FROM temporary_use
    GROUP BY month_start, user_id
)

SELECT u.*
FROM t1
INNER JOIN temporary_use u
  ON t1.user_id = u.user_id
 AND t1.month_start = u.month_start

WHERE t1.first_purchase_date > t1.first_active_date
  AND DATE(u.event_time) > t1.first_active_date
  and DATE(u.event_time) < t1.first_purchase_date

ORDER BY u.month_start, u.user_id, u.event_time;

-- name: test_3

with t1 as (
    select month_start, user_id, min(date(event_time)) first_active_date
from temporary_use
group by month_start, user_id
),

t2 as (
    select u.month_start, u.user_id, max(
    CASE 
        WHEN u.EVENT_type = 'purchase' THEN 1  
        ELSE 0
    END
) is_buyer_at_first_active_day
from t1 inner join temporary_use u on t1.first_active_date = date(u.event_time)
and t1.user_id = u.user_id
group by u.month_start, u.user_id
),

non_first_day_purchased as (
    select month_start, user_id
from t2
where is_buyer_at_first_active_day = 0
)

select a.month_start, a.user_id, date(b.event_time) date, max(
    CASE 
        WHEN b.event_type = 'purchase' THEN 1  
        ELSE  0
    END
) is_buyer_that_day
from non_first_day_purchased a
inner join temporary_use b on a.user_id = b.user_id
and a.month_start = b.month_start
group by a.month_start, a.user_id, date(b.event_time)


-- name: test_4

with t1 as (
    select month_start, user_id, min(date(event_time)) first_active_date
from temporary_use
group by month_start, user_id
),

t2 as (
    select u.month_start, u.user_id, max(
    CASE 
        WHEN u.EVENT_type = 'purchase' THEN 1  
        ELSE 0
    END
) is_buyer_at_first_active_day
from t1 inner join temporary_use u on t1.first_active_date = date(u.event_time)
and t1.user_id = u.user_id
where day(t1.first_active_date) <= 15 
group by u.month_start, u.user_id
),

non_first_day_purchased as (
    select month_start, user_id
from t2
where is_buyer_at_first_active_day = 0
),

t3 as (
    select a.month_start, a.user_id, date(b.event_time) date, max(
    CASE 
        WHEN b.event_type = 'purchase' THEN 1  
        ELSE  0
    END
) is_buyer_that_day
from non_first_day_purchased a
inner join temporary_use b on a.user_id = b.user_id
and a.month_start = b.month_start
group by a.month_start, a.user_id, date(b.event_time)
)

select t3.*, t1.first_active_date
from t3 inner join t1 on t3.user_id = t1.user_id and t3.month_start = t1.month_start

-- name: test_5

with t1 as (
    select month_start, user_id, min(date(event_time)) first_active_date
from temporary_use
group by month_start, user_id
),

t2 as (
    select u.month_start, u.user_id, max(
    CASE 
        WHEN u.EVENT_type = 'purchase' THEN 1  
        ELSE 0
    END
) is_buyer_at_first_active_day
from t1 inner join temporary_use u on t1.first_active_date = date(u.event_time)
and t1.user_id = u.user_id
group by u.month_start, u.user_id
),

non_first_day_purchased as (
    select t2.month_start, t2.user_id, t1.first_active_date
from t2
inner join t1 on t2.user_id = t1.user_id and t2.month_start = t1.month_start
where t2.is_buyer_at_first_active_day = 0
),

labeled_group as (
    select n.month_start, n.user_id, min(datediff(date(t.event_time), n.first_active_date)) smallest_day_diff,
(CASE 
    WHEN min(datediff(date(t.event_time), n.first_active_date)) <= 10 THEN 'active within 10 days'  
    ELSE  'active after 10 days'
END) is_in_10_days
from non_first_day_purchased n
inner join temporary_use t on n.user_id = t.user_id
and n.month_start = t.month_start AND DATE(t.event_time) > n.first_active_date
group by n.month_start, n.user_id
),

t3 as (
    select a.month_start, a.user_id, max(
    CASE 
        WHEN b.event_type = 'purchase' THEN 1  
        ELSE  0
    END
) is_buyer
from non_first_day_purchased a
inner join temporary_use b on a.user_id = b.user_id
and a.month_start = b.month_start
group by a.month_start, a.user_id
)

select t3.*, l.smallest_day_diff, l.is_in_10_days
from t3 inner join labeled_group l on t3.user_id = l.user_id 
and t3.month_start = l.month_start

-- name: daily October November cohorts early return and subsequent purchase
WITH params AS (
    SELECT CAST('2019-12-20' AS DATE) data_coverage_end
),

t1 AS (
    SELECT
        month_start,
        user_id,
        MIN(DATE(event_time)) first_active_date

    FROM deduplicated_data_processed
    WHERE month_start >= '2019-10-01'
      AND month_start < '2019-12-01'

    GROUP BY month_start, user_id
),

t2 AS (
    SELECT
        b.month_start,
        b.user_id,
        b.first_active_date,

        -- D0-D10 是否购买
        MAX(
            CASE
                WHEN u.event_type = 'purchase'
                 AND u.event_time <
                     DATE_ADD(b.first_active_date, INTERVAL 11 DAY)
                THEN 1 ELSE 0
            END
        ) early_buyer,

        -- D1-D10 是否有跨日回访
        MAX(
            CASE
                WHEN u.event_time >=
                     DATE_ADD(b.first_active_date, INTERVAL 1 DAY)
                 AND u.event_time <
                     DATE_ADD(b.first_active_date, INTERVAL 11 DAY)
                THEN 1 ELSE 0
            END
        ) early_return,

        -- D11-D20 是否购买
        MAX(
            CASE
                WHEN u.event_type = 'purchase'
                 AND u.event_time >=
                     DATE_ADD(b.first_active_date, INTERVAL 11 DAY)
                THEN 1 ELSE 0
            END
        ) subsequent_buyer

    FROM t1 b
    CROSS JOIN params p

    LEFT JOIN deduplicated_data_processed u
      ON b.user_id = u.user_id
     AND u.event_time >= b.first_active_date
     AND u.event_time <
         DATE_ADD(b.first_active_date, INTERVAL 21 DAY)

    WHERE DATE_ADD(b.first_active_date, INTERVAL 20 DAY)
              <= p.data_coverage_end

    GROUP BY b.month_start, b.user_id, b.first_active_date
),

t3 AS (
    SELECT
        first_active_date,
        early_return,
        COUNT(*) total_users,
        SUM(subsequent_buyer) subsequent_buyers

    FROM t2
    WHERE early_buyer = 0

    GROUP BY first_active_date, early_return
),

cohort_dates AS (
    SELECT DISTINCT first_active_date
    FROM t2
),

return_groups AS (
    SELECT 0 early_return
    UNION ALL
    SELECT 1 early_return
)

SELECT
    d.first_active_date,

    CASE
        WHEN g.early_return = 1 THEN 'returned_D1_D10'
        ELSE 'no_return_D1_D10'
    END early_return_group,

    COALESCE(t3.total_users, 0) total_users,
    COALESCE(t3.subsequent_buyers, 0) subsequent_buyers,

    COALESCE(t3.subsequent_buyers, 0)
        / NULLIF(t3.total_users, 0) subsequent_purchase_rate

FROM cohort_dates d
CROSS JOIN return_groups g

LEFT JOIN t3
  ON d.first_active_date = t3.first_active_date
 AND g.early_return = t3.early_return

ORDER BY d.first_active_date, g.early_return;

-- name: cumulative purchase heatmap for October November daily cohorts
WITH RECURSIVE
params AS (
    -- 请填写已确认完整覆盖的数据截止日
    SELECT CAST('2019-12-20' AS DATE) data_coverage_end
),

relative_days AS (
    SELECT 11 relative_day

    UNION ALL

    SELECT relative_day + 1
    FROM relative_days
    WHERE relative_day < 20
),

t1 AS (
    SELECT
        month_start,
        user_id,
        MIN(DATE(event_time)) first_active_date

    FROM deduplicated_data_processed
    WHERE month_start >= '2019-10-01'
      AND month_start < '2019-12-01'

    GROUP BY month_start, user_id
),

t2 AS (
    SELECT
        b.month_start,
        b.user_id,
        b.first_active_date,

        -- D0-D20 内首次购买时间
        MIN(
            CASE WHEN u.event_type = 'purchase'
                 THEN u.event_time END
        ) first_purchase_time,

        -- D1-D10 是否有跨日回访
        MAX(
            CASE
                WHEN u.event_time >=
                     DATE_ADD(b.first_active_date, INTERVAL 1 DAY)
                 AND u.event_time <
                     DATE_ADD(b.first_active_date, INTERVAL 11 DAY)
                THEN 1 ELSE 0
            END
        ) early_return

    FROM t1 b
    CROSS JOIN params p

    LEFT JOIN deduplicated_data_processed u
      ON b.user_id = u.user_id
     AND u.event_time >= b.first_active_date
     AND u.event_time <
         DATE_ADD(b.first_active_date, INTERVAL 21 DAY)

    WHERE DATE_ADD(b.first_active_date, INTERVAL 20 DAY)
              <= p.data_coverage_end

    GROUP BY b.month_start, b.user_id, b.first_active_date
),

t3 AS (
    SELECT
        month_start,
        user_id,
        first_active_date,
        early_return,

        DATEDIFF(
            DATE(first_purchase_time),
            first_active_date
        ) first_purchase_day

    FROM t2

    -- 保留 D0-D10 没有购买的用户
    WHERE first_purchase_time IS NULL
       OR first_purchase_time >=
          DATE_ADD(first_active_date, INTERVAL 11 DAY)
)

SELECT
    t3.first_active_date,

    CASE
        WHEN t3.early_return = 1 THEN 'returned_D1_D10'
        ELSE 'no_return_D1_D10'
    END early_return_group,

    d.relative_day,

    COUNT(*) total_users,

    SUM(
        CASE WHEN t3.first_purchase_day <= d.relative_day
             THEN 1 ELSE 0 END
    ) cumulative_buyers,

    SUM(
        CASE WHEN t3.first_purchase_day <= d.relative_day
             THEN 1 ELSE 0 END
    ) / COUNT(*) cumulative_purchase_rate

FROM t3
CROSS JOIN relative_days d

GROUP BY
    t3.first_active_date,
    t3.early_return,
    d.relative_day

ORDER BY
    t3.first_active_date,
    t3.early_return,
    d.relative_day;


-- name: daily cohorts by early active days and subsequent purchase
WITH params AS (
    -- 请填写已确认完整覆盖的数据截止日
    SELECT CAST('2019-12-20' AS DATE) data_coverage_end
),

t1 AS (
    SELECT
        month_start,
        user_id,
        MIN(DATE(event_time)) first_active_date

    FROM deduplicated_data_processed
    WHERE month_start >= '2019-10-01'
      AND month_start < '2019-12-01'

    GROUP BY month_start, user_id
),

t2 AS (
    SELECT
        b.month_start,
        b.user_id,
        b.first_active_date,

        -- D0-D10 是否购买
        MAX(
            CASE
                WHEN u.event_type = 'purchase'
                 AND u.event_time <
                     DATE_ADD(b.first_active_date, INTERVAL 11 DAY)
                THEN 1 ELSE 0
            END
        ) early_buyer,

        -- D1-D10 的去重活跃天数，不包含 D0
        COUNT(DISTINCT CASE
            WHEN u.event_time >=
                 DATE_ADD(b.first_active_date, INTERVAL 1 DAY)
             AND u.event_time <
                 DATE_ADD(b.first_active_date, INTERVAL 11 DAY)
            THEN DATE(u.event_time)
        END) early_active_days,

        -- D11-D20 是否购买
        MAX(
            CASE
                WHEN u.event_type = 'purchase'
                 AND u.event_time >=
                     DATE_ADD(b.first_active_date, INTERVAL 11 DAY)
                THEN 1 ELSE 0
            END
        ) subsequent_buyer

    FROM t1 b
    CROSS JOIN params p

    LEFT JOIN deduplicated_data_processed u
      ON b.user_id = u.user_id
     AND u.event_time >= b.first_active_date
     AND u.event_time <
         DATE_ADD(b.first_active_date, INTERVAL 21 DAY)

    WHERE DATE_ADD(b.first_active_date, INTERVAL 20 DAY)
              <= p.data_coverage_end

    GROUP BY b.month_start, b.user_id, b.first_active_date
),

t3 AS (
    SELECT
        first_active_date,
        user_id,
        subsequent_buyer,

        CASE
            WHEN early_active_days = 0 THEN 0
            WHEN early_active_days <= 3 THEN 1
            WHEN early_active_days <= 6 THEN 2
            ELSE 3
        END group_order

    FROM t2
    WHERE early_buyer = 0
),

t4 AS (
    SELECT
        first_active_date,
        group_order,
        COUNT(*) total_users,
        SUM(subsequent_buyer) subsequent_buyers

    FROM t3
    GROUP BY first_active_date, group_order
),

cohort_dates AS (
    SELECT DISTINCT first_active_date
    FROM t2
),

active_groups AS (
    SELECT 0 group_order, '0' early_active_days_group
    UNION ALL
    SELECT 1, '[1, 3]'
    UNION ALL
    SELECT 2, '[4, 6]'
    UNION ALL
    SELECT 3, '[7, 10]'
)

SELECT
    d.first_active_date,
    g.early_active_days_group,
    COALESCE(t4.total_users, 0) total_users,
    COALESCE(t4.subsequent_buyers, 0) subsequent_buyers,

    COALESCE(t4.subsequent_buyers, 0)
        / NULLIF(t4.total_users, 0) subsequent_purchase_rate

FROM cohort_dates d
CROSS JOIN active_groups g

LEFT JOIN t4
  ON d.first_active_date = t4.first_active_date
 AND g.group_order = t4.group_order

ORDER BY d.first_active_date, g.group_order;

-- name: 11. 2019 one-day-active users sessions and buyer status
WITH t1 AS (
    SELECT
        month_start,
        user_id,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer,

        SUM(
            CASE WHEN event_type = 'purchase'
                 THEN COALESCE(price, 0) ELSE 0 END
        ) total_purchase_gmv

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-11-01 00:00:00'
      AND event_time < '2019-12-01 00:00:00'

    GROUP BY month_start, user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
)

SELECT
    t1.*,

    CASE
        WHEN total_sessions BETWEEN 1 AND 10 THEN '[1, 10]'
        WHEN total_sessions > 10 AND total_sessions <= 20 THEN '(10, 20]'
        WHEN total_sessions > 20 AND total_sessions <= 50 THEN '(20, 50]'
        WHEN total_sessions > 50 AND total_sessions <= 100 THEN '(50, 100]'
        WHEN total_sessions > 100 THEN '(100, inf]'
    END session_group

FROM t1
ORDER BY user_id;

-- name: 10. 2019 one-day-active users by session group
WITH t1 AS (
    SELECT
        month_start,
        user_id,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer,

        SUM(
            CASE WHEN event_type = 'purchase'
                 THEN COALESCE(price, 0) ELSE 0 END
        ) total_purchase_gmv

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-10-01 00:00:00'
      AND event_time < '2019-11-01 00:00:00'

    GROUP BY month_start, user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
)

SELECT
    t1.*,

    CASE
        WHEN total_sessions BETWEEN 1 AND 10 THEN '[1, 10]'
        WHEN total_sessions > 10 AND total_sessions <= 20 THEN '(10, 20]'
        WHEN total_sessions > 20 AND total_sessions <= 50 THEN '(20, 50]'
        WHEN total_sessions > 50 AND total_sessions <= 100 THEN '(50, 100]'
        WHEN total_sessions > 100 THEN '(100, inf]'
    END session_group

FROM t1
ORDER BY user_id;

-- name: November one-day-active users by October activity
WITH november_users AS (
    SELECT
        user_id,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-11-01 00:00:00'
      AND event_time < '2019-12-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
),

october_users AS (
    SELECT DISTINCT user_id
    FROM deduplicated_data_processed
    WHERE event_time >= '2019-10-01 00:00:00'
      AND event_time < '2019-11-01 00:00:00'
),

t1 AS (
    SELECT
        n.user_id,
        n.is_buyer,

        CASE
            WHEN o.user_id IS NOT NULL THEN 1
            ELSE 0
        END october_active

    FROM november_users n
    LEFT JOIN october_users o
      ON n.user_id = o.user_id
),

user_groups AS (
    SELECT 0 october_active, 'no_October_activity' user_group
    UNION ALL
    SELECT 1, 'had_October_activity'
)

SELECT
    g.user_group,
    COUNT(t1.user_id) user_base,
    COALESCE(SUM(t1.is_buyer), 0) buyer_total,

    COALESCE(SUM(t1.is_buyer), 0)
        / NULLIF(COUNT(t1.user_id), 0) conversion_rate

FROM user_groups g
LEFT JOIN t1
  ON g.october_active = t1.october_active

GROUP BY g.october_active, g.user_group
ORDER BY g.october_active;

-- name: November 2019 one-day-active users by sessions 1 to 10
WITH t1 AS (
    SELECT
        user_id,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-11-01 00:00:00'
      AND event_time < '2019-12-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
       AND COUNT(DISTINCT user_session) BETWEEN 1 AND 10
)

SELECT
    total_sessions,
    COUNT(*) total_base,
    SUM(is_buyer) total_buyer,
    SUM(is_buyer) / COUNT(*) buyer_rate
FROM t1
GROUP BY total_sessions
ORDER BY total_sessions;

-- name: October 2019 one-day-active users by sessions 1 to 10
WITH t1 AS (
    SELECT
        user_id,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-10-01 00:00:00'
      AND event_time < '2019-11-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
       AND COUNT(DISTINCT user_session) BETWEEN 1 AND 10
)

SELECT
    total_sessions,
    COUNT(*) total_base,
    SUM(is_buyer) total_buyer,
    SUM(is_buyer) / COUNT(*) buyer_rate
FROM t1
GROUP BY total_sessions
ORDER BY total_sessions;

-- name: November 2019 logs for one-day-active users with 1 to 3 sessions
WITH t1 AS (
    SELECT
        user_id,

        MIN(
            CASE WHEN event_type = 'purchase'
                 THEN event_time END
        ) first_purchase_time

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-11-01 00:00:00'
      AND event_time < '2019-12-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
       AND COUNT(DISTINCT user_session) BETWEEN 1 AND 3
)

SELECT u.*
FROM deduplicated_data_processed u
INNER JOIN t1 ON u.user_id = t1.user_id

WHERE u.event_time >= '2019-11-01 00:00:00'
  AND u.event_time < '2019-12-01 00:00:00'
  AND (
      t1.first_purchase_time IS NULL
      OR u.event_time <= t1.first_purchase_time
  )

ORDER BY u.user_id, u.event_time;

-- name: October 2019 logs for one-day-active users with 1 to 3 sessions
WITH t1 AS (
    SELECT
        user_id,

        MIN(
            CASE WHEN event_type = 'purchase'
                 THEN event_time END
        ) first_purchase_time

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-10-01 00:00:00'
      AND event_time < '2019-11-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
       AND COUNT(DISTINCT user_session) BETWEEN 1 AND 3
)

SELECT u.*
FROM deduplicated_data_processed u
INNER JOIN t1 ON u.user_id = t1.user_id

WHERE u.event_time >= '2019-10-01 00:00:00'
  AND u.event_time < '2019-11-01 00:00:00'
  AND (
      t1.first_purchase_time IS NULL
      OR u.event_time <= t1.first_purchase_time
  )

ORDER BY u.user_id, u.event_time;

-- name: October November buyer status and sessions for selected users
WITH t1 AS (
    SELECT
        month_start,
        user_id,
        COUNT(DISTINCT DATE(event_time)) total_active_days,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-10-01 00:00:00'
      AND event_time < '2019-12-01 00:00:00'

    GROUP BY month_start, user_id
),

selected_users AS (
    SELECT DISTINCT user_id
    FROM t1
    WHERE total_active_days = 1
      AND total_sessions BETWEEN 1 AND 3
)

SELECT
    m.user_id,

    MAX(
        CASE WHEN m.month_start = '2019-10-01'
             THEN m.is_buyer ELSE 0 END
    ) october_is_buyer,

    MAX(
        CASE WHEN m.month_start = '2019-11-01'
             THEN m.is_buyer ELSE 0 END
    ) november_is_buyer,

    MAX(
        CASE WHEN m.month_start = '2019-10-01'
             THEN m.total_sessions ELSE 0 END
    ) october_total_sessions,

    MAX(
        CASE WHEN m.month_start = '2019-11-01'
             THEN m.total_sessions ELSE 0 END
    ) november_total_sessions

FROM t1 m
INNER JOIN selected_users s
  ON m.user_id = s.user_id

GROUP BY m.user_id
ORDER BY m.user_id;

-- name: October November brand GMV quantity average and rank
WITH t1 AS (
    SELECT
        month_start,
        brand,
        SUM(COALESCE(price, 0)) total_gmv,
        COUNT(*) total_quantity

    FROM deduplicated_data_processed
    WHERE event_type = 'purchase'
      AND event_time >= '2019-10-01 00:00:00'
      AND event_time < '2019-12-01 00:00:00'

    GROUP BY month_start, brand
),

t2 AS (
    SELECT
        t1.*,
        total_gmv / total_quantity avg_gmv,

        DENSE_RANK() OVER (
            PARTITION BY month_start
            ORDER BY total_gmv / total_quantity DESC
        ) brand_rank

    FROM t1
)

SELECT
    brand,

    MAX(
        CASE WHEN month_start = '2019-10-01'
             THEN total_gmv ELSE 0 END
    ) oct_total_gmv,

    MAX(
        CASE WHEN month_start = '2019-10-01'
             THEN total_quantity ELSE 0 END
    ) oct_total_quantity,

    MAX(
        CASE WHEN month_start = '2019-10-01'
             THEN avg_gmv END
    ) oct_avg_gmv,

    MAX(
        CASE WHEN month_start = '2019-10-01'
             THEN brand_rank END
    ) oct_rank,

    MAX(
        CASE WHEN month_start = '2019-11-01'
             THEN total_gmv ELSE 0 END
    ) nov_total_gmv,

    MAX(
        CASE WHEN month_start = '2019-11-01'
             THEN total_quantity ELSE 0 END
    ) nov_total_quantity,

    MAX(
        CASE WHEN month_start = '2019-11-01'
             THEN avg_gmv END
    ) nov_avg_gmv,

    MAX(
        CASE WHEN month_start = '2019-11-01'
             THEN brand_rank END
    ) nov_rank

FROM t2
GROUP BY brand
ORDER BY
    nov_rank IS NULL,
    nov_rank,
    brand;


-- name: November 2019 selected users first view and buyer status
WITH t1 AS (
    SELECT
        user_id,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer,

        MIN(
            CASE WHEN event_type = 'purchase'
                 THEN event_time END
        ) first_purchase_time

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-11-01 00:00:00'
      AND event_time < '2019-12-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
       AND COUNT(DISTINCT user_session) BETWEEN 1 AND 3
),

t2 AS (
    SELECT
        u.user_id,
        u.event_time first_view_time,
        u.category_id,
        u.brand,
        u.price,

        ROW_NUMBER() OVER (
            PARTITION BY u.user_id
            ORDER BY u.event_time
        ) r

    FROM t1
    INNER JOIN deduplicated_data_processed u
      ON t1.user_id = u.user_id

    WHERE u.event_time >= '2019-11-01 00:00:00'
      AND u.event_time < '2019-12-01 00:00:00'
      AND u.event_type = 'view'
      AND (
          t1.first_purchase_time IS NULL
          OR u.event_time < t1.first_purchase_time
      )
)

SELECT
    t1.user_id,
    t1.total_sessions,
    t1.is_buyer,
    t2.first_view_time,
    t2.category_id,
    t2.brand,
    t2.price

FROM t1
LEFT JOIN t2
  ON t1.user_id = t2.user_id
 AND t2.r = 1

ORDER BY t1.user_id;


-- name: October 2019 selected users first view and buyer status
WITH t1 AS (
    SELECT
        user_id,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer,

        MIN(
            CASE WHEN event_type = 'purchase'
                 THEN event_time END
        ) first_purchase_time

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-10-01 00:00:00'
      AND event_time < '2019-11-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
       AND COUNT(DISTINCT user_session) BETWEEN 1 AND 3
),

t2 AS (
    SELECT
        u.user_id,
        u.event_time first_view_time,
        u.category_id,
        u.brand,
        u.price,

        ROW_NUMBER() OVER (
            PARTITION BY u.user_id
            ORDER BY u.event_time
        ) r

    FROM t1
    INNER JOIN deduplicated_data_processed u
      ON t1.user_id = u.user_id

    WHERE u.event_time >= '2019-10-01 00:00:00'
      AND u.event_time < '2019-11-01 00:00:00'
      AND u.event_type = 'view'
      AND (
          t1.first_purchase_time IS NULL
          OR u.event_time < t1.first_purchase_time
      )
)

SELECT
    t1.user_id,
    t1.total_sessions,
    t1.is_buyer,
    t2.first_view_time,
    t2.category_id,
    t2.brand,
    t2.price

FROM t1
LEFT JOIN t2
  ON t1.user_id = t2.user_id
 AND t2.r = 1

ORDER BY t1.user_id;

-- name: November 2019 selected users most interacted product
WITH t1 AS (
    SELECT
        user_id,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer,

        MIN(
            CASE WHEN event_type = 'purchase'
                 THEN event_time END
        ) first_purchase_time

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-11-01 00:00:00'
      AND event_time < '2019-12-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
       AND COUNT(DISTINCT user_session) BETWEEN 1 AND 3
),

t2 AS (
    SELECT
        u.user_id,
        u.product_id,
        u.category_id,
        u.brand,
        u.price,
        u.event_time,

        COUNT(*) OVER (
            PARTITION BY u.user_id, u.product_id
        ) total_interactions,

        MIN(u.event_time) OVER (
            PARTITION BY u.user_id, u.product_id
        ) first_interaction_time

    FROM t1
    INNER JOIN deduplicated_data_processed u
      ON t1.user_id = u.user_id

    WHERE u.event_time >= '2019-11-01 00:00:00'
      AND u.event_time < '2019-12-01 00:00:00'
      AND u.event_type IN ('view', 'cart')
      AND (
          t1.first_purchase_time IS NULL
          OR u.event_time < t1.first_purchase_time
      )
),

t3 AS (
    SELECT
        t2.*,

        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY
                total_interactions DESC,
                first_interaction_time,
                product_id,
                event_time DESC,
                price DESC,
                category_id,
                brand
        ) r

    FROM t2
)

SELECT
    t1.user_id,
    t1.total_sessions,
    t1.is_buyer,
    t3.product_id,
    t3.total_interactions,
    t3.category_id,
    t3.brand,
    t3.price

FROM t1
LEFT JOIN t3
  ON t1.user_id = t3.user_id
 AND t3.r = 1

ORDER BY t1.user_id;



-- name: October 2019 selected users most interacted product
WITH t1 AS (
    SELECT
        user_id,
        COUNT(DISTINCT user_session) total_sessions,

        MAX(
            CASE WHEN event_type = 'purchase'
                 THEN 1 ELSE 0 END
        ) is_buyer,

        MIN(
            CASE WHEN event_type = 'purchase'
                 THEN event_time END
        ) first_purchase_time

    FROM deduplicated_data_processed
    WHERE event_time >= '2019-10-01 00:00:00'
      AND event_time < '2019-11-01 00:00:00'

    GROUP BY user_id
    HAVING COUNT(DISTINCT DATE(event_time)) = 1
       AND COUNT(DISTINCT user_session) BETWEEN 1 AND 3
),

t2 AS (
    SELECT
        u.user_id,
        u.product_id,
        u.category_id,
        u.brand,
        u.price,
        u.event_time,

        COUNT(*) OVER (
            PARTITION BY u.user_id, u.product_id
        ) total_interactions,

        MIN(u.event_time) OVER (
            PARTITION BY u.user_id, u.product_id
        ) first_interaction_time

    FROM t1
    INNER JOIN deduplicated_data_processed u
      ON t1.user_id = u.user_id

    WHERE u.event_time >= '2019-10-01 00:00:00'
      AND u.event_time < '2019-11-01 00:00:00'
      AND u.event_type IN ('view', 'cart')
      AND (
          t1.first_purchase_time IS NULL
          OR u.event_time < t1.first_purchase_time
      )
),

t3 AS (
    SELECT
        t2.*,

        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY
                total_interactions DESC,
                first_interaction_time,
                product_id,
                event_time DESC,
                price DESC,
                category_id,
                brand
        ) r

    FROM t2
)

SELECT
    t1.user_id,
    t1.total_sessions,
    t1.is_buyer,
    t3.product_id,
    t3.total_interactions,
    t3.category_id,
    t3.brand,
    t3.price

FROM t1
LEFT JOIN t3
  ON t1.user_id = t3.user_id
 AND t3.r = 1

ORDER BY t1.user_id;
