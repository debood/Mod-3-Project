-- If you haven't added these yet, run them ONCE (comment out if they already exist)

-- ALTER TABLE fact_visits    ADD COLUMN spend_cents_clean   INTEGER;
-- ALTER TABLE fact_purchases ADD COLUMN amount_cents_clean  INTEGER;

-- Visits: compute cleaned once, join by rowid, update when cleaned is non-empty
WITH c AS (
  SELECT
    rowid AS rid,
    REPLACE(REPLACE(REPLACE(REPLACE(UPPER(COALESCE(total_spend_cents,'')),
      'USD',''), '$',''), ',', ''), ' ', '') AS cleaned
  FROM fact_visits
)
UPDATE fact_visits
SET spend_cents_clean = CAST((SELECT cleaned FROM c WHERE c.rid = fact_visits.rowid) AS INTEGER)
WHERE LENGTH((SELECT cleaned FROM c WHERE c.rid = fact_visits.rowid)) > 0;

-- Purchases: same pattern (WRITE THE SAME CODE ABOVE for the fact_purchases table)  

-- Remember facts_visits and facts_purchases has the `amount` column in units of cents so you may need to do another SELECT statement to convert these columns to dollars


-- Check how many rows have non-null cleaned values
SELECT 
  COUNT(*) AS total_visits, 
  SUM(CASE WHEN spend_cents_clean IS NOT NULL THEN 1 ELSE 0 END) AS cleaned_visits
FROM fact_visits;

SELECT 
  COUNT(*) AS total_purchases, 
  SUM(CASE WHEN amount_cents_clean IS NOT NULL THEN 1 ELSE 0 END) AS cleaned_purchases
FROM fact_purchases;


-- B) Duplicates
-- Detect exact duplicates, all non-PK fields must match


-- Step 1: Count duplicate groups
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

-- Step 2: Remove duplicates but keep one copy
-- Keep the lowest rowid in each duplicate group
DELETE FROM fact_ride_events
WHERE rowid NOT IN (
    SELECT MIN(rowid)
    FROM fact_ride_events
    GROUP BY 
        visit_id,
        attraction_id,
        ride_time,
        wait_minutes,
        satisfaction_rating,
        photo_purchase
);

-- Comment:
-- 1. ride_event_id is a PK, so duplicates will differ by PK but match on all other fields.
-- 2. This logic ensures we keep the "first" row in each duplicate set and remove extras.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- C) Validate Keys
-- Ensure foreign keys match parent dimension tables


-- Orphan visits (guest_id not in dim_guest)
SELECT v.visit_id, v.guest_id
FROM fact_visits v
LEFT JOIN dim_guest g ON g.guest_id = v.guest_id
WHERE g.guest_id IS NULL;

-- Orphan visits (ticket_type_id not in dim_ticket) 
SELECT v.visit_id, v.ticket_type_id
FROM fact_visits v
LEFT JOIN dim_ticket t ON t.ticket_type_id = v.ticket_type_id
WHERE t.ticket_type_id IS NULL;

-- Orphan ride events (attraction_id not in dim_attraction) 
SELECT r.ride_event_id, r.attraction_id
FROM fact_ride_events r
LEFT JOIN dim_attraction a ON a.attraction_id = r.attraction_id
WHERE a.attraction_id IS NULL;

-- Orphan purchases (visit_id not in fact_visits) 
SELECT p.purchase_id, p.visit_id
FROM fact_purchases p
LEFT JOIN fact_visits v ON v.visit_id = p.visit_id
WHERE v.visit_id IS NULL;

-- No orphan keys found during validation

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- D) Handle Missing Values


-- Essential numeric fields, set unusable values to NULL
UPDATE fact_visits
SET spend_cents_clean = NULL
WHERE spend_cents_clean <= 0;

UPDATE fact_ride_events
SET wait_minutes = NULL
WHERE wait_minutes < 0;

-- Text fields: normalize casing and trim spaces
UPDATE dim_guest
SET home_state = UPPER(TRIM(home_state));

UPDATE dim_guest
SET home_state = 'NY'
WHERE home_state IN ('NEW YORK');

UPDATE fact_visits
SET promotion_code = UPPER(TRIM(promotion_code));

-- Normalize payment_method
UPDATE fact_purchases
SET payment_method = UPPER(TRIM(REPLACE(payment_method, ',', '')));


-- Standardize attraction_name casing
UPDATE dim_attraction
SET attraction_name = TRIM(attraction_name);

-- Fix specific duplicates
UPDATE dim_attraction
SET attraction_name = 'Galaxy Coaster'
WHERE LOWER(attraction_name) = 'galaxy coaster';

UPDATE dim_attraction
SET attraction_name = 'Pirate Splash'
WHERE LOWER(attraction_name) IN ('pirate splash!', 'pirate splash');



-- Report missing counts for documentation
SELECT 
  SUM(CASE WHEN spend_cents_clean IS NULL THEN 1 ELSE 0 END) AS missing_spend,
  SUM(CASE WHEN party_size IS NULL THEN 1 ELSE 0 END) AS missing_party_size,
  SUM(CASE WHEN wait_minutes IS NULL THEN 1 ELSE 0 END) AS missing_waits,
  SUM(CASE WHEN satisfaction_rating IS NULL THEN 1 ELSE 0 END) AS missing_satisfaction
FROM fact_visits v
LEFT JOIN fact_ride_events r ON v.visit_id = r.visit_id;
