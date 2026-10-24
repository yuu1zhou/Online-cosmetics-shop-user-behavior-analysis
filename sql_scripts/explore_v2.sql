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

-- name: monthly total revenue
select month_start, sum(price) total_revenue
from deduplicated_data_processed
where event_type = 'purchase'
group by month_start


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
