
-- Feature 1: stay_minutes
-- From entry_time to exit_time
-- Why: GM & Ops need to know how long guests stay; longer stays = more spend potential

ALTER TABLE fact_visits ADD COLUMN stay_minutes INTEGER;

UPDATE fact_visits
SET stay_minutes = 
  CAST((JULIANDAY(exit_time) - JULIANDAY(entry_time)) * 24 * 60 AS INTEGER)
WHERE entry_time IS NOT NULL AND exit_time IS NOT NULL;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 


-- Feature 2: spend_cents_clean (already created in cleaning)
-- But also compute spend_per_person for Marketing
-- Why: Marketing cares about per-person value, not just group spend

ALTER TABLE fact_visits ADD COLUMN spend_per_person INTEGER;

UPDATE fact_visits
SET spend_per_person = 
  CASE 
    WHEN party_size > 0 THEN CAST(spend_cents_clean / party_size AS INTEGER)
    ELSE NULL
  END;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Feature 3: visit_hour_bucket
-- Groups entry time into buckets (Morning, Afternoon, Evening)
-- Why: Ops can schedule staff better by guest arrival times

ALTER TABLE fact_visits ADD COLUMN visit_hour_bucket TEXT;

UPDATE fact_visits
SET visit_hour_bucket = CASE 
  WHEN CAST(SUBSTR(entry_time, 1, 2) AS INTEGER) BETWEEN 6 AND 11 THEN 'Morning'
  WHEN CAST(SUBSTR(entry_time, 1, 2) AS INTEGER) BETWEEN 12 AND 17 THEN 'Afternoon'
  WHEN CAST(SUBSTR(entry_time, 1, 2) AS INTEGER) BETWEEN 18 AND 23 THEN 'Evening'
  ELSE 'Unknown'
END
WHERE entry_time IS NOT NULL;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Feature 4: wait_bucket
-- Groups wait_minutes into ranges for staffing analysis
-- Why: Ops can identify when waits exceed acceptable thresholds

ALTER TABLE fact_ride_events ADD COLUMN wait_bucket TEXT;

UPDATE fact_ride_events
SET wait_bucket = CASE
  WHEN wait_minutes BETWEEN 0 AND 15 THEN '0–15'
  WHEN wait_minutes BETWEEN 16 AND 30 THEN '16–30'
  WHEN wait_minutes BETWEEN 31 AND 60 THEN '31–60'
  WHEN wait_minutes > 60 THEN '>60'
  ELSE 'Unknown'
END;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Feature 5 (extra): is_repeat_guest
-- Flag if a guest has >1 visit
-- Why: Marketing/GM can target repeat visitors for loyalty campaigns
-- A 1 indicates that the guest is a loyal customer and a 0 indicates that this is the guests' first time here

ALTER TABLE fact_visits ADD COLUMN is_repeat_guest INTEGER;

UPDATE fact_visits
SET is_repeat_guest = CASE
  WHEN guest_id IN (
    SELECT guest_id
    FROM fact_visits
    GROUP BY guest_id
    HAVING COUNT(*) > 1
  ) THEN 1
  ELSE 0
END;