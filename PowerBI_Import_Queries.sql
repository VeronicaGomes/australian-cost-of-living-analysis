-- =============================================
-- AUSTRALIAN COST OF LIVING - POWER BI QUERIES
-- =============================================

-- QUERY 1: MAIN DATASET (CPI_Data)
SELECT 
    Unit AS Quarter,
    Sydney_AllGroups, Sydney_Housing, Sydney_Food, Sydney_Transport,
    Melbourne_AllGroups, Melbourne_Housing, Melbourne_Food, Melbourne_Transport,
    Brisbane_AllGroups, Brisbane_Housing, Brisbane_Food, Brisbane_Transport
FROM CPI_RawData
WHERE Unit >= '2000-01-01' 
  AND Unit < '2026-01-01'
  AND Sydney_Food IS NOT NULL
ORDER BY Unit;

-- QUERY 2: YEAR-OVER-YEAR GROWTH (YoY_Growth)
WITH AllCategories_YoY AS (
    SELECT 
        Unit AS Quarter,
        CAST(((Sydney_Housing - LAG(Sydney_Housing, 4) OVER (ORDER BY Unit)) / LAG(Sydney_Housing, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Sydney_Housing_YoY,
        CAST(((Melbourne_Housing - LAG(Melbourne_Housing, 4) OVER (ORDER BY Unit)) / LAG(Melbourne_Housing, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Melbourne_Housing_YoY,
        CAST(((Brisbane_Housing - LAG(Brisbane_Housing, 4) OVER (ORDER BY Unit)) / LAG(Brisbane_Housing, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Brisbane_Housing_YoY,
        CAST(((Sydney_Food - LAG(Sydney_Food, 4) OVER (ORDER BY Unit)) / LAG(Sydney_Food, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Sydney_Food_YoY,
        CAST(((Melbourne_Food - LAG(Melbourne_Food, 4) OVER (ORDER BY Unit)) / LAG(Melbourne_Food, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Melbourne_Food_YoY,
        CAST(((Brisbane_Food - LAG(Brisbane_Food, 4) OVER (ORDER BY Unit)) / LAG(Brisbane_Food, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Brisbane_Food_YoY,
        CAST(((Sydney_Transport - LAG(Sydney_Transport, 4) OVER (ORDER BY Unit)) / LAG(Sydney_Transport, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Sydney_Transport_YoY,
        CAST(((Melbourne_Transport - LAG(Melbourne_Transport, 4) OVER (ORDER BY Unit)) / LAG(Melbourne_Transport, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Melbourne_Transport_YoY,
        CAST(((Brisbane_Transport - LAG(Brisbane_Transport, 4) OVER (ORDER BY Unit)) / LAG(Brisbane_Transport, 4) OVER (ORDER BY Unit)) * 100 AS DECIMAL(10,2)) AS Brisbane_Transport_YoY
    FROM CPI_RawData
    WHERE Unit >= '2020-01-01' AND Unit < '2026-01-01'
)
SELECT * FROM AllCategories_YoY
WHERE Sydney_Housing_YoY IS NOT NULL
ORDER BY Quarter;

-- QUERY 3: GROWTH MATRIX (Growth_Matrix)
WITH TimePoints AS (
    SELECT MIN(Unit) AS StartDate, MAX(Unit) AS EndDate
    FROM CPI_RawData
    WHERE Unit >= '2020-01-01' AND Unit < '2026-01-01'
),
BaselineValues AS (
    SELECT Sydney_Housing, Sydney_Food, Sydney_Transport,
           Melbourne_Housing, Melbourne_Food, Melbourne_Transport,
           Brisbane_Housing, Brisbane_Food, Brisbane_Transport
    FROM CPI_RawData CROSS JOIN TimePoints
    WHERE Unit = TimePoints.StartDate
),
CurrentValues AS (
    SELECT Sydney_Housing, Sydney_Food, Sydney_Transport,
           Melbourne_Housing, Melbourne_Food, Melbourne_Transport,
           Brisbane_Housing, Brisbane_Food, Brisbane_Transport
    FROM CPI_RawData CROSS JOIN TimePoints
    WHERE Unit = TimePoints.EndDate
)
SELECT 'Sydney' AS City, 'Housing' AS Category, CAST(((c.Sydney_Housing - b.Sydney_Housing) / b.Sydney_Housing) * 100 AS DECIMAL(10,2)) AS Growth_Percent FROM BaselineValues b CROSS JOIN CurrentValues c
UNION ALL SELECT 'Sydney', 'Food', CAST(((c.Sydney_Food - b.Sydney_Food) / b.Sydney_Food) * 100 AS DECIMAL(10,2)) FROM BaselineValues b CROSS JOIN CurrentValues c
UNION ALL SELECT 'Sydney', 'Transport', CAST(((c.Sydney_Transport - b.Sydney_Transport) / b.Sydney_Transport) * 100 AS DECIMAL(10,2)) FROM BaselineValues b CROSS JOIN CurrentValues c
UNION ALL SELECT 'Melbourne', 'Housing', CAST(((c.Melbourne_Housing - b.Melbourne_Housing) / b.Melbourne_Housing) * 100 AS DECIMAL(10,2)) FROM BaselineValues b CROSS JOIN CurrentValues c
UNION ALL SELECT 'Melbourne', 'Food', CAST(((c.Melbourne_Food - b.Melbourne_Food) / b.Melbourne_Food) * 100 AS DECIMAL(10,2)) FROM BaselineValues b CROSS JOIN CurrentValues c
UNION ALL SELECT 'Melbourne', 'Transport', CAST(((c.Melbourne_Transport - b.Melbourne_Transport) / b.Melbourne_Transport) * 100 AS DECIMAL(10,2)) FROM BaselineValues b CROSS JOIN CurrentValues c
UNION ALL SELECT 'Brisbane', 'Housing', CAST(((c.Brisbane_Housing - b.Brisbane_Housing) / b.Brisbane_Housing) * 100 AS DECIMAL(10,2)) FROM BaselineValues b CROSS JOIN CurrentValues c
UNION ALL SELECT 'Brisbane', 'Food', CAST(((c.Brisbane_Food - b.Brisbane_Food) / b.Brisbane_Food) * 100 AS DECIMAL(10,2)) FROM BaselineValues b CROSS JOIN CurrentValues c
UNION ALL SELECT 'Brisbane', 'Transport', CAST(((c.Brisbane_Transport - b.Brisbane_Transport) / b.Brisbane_Transport) * 100 AS DECIMAL(10,2)) FROM BaselineValues b CROSS JOIN CurrentValues c
ORDER BY City, Category;