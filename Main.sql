USE CostOfLiving;

SELECT TOP 100 *
FROM CPI_RawData;

SELECT COUNT(*) AS TotalRows
FROM CPI_RawData;

-- Delete the metadata rows
DELETE FROM CPI_RawData
WHERE Unit IS NULL 
   OR Index_Numbers = 'INDEX'
   OR Index_Numbers = 'Quarter'
   OR Index_Numbers = '3'
   OR Index_Numbers LIKE 'Sep-%'
   OR Index_Numbers LIKE 'Mar-%'
   OR Index_Numbers LIKE 'A%';

-- Rename key columns for analysis
-- Sydney columns (columns 2-13 in original, which are Index_Numbers, Index_Numbers2, etc.)
EXEC sp_rename 'CPI_RawData.Index_Numbers', 'Sydney_Food', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers4', 'Sydney_Housing', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers7', 'Sydney_Transport', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers12', 'Sydney_AllGroups', 'COLUMN';

-- Melbourne columns (columns 14-25, which are Index_Numbers13-24)
EXEC sp_rename 'CPI_RawData.Index_Numbers13', 'Melbourne_Food', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers16', 'Melbourne_Housing', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers19', 'Melbourne_Transport', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers24', 'Melbourne_AllGroups', 'COLUMN';

-- Brisbane columns (columns 26-37, which are Index_Numbers25-36)
EXEC sp_rename 'CPI_RawData.Index_Numbers25', 'Brisbane_Food', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers28', 'Brisbane_Housing', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers31', 'Brisbane_Transport', 'COLUMN';
EXEC sp_rename 'CPI_RawData.Index_Numbers36', 'Brisbane_AllGroups', 'COLUMN';

SELECT TOP 5 
    Unit,
    Sydney_Food,
    Sydney_Housing,
    Melbourne_Food,
    Melbourne_Housing,
    Brisbane_Food,
    Brisbane_Housing
FROM CPI_RawData
WHERE Sydney_Food IS NOT NULL
ORDER BY Unit DESC;

SELECT TOP 1 *
FROM CPI_RawData;

SELECT 
    Unit, 
    Sydney_Food, 
    Sydney_Housing, 
    Sydney_Transport, 
    Sydney_AllGroups,
    Melbourne_Food, 
    Melbourne_Housing, 
    Melbourne_Transport, 
    Melbourne_AllGroups
FROM  CPI_RawData
WHERE Unit = '2025-03-01';

--See how much usable data we have
SELECT 
    MIN(Unit) As EarliestDate,
    MAX(Unit) As LatestDate,
    Count(*) As TotalRows
FROM CPI_RawData
WHERE Unit>= '1970-01-01';

SELECT TOP 5
    Unit,
    Sydney_Food,
    Sydney_Housing,
    Sydney_Transport,
    Sydney_AllGroups,
    Melbourne_Food,
    Melbourne_Housing
FROM CPI_RawData
WHERE Unit >= '1970-03-19'
  AND Sydney_Food IS NOT NULL
ORDER BY Unit DESC;

--What are the current cost of living differences between Sydney, Melbourne, and Brisbane?

SELECT 
    Unit AS [Quarter],
    Sydney_AllGroups, 
    Melbourne_AllGroups, 
    Brisbane_AllGroups, 
    --Calculate differences
    CAST(Sydney_AllGroups AS DECIMAL(10,2)) - CAST(Melbourne_AllGroups AS DECIMAL(10,2)) AS Sydney_vs_Melbourne_Diff, 
    CAST(Sydney_AllGroups AS DECIMAL(10,2)) - CAST(Brisbane_AllGroups AS DECIMAL(10,2) )AS Sydney_vs_Brisbane_Diff
FROM CPI_RawData
WHERE Unit = (SELECT MAX(UNIT) FROM CPI_RawData WHERE Unit < '2026-01-01')
      AND Sydney_AllGroups IS NOT NULL;

--Which expense categories (Food, Housing, Transport) differ most between Sydney, Melbourne, and Brisbane in the most recent quarter?

SELECT 
    Unit AS Quarter,
    -- Sydney
    CAST(Sydney_Food AS DECIMAL(10,2)) AS Sydney_Food,
    CAST(Sydney_Housing AS DECIMAL(10,2)) AS Sydney_Housing,
    CAST(Sydney_Transport AS DECIMAL(10,2)) AS Sydney_Transport,
    -- Melbourne  
    CAST(Melbourne_Food AS DECIMAL(10,2)) AS Melbourne_Food,
    CAST(Melbourne_Housing AS DECIMAL(10,2)) AS Melbourne_Housing,
    CAST(Melbourne_Transport AS DECIMAL(10,2)) AS Melbourne_Transport,
    -- Brisbane
    CAST(Brisbane_Food AS DECIMAL(10,2)) AS Brisbane_Food,
    CAST(Brisbane_Housing AS DECIMAL(10,2)) AS Brisbane_Housing,
    CAST(Brisbane_Transport AS DECIMAL(10,2)) AS Brisbane_Transport
FROM CPI_RawData
WHERE Unit = (SELECT MAX(Unit) FROM CPI_RawData WHERE Unit < '2026-01-01')
  AND Sydney_Food IS NOT NULL;

--Differences 
-- Change the data type of columns from nvarchar to decimal
ALTER TABLE CPI_RawData
ALTER COLUMN Sydney_Food DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Sydney_Housing DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Sydney_Transport DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Sydney_AllGroups DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Melbourne_Food DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Melbourne_Housing DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Melbourne_Transport DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Melbourne_AllGroups DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Brisbane_Food DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Brisbane_Housing DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Brisbane_Transport DECIMAL(10,2);

ALTER TABLE CPI_RawData
ALTER COLUMN Brisbane_AllGroups DECIMAL(10,2);

SELECT
    Unit AS Quarter, 
    Sydney_Housing, 
    Brisbane_Housing, 
    Melbourne_Housing, 

    Sydney_Food,
    Brisbane_Food
    Melbourne_Food,

    Sydney_Transport,
    Brisbane_Transport,
    Melbourne_Transport,

    Sydney_Housing - Melbourne_Housing AS Sydney_vs_Melbourne_Housing,
    Sydney_Housing - Brisbane_Housing AS Sydney_vs_Brisbane_Housing,
    Melbourne_Housing - Brisbane_Housing AS Melbourne_vs_Brisbane_Housing,

    Sydney_Food - Melbourne_Food AS Sydney_vs_Melbourne_Food,
    Sydney_Food - Brisbane_Food AS Sydney_vs_Brisbane_Food,
    Melbourne_Food - Brisbane_Food AS Melbourne_vs_Brisbane_Food,

    Sydney_Transport - Melbourne_Transport  AS Sydney_vs_Melbourne_Transport, 
    Sydney_Transport - Brisbane_Transport  AS Sydney_vs_Brisbane_Transport, 
    Melbourne_Transport - Brisbane_Transport AS Melbourne_vs_Brisbane_Transport 

FROM CPI_RawData
WHERE Unit = (SELECT MAX(Unit) FROM CPI_RawData WHERE Unit <'2026-01-01')
    AND Sydney_Food IS NOT NULL;    


--How much have Food, Housing, and Transport costs increased in Sydney, Melbourne, and Brisbane over the last 5 years (March 2020 vs March 2025)

WITH Last_five_year_data AS(
    SELECT 
        Unit,
        Sydney_Housing, 
        Brisbane_Housing, 
        Melbourne_Housing, 

        Sydney_Food,
        Brisbane_Food,
        Melbourne_Food,

        Sydney_Transport,
        Brisbane_Transport,
        Melbourne_Transport
    FROM CPI_RawData 
    WHERE Unit >= DATEADD(year, -5, (SELECT MAX(Unit) FROM CPI_RawData WHERE Unit < '2026-01-01'))
        AND Unit < '2026-01-01'
),

TimePoint AS (
    SELECT 
        MAX(Unit) AS RecentDate, 
        MIN(Unit) AS OldDate
    FROM Last_five_year_data
)
SELECT 
    recent.Unit AS Recent_Quarter, 
    old.Unit AS Old_Quarter,
    recent.Sydney_Housing - old.Sydney_Housing AS Sydney_Housing_Change,
    recent.Melbourne_Housing - old.Melbourne_Housing AS Melbourne_Housing_Change,
    recent.Brisbane_Housing - old.Brisbane_Housing AS Brisbane_Housing_Change
FROM Last_five_year_data recent
CROSS JOIN Last_five_year_data old
CROSS JOIN TimePoint
WHERE recent.Unit = TimePoint.RecentDate
    AND old.Unit = TimePoint.OldDate;

--Compare Food costs across Sydney, Melbourne, and Brisbane between 1 year ago (March 2024) vs now (March 2025). Which city had the biggest food price increase?

WITH FoodCostInOneYear AS(
    SELECT 
        Unit,
        Sydney_Food, 
        Melbourne_Food,
        Brisbane_Food
    FROM CPI_RawData
    WHERE Unit >= DATEADD(year, -1, (SELECT MAX(UNIT) FROM CPI_RawData WHERE Unit < '2026-01-1'))
        AND Unit < '2026-01-01'
),
TimePoint AS (
    SELECT
        MAX(Unit) AS RecentDate,
        MIN(Unit) AS OneYearAgo
    FROM FoodCostInOneYear
)
SELECT 
  RecentDate,
  OneYearAgo,
  recent.Sydney_Food - old.Sydney_Food AS Sydney_Food_Change,
  recent.Melbourne_Food - old.Melbourne_Food AS Melbourne_Food_Change,
  recent.Brisbane_Food - old.Brisbane_Food AS Brisbane_Food_Change
FROM FoodCostInOneYear recent
CROSS JOIN FoodCostInOneYear old
CROSS JOIN TimePoint
WHERE recent.Unit = TimePoint.RecentDate
AND old.Unit = TimePoint.OneYearAgo

--Calculate the percentage growth rate for Food, Housing, and Transport costs in Sydney, Melbourne, and Brisbane over the last 5 years. Which city and which category had the highest growth rate?

WITH Last_Five_Year AS (
    SELECT 
        Unit, 
        Sydney_Housing, 
        Melbourne_Housing, 
        Brisbane_Housing,

        Sydney_Food, 
        Melbourne_Food,
        Brisbane_Food,

        Sydney_Transport, 
        Melbourne_Transport,
        Brisbane_Transport

    FROM CPI_RawData
    WHERE Unit >= DATEADD(year, -5, (SELECT MAX(Unit) FROM CPI_RawData WHERE Unit < '2026-01-01'))
        AND Unit <'2026-01-01'
),
--Getting the exact current date and oldest date for 5 years
TimePoint AS (
    SELECT 
        MAX(Unit) AS RecentDate,
        MIN(Unit) AS OldDate
    FROM Last_Five_Year
)
SELECT 
    RecentDate, 
    OldDate, 
    CAST(((recent.Sydney_Housing - old.Sydney_Housing )/old.Sydney_Housing) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Sydney_Housing,
    CAST(((recent.Melbourne_Housing - old.Melbourne_Housing)/old.Melbourne_Housing) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Melbourne_Housing,
    CAST(((recent.Brisbane_Housing - old.Brisbane_Housing)/old.Brisbane_Housing) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Brisbane_Housing,

    CAST(((recent.Sydney_Food - old.Sydney_Food)/old.Sydney_Food) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Sydney_Food,
    CAST(((recent.Melbourne_Food - old.Melbourne_Food)/old.Melbourne_Food) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Melbourne_Food,
    CAST(((recent.Brisbane_Food - old.Brisbane_Food)/old.Brisbane_Food) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Brisbane_Food,

    CAST(((recent.Sydney_Transport - old.Sydney_Transport)/old.Sydney_Transport) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Sydney_Transport,
    CAST(((recent.Melbourne_Transport - old.Melbourne_Transport)/old.Melbourne_Transport) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Melbourne_Transport,
    CAST(((recent.Brisbane_Transport - old.Brisbane_Transport)/old.Brisbane_Transport) *100 AS DECIMAL(10,2)) AS GrowthRate_in_Brisbane_Transport
FROM Last_Five_Year  recent
CROSS JOIN Last_Five_Year old
CROSS JOIN TimePoint
WHERE recent.Unit = TimePoint.RecentDate
AND old.Unit = TimePoint.OldDate

--For each quarter from 2020 to 2025, calculate the year-over-year percentage change for Sydney Housing. When did housing costs spike the most?

WITH Sydney_Housing_Previous_Year AS(
    SELECT 
        Unit, 
        Sydney_Housing,
        LAG(Sydney_Housing, 4) OVER (ORDER BY Unit) AS Sydney_Housing_In_PreviousYear
    FROM CPI_RawData
    WHERE Unit BETWEEN '2020-01-01' AND '2026-01-01'
)

SELECT 
    Unit,  
    Sydney_Housing, 
    Sydney_Housing_In_PreviousYear,
    CAST((Sydney_Housing -  Sydney_Housing_In_PreviousYear) / Sydney_Housing_In_PreviousYear *100 AS DECIMAL (10,2)) AS Year_Over_Year_Percentage
FROM Sydney_Housing_Previous_Year
WHERE Sydney_Housing_In_PreviousYear IS NOT NULL
ORDER BY Unit;
