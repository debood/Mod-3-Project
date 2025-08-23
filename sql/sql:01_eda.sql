-- Q1: Date range of visit_date; number of distinct dates; visits per date
-- Shows the time span of data and daily visit number
SELECT 
    MIN(visit_date) AS start_date,
    MAX(visit_date) AS max_date,
    COUNT(DISTINCT visit_date) AS distinct_date
FROM fact_visits;

-- Daily visits 
SELECT 
    visit_date,
    COUNT(DISTINCT visit_id) AS daily_visits
FROM fact_visits
GROUP BY visit_date
ORDER BY visit_date;



-- Q2: Visits by ticket_type_name (joined to dim_ticket), ordered by most to least
SELECT 
    dt.ticket_type_name,
    COUNT(f.visit_id) AS total_visits
FROM fact_visits f
JOIN dim_ticket dt ON f.ticket_type_id = dt.ticket_type_id
GROUP BY dt.ticket_type_name
ORDER BY total_visits DESC;



-- Q3: Distribution of wait_minutes (with NULL count)
-- Useful to see how many missing values exist and typical ranges
SELECT
    CASE 
        WHEN wait_minutes IS NULL THEN 'NULL'
        WHEN wait_minutes BETWEEN 0 AND 15 THEN '0–15'
        WHEN wait_minutes BETWEEN 16 AND 30 THEN '16–30'
        WHEN wait_minutes BETWEEN 31 AND 60 THEN '31–60'
        ELSE '>60'
    END AS wait_bucket,
    COUNT(*) AS num_minutes
FROM fact_ride_events
GROUP BY wait_bucket
ORDER BY 
    CASE wait_bucket 
        WHEN 'NULL' THEN 1
        WHEN '0–15' THEN 2
        WHEN '16–30' THEN 3
        WHEN '31–60' THEN 4
        ELSE 5
    END;



-- Q4: Average satisfaction_rating by attraction_name and category
-- Helps find which rides or ride types are performing best
SELECT 
    da.attraction_name,
    da.category,
    ROUND(AVG(satisfaction_rating), 2) AS avg_satisfaction,
    COUNT(*) AS num_rides
FROM fact_ride_events r
JOIN dim_attraction da ON r.attraction_id = da.attraction_id
GROUP BY da.attraction_name, da.category
ORDER BY avg_satisfaction DESC;



-- Q5: Duplicate check in fact_ride_events (all columns must match)
-- If duplicates exist, they should be removed or flagged
SELECT 
    visit_id,
    attraction_id,
    ride_time,
    wait_minutes,
    satisfaction_rating,
    photo_purchase,
    COUNT(*) AS dup_count
FROM fact_ride_events
GROUP BY 
    visit_id,
    attraction_id,
    ride_time,
    wait_minutes,
    satisfaction_rating,
    photo_purchase
HAVING COUNT(*) > 1;



-- Q6: Null audit for key columns (important fields for analysis)
-- This reveals null values in columns 
SELECT 
    SUM(CASE WHEN guest_id IS NULL THEN 1 ELSE 0 END) AS num_null_guest_id,
    SUM(CASE	WHEN ticket_type_id IS NULL THEN 1 ELSE 0 END) AS num_null_ticket_type_id,
    SUM(CASE WHEN attraction_id IS NULL THEN 1 ELSE 0 END) AS num_null_attraction_id,
    SUM(CASE WHEN total_spend_cents IS NULL THEN 1 ELSE 0 END) AS num_null_total_spend,
    SUM(CASE WHEN satisfaction_rating IS NULL THEN 1 ELSE 0 END) AS num_null_satisfaction
FROM (
    SELECT guest_id, ticket_type_id, total_spend_cents, NULL AS attraction_id, NULL AS satisfaction_rating
    FROM fact_visits
    UNION ALL
    SELECT NULL AS guest_id, NULL AS ticket_type_id, NULL AS total_spend_cents, attraction_id, satisfaction_rating
    FROM fact_ride_events);



-- Q7: Average party_size by day of week
SELECT 
    d.day_name,
    ROUND(AVG(v.party_size), 2) AS avg_party_size,
    COUNT(v.visit_id) AS num_visits
FROM fact_visits v
JOIN dim_date d ON v.date_id = d.date_id
GROUP BY d.day_name
ORDER BY avg_party_size DESC;