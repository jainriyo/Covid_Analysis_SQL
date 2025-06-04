/*
===============================================================
  Project Title : COVID-19 Data Analysis using SQL
  Author        : Riya Jain
  Description   : This SQL script performs an in-depth analysis 
                  of COVID-19 trends using country-wise and 
                  time-series data. It covers daily cases,
                  weekly trends, growth rates, top affected 
                  countries, and surge detection.

  Dataset Used  : COVID-19 (from WHO, Worldometer, etc.)
  Tools Used    : SQLite, Power BI, GitHub
  SQL Dialect   : SQLite

  Objectives:
  - Track daily and weekly trends of confirmed cases
  - Identify top 10 countries by total or new cases
  - Calculate week-over-week growth rates
  - Total Confirmed Cases by Continent
  - 

  Last Updated  : June 2025
===============================================================
*/



/*Maximum Deaths by No. of countries*/

SELECT MAX(Covid191.c3) AS total_Deaths
FROM Covid191
GROUP BY Covid191.c12
ORDER BY Covid191.c3 DESC
LIMIT 20;




/*Total Confirmed Cases by Continent*/

SELECT covid194worldometer.c2, SUM(covid194worldometer.c4) AS Total_Cases
FROM covid194worldometer
GROUP BY covid194worldometer.c2
ORDER BY covid194worldometer.c4 DESC;


/*Countries with High Death Rate (>5%)*/

SELECT covid194worldometer.c1,covid194worldometer.c6, covid194worldometer.c4,
       ROUND((covid194worldometer.c6 * 100.0) / covid194worldometer.c4, 2) AS DeathRate
FROM covid194worldometer
WHERE covid194worldometer.c4 > 10000
AND (covid194worldometer.c6 * 1.0 / covid194worldometer.c4) > 0.05
ORDER BY DeathRate DESC;


/*Population to Find Case Penetration per 1M People*/

SELECT covid194worldometer.c1, covid194worldometer.c4, covid194worldometer.c3,
       ROUND((covid194worldometer.c4 * 1000000.0) / covid194worldometer.c3, 2) AS Cases_Per_Million
FROM covid194worldometer
WHERE covid194worldometer.c3 > 0
ORDER BY Cases_Per_Million DESC;



/*Growth in Confirmed Cases (Week over Week)*/

SELECT Country_Region, Date,
       Confirmed - LAG(Confirmed, 7) OVER (PARTITION BY Country_Region ORDER BY Date) AS Weekly_Growth
FROM daily_clean
ORDER BY Country_Region, Date;
)




/*Most Improved Recovery Rate (Monthly)*/
SELECT covid195cleacomplete.c2, 
       MAX(covid195cleacomplete.c8) - MIN(covid195cleacomplete.C8) AS Recovery_Growth
FROM covid195cleacomplete
WHERE covid195cleacomplete.c5 BETWEEN '2020-06-01' AND '2020-06-30'
GROUP BY covid195cleacomplete.c2
ORDER BY Recovery_Growth DESC
LIMIT 5;



/*7-Day Moving Average of New Cases per Country*/
SELECT Covid191.c12, Covid191.c1,
       AVG(Covid191.c6) OVER (PARTITION BY Covid191.c12 ORDER BY Covid191.c1 ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS MovingAvg_NewCases
FROM Covid191
ORDER BY Covid191.c12, Covid191.c1;




/*Growth Rate of Cases Over Time*/
SELECT Covid191.c12, Covid191.c1,
       Covid191.c2,
       LAG(Covid191.c2, 1) OVER (PARTITION BY Covid191.c12 ORDER BY Covid191.c1) AS Previous_Day_Confirmed,
       ROUND(((Covid191.c2 - LAG(Covid191.c2, 1) OVER (PARTITION BY Covid191.c12 ORDER BY Covid191.c1)) * 100.0) 
             / NULLIF(LAG(Covid191.c2, 1) OVER (PARTITION BY Covid191.c12 ORDER BY Covid191.c1), 0), 2) AS Growth_Percentage
FROM Covid191
WHERE Covid191.c2 IS NOT NULL
ORDER BY Covid191.c12, Covid191.c1;



/*Top 3 Countries with Highest Tests Per 1M Population*/
SELECT covid194worldometer.c1, covid194worldometer.c15
FROM covid194worldometer
WHERE covid194worldometer.C15 IS NOT NULL
ORDER BY covid194worldometer.C15 DESC
LIMIT 4;



/*Countries with High Deaths But Low Recovery Rate*/
SELECT covid194worldometer.c1, covid194worldometer.c6, covid194worldometer.c8, covid194worldometer.c4,
       ROUND((covid194worldometer.c8 * 100.0) / covid194worldometer.c4, 2) AS RecoveryRate,
       ROUND((covid194worldometer.c6 * 100.0) / covid194worldometer.c4, 2) AS DeathRate
FROM covid194worldometer
WHERE covid194worldometer.c4 > 50000
AND (covid194worldometer.c8 * 1.0 / covid194worldometer.c4) < 0.5
ORDER BY DeathRate DESC;



/*Compare Case Fatality Rate Across Continents*/
SELECT covid194worldometer.c2,
       SUM(covid194worldometer.c4) AS Total_Cases,
       SUM(covid194worldometer.c6) AS Total_Deaths,
       ROUND((SUM(covid194worldometer.c6) * 100.0) / SUM(covid194worldometer.c4), 2) AS CFR
FROM covid194worldometer
GROUP BY covid194worldometer.c2
ORDER BY CFR DESC;



/*Active Cases Using Total - Deaths - Recovered*/
SELECT covid194worldometer.c1,
       covid194worldometer.c4,
       covid194worldometer.c6,
       covid194worldometer.c8,
       (covid194worldometer.c4 - covid194worldometer.c6 - covid194worldometer.c8) AS Computed_ActiveCases
FROM covid194worldometer
ORDER BY Computed_ActiveCases DESC;




/*First Date When a Country Crossed 1000 Cases*/
SELECT Covid191.c12, MIN(Covid191.c1) AS First_Date_Over_1000
FROM Covid191
WHERE Covid191.c2 >= 1000
GROUP BY Covid191.c12
ORDER BY First_Date_Over_1000;





/*Detect sudden surge (spike) in new confirmed cases (day-to-day jump > 50%)*/
WITH daily AS (
  SELECT 
    c2 AS country,
    c5 AS date,
    c6 AS total_cases,
    c6 - LAG(c6) OVER (PARTITION BY c2 ORDER BY c5) AS new_cases
  FROM covid195cleacomplete
),
surges AS (
  SELECT 
    c2,
    c1,
    c7,
    LAG(c7) OVER (PARTITION BY c2 ORDER BY c1) AS prev_day_cases
  FROM covid192
)
SELECT 
  c2,
  c1,
  c7,
  prev_day_cases,
  ROUND(100.0 * (c7 - prev_day_cases) / NULLIF(prev_day_cases, 0), 2) || '%' AS percent_change
FROM surges
WHERE prev_day_cases IS NOT NULL
  AND c7 > 1.5 * prev_day_cases
ORDER BY CAST(REPLACE(ROUND(100.0 * (c7 - prev_day_cases) / NULLIF(prev_day_cases, 0), 2) || '%', '%', '') AS REAL) DESC;