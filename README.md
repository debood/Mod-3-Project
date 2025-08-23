# Mod 3 Project – Theme Park Analytics
##### By Debo Odutola

## 📂 Project Overview
This project analyzes a theme park’s guest behavior using a star-schema database (`themepark.db`).  
The goal was to prepare clean data, run exploratory SQL, and generate Python visuals to provide actionable insights for three stakeholder groups: **General Manager (GM)**, **Operations**, and **Marketing**.

---

## 🛠️ Process Summary
1. **Schema Review**  
   - Verified star schema structure (dim_guest, dim_ticket, dim_attraction, fact_visits, fact_ride_events, fact_purchases).  
   - Confirmed primary and foreign key integrity (no orphaned keys).  

2. **Data Cleaning**  
   - Removed duplicates from fact tables (`fact_ride_events`) while preserving one record.  
   - Standardized categorical values:  
     - `dim_guest.home_state` → collapsed variants (`NY`, `NEW YORK` → `NY`).  
     - `fact_purchases.payment_method` → standardized (`cash`, `card`, `CARD,`, `Apple Pay` → `CASH`, `CARD`, `APPLE PAY`).  
     - `dim_attraction.attraction_name` → trimmed punctuation/case (`Galaxy Coaster` vs `Galaxy coaster`; `Pirate Splash!` vs `Pirate Splash`).  
   - Normalized casing and trimmed whitespace in string columns.  
   - Validated numeric fields (wait times, spend, ratings) and set out-of-range values to `NULL`.  

3. **Exploratory SQL Queries (EDA)**  
   - Attendance trends over time.  
   - Guest demographics and ticket breakdown.  
   - Ride utilization and satisfaction.  
   - Purchases by category and payment method.  

4. **Note**  
   - While building Python visuals, I noticed data quality issues (e.g., duplicate state names, inconsistent payment methods).  
   - This sent me back to SQL to improve cleaning.  
   - Visualizations are a powerful tool for catching hidden inconsistencies.

---

## 📊 Python Visuals

### 1. Daily Attendance & Spend
- Attendance and revenue rise together, indicating strong per-guest spend consistency.

### 2. CLV by State
- Certain states (NY, CA, TX) contribute disproportionately to guest lifetime value.  
- Useful for targeted marketing campaigns and loyalty programs.

### 3. Attraction Wait Time vs Satisfaction
- Longer waits (>30 minutes) correlate with lower satisfaction.  
- Popular thrill rides (coasters, water rides) suffer the steepest drops when waits exceed 45 minutes.  
- Operations should implement queue management or capacity redistribution.

---

## 💡 Insights & Recommendations

**General Manager (GM)**  
- Plan staffing and hours around peak holidays (attendance & revenue spikes).  
- Balance growth (more guests) with experience (avoid long waits).

**Operations**  
- Reallocate staff to high-wait attractions.  
- Introduce virtual queues or staggered openings to protect satisfaction.

**Marketing**  
- Focus campaigns on high-value states (NY, CA, TX).  
- Promote in-park purchases, not just admissions, to increase per-guest revenue.  
- Leverage CLV segmentation for repeat-guest loyalty programs.

---

## ⚖️ Ethics & Bias
- Data cleaning ensured fairness (e.g., resolving duplicate states so one region isn’t over/underrepresented).  
- Analysis is limited to in-park behavior — we avoid inferring demographics or socioeconomic status beyond the data.  
- Recognize that high-spending states may correlate with travel privilege, so recommendations should balance inclusivity.
