-- Q1: Daily Performance
-- CTE joins visits to dim_date, aggregates daily visits & spend
-- Uses running total window to find growth over time


WITH dailyperformance AS (
    SELECT 
        d.date_iso,
        d.day_name,
        COUNT(DISTINCT v.visit_id) AS daily_visits,
        SUM(v.spend_cents_clean) AS daily_spend
    FROM fact_visits v
    JOIN dim_date d ON v.date_id = d.date_id
    GROUP BY d.date_iso, d.day_name
)
SELECT 
    date_iso,
    day_name,
    daily_visits,
    daily_spend,
    SUM(daily_visits) OVER (ORDER BY date_iso) AS running_visits,
    SUM(daily_spend) OVER (ORDER BY date_iso) AS running_spend,
    RANK() OVER (ORDER BY daily_visits DESC) AS visit_rank
FROM dailyperformance
ORDER BY date_iso;

-- AWES:
-- Answer: Top 3 peak days are those with visit_rank = 1,2,3
-- Why: High demand days stress staff, queues, and rides
-- Example: If July 4th ranks #1, it shows holiday surges
-- Summary: Ops should allocate extra staff on these peak days

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Q2: RFM & CLV (Customer Lifetime Value Proxy)
-- Recency (days since last visit), Frequency (# visits), Monetary (total spend)
-- CLV proxy = SUM(spend_cents_clean)

WITH guest_visits AS (
    SELECT 
        g.guest_id,
        g.home_state,
        MAX(v.visit_date) AS last_visit,
        COUNT(v.visit_id) AS frequency,
        SUM(v.spend_cents_clean) AS monetary
    FROM fact_visits v
    JOIN dim_guest g ON v.guest_id = g.guest_id
    GROUP BY g.guest_id, g.home_state
),
rfm AS (
    SELECT 
        guest_id,
        home_state,
        JULIANDAY((SELECT MAX(visit_date) FROM fact_visits)) - JULIANDAY(last_visit) AS recency,
        frequency,
        monetary,
        RANK() OVER (PARTITION BY home_state ORDER BY monetary DESC) AS clv_rank
    FROM guest_visits
)
SELECT * FROM rfm
ORDER BY home_state, clv_rank;

-- AWES:
-- Answer: High-value guests cluster in certain states
-- Why: Some states send frequent/recent visitors with higher spend
-- Example: If California guests rank top in CLV, target promos there
-- Summary: Marketing should double down on high-value home states

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-- Q3: Behavior Change with LAG()
-- Compare each visit’s spend to prior visit for the same guest
-- Compute delta and % who increased spending


WITH visit_ordered AS (
    SELECT 
        v.guest_id,
        v.visit_id,
        v.visit_date,
        v.spend_cents_clean,
        LAG(v.spend_cents_clean) OVER (PARTITION BY v.guest_id ORDER BY v.visit_date) AS prior_spending
    FROM fact_visits v
),
deltas AS (
    SELECT 
        guest_id,
        visit_id,
        spend_cents_clean,
        prior_spending,
        spend_cents_clean - prior_spending AS delta
    FROM visit_ordered
    WHERE prior_spending IS NOT NULL
)
SELECT 
    COUNT(*) AS total_repeat_visits,
    SUM(CASE WHEN delta > 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pct_increased
FROM deltas;

-- AWES:
-- Answer: % of repeat visits that increased spend
-- Why: Indicates if guests are growing more valuable or dropping off
-- Example: If 65% increased, marketing can link it to promotions/ticket types
-- Summary: Ops/Marketing should reinforce what drives positive deltas

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Q4: Ticket Switching with FIRST_VALUE()
-- Identify if a guest ever changed ticket type


WITH ticket_history AS (
    SELECT 
        v.guest_id,
        v.visit_date,
        t.ticket_type_name,
        FIRST_VALUE(t.ticket_type_name) OVER (PARTITION BY v.guest_id ORDER BY v.visit_date) AS first_ticket
    FROM fact_visits v
    JOIN dim_ticket t ON v.ticket_type_id = t.ticket_type_id
),
switches AS (
    SELECT 
        guest_id,
        CASE 
            WHEN COUNT(DISTINCT ticket_type_name) > 1 THEN 1
            ELSE 0
        END AS switched_ticket
    FROM ticket_history
    GROUP BY guest_id
)
SELECT 
    switched_ticket,
    COUNT(*) AS num_guests
FROM switches
GROUP BY switched_ticket;

-- AWES:
-- Answer: % of guests who switch ticket types
-- Why: Shows how pricing/packages influence loyalty
-- Example: If 20% switch from Day Pass to Family or VIP Pass, it’s an upgrade trend
-- Summary: Marketing should design targeted upsell paths