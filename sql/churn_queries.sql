-- ============================================================
-- Customer Churn Analysis: SQL queries (PostgreSQL)
-- Table: telco (loaded from telco_cleaned.csv, 7,043 rows)
-- ============================================================

-- Q1. Overall churn rate
SELECT
    COUNT(*)                                              AS total_customers,
    SUM(ChurnFlag)                                        AS churned_customers,
    ROUND(100.0 * SUM(ChurnFlag) / COUNT(*), 2)           AS churn_rate_pct
FROM telco;

-- Q2. Top 5 segments by churn rate
-- Segment = Contract + TenureGroup + PaymentMethod (HAVING removes tiny groups)
SELECT
    Contract, TenureGroup, PaymentMethod,
    COUNT(*)                                              AS customers,
    ROUND(100.0 * SUM(ChurnFlag) / COUNT(*), 2)           AS churn_rate_pct
FROM telco
GROUP BY Contract, TenureGroup, PaymentMethod
HAVING COUNT(*) >= 30
ORDER BY churn_rate_pct DESC
LIMIT 5;

-- Q3. Average monthly charges: churned vs active
SELECT
    CASE WHEN ChurnFlag = 1 THEN 'Churned' ELSE 'Active' END AS status,
    COUNT(*)                                              AS customers,
    ROUND(AVG(MonthlyCharges), 2)                         AS avg_monthly_charges
FROM telco
GROUP BY ChurnFlag
ORDER BY status;

-- Q4. Customers with high monthly charges and short tenure
-- High = above the overall average charge (subquery); short = 12 months or less
SELECT customerID, Contract, tenure, MonthlyCharges, Churn
FROM telco
WHERE MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM telco)
  AND tenure <= 12
ORDER BY MonthlyCharges DESC
LIMIT 50;

-- Q5. Churn by contract type
SELECT
    Contract,
    COUNT(*)                                              AS customers,
    SUM(ChurnFlag)                                        AS churned,
    ROUND(100.0 * SUM(ChurnFlag) / COUNT(*), 2)           AS churn_rate_pct
FROM telco
GROUP BY Contract
ORDER BY churn_rate_pct DESC;

-- Q6. Churn by payment method
SELECT
    PaymentMethod,
    COUNT(*)                                              AS customers,
    SUM(ChurnFlag)                                        AS churned,
    ROUND(100.0 * SUM(ChurnFlag) / COUNT(*), 2)           AS churn_rate_pct
FROM telco
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;

-- Q7. Monthly revenue associated with churned customers (CTE)
WITH revenue AS (
    SELECT
        SUM(MonthlyCharges)                                         AS total_mrr,
        SUM(CASE WHEN ChurnFlag = 1 THEN MonthlyCharges ELSE 0 END) AS churned_mrr
    FROM telco
)
SELECT
    ROUND(total_mrr, 2)                                   AS total_monthly_revenue,
    ROUND(churned_mrr, 2)                                 AS churned_monthly_revenue,
    ROUND(100.0 * churned_mrr / total_mrr, 2)             AS pct_revenue_lost_to_churn
FROM revenue;

-- Q8. Rank segments by churn rate (CTE + window function)
WITH seg AS (
    SELECT
        Contract, InternetService,
        COUNT(*)                                          AS customers,
        ROUND(100.0 * SUM(ChurnFlag) / COUNT(*), 2)       AS churn_rate_pct
    FROM telco
    GROUP BY Contract, InternetService
    HAVING COUNT(*) >= 30
)
SELECT
    RANK() OVER (ORDER BY churn_rate_pct DESC)            AS churn_rank,
    Contract, InternetService, customers, churn_rate_pct
FROM seg
ORDER BY churn_rank;

-- Q9. Retention across tenure groups
SELECT
    TenureGroup,
    COUNT(*)                                              AS customers,
    ROUND(100.0 * SUM(1 - ChurnFlag) / COUNT(*), 2)       AS retention_rate_pct,
    ROUND(100.0 * SUM(ChurnFlag) / COUNT(*), 2)           AS churn_rate_pct
FROM telco
GROUP BY TenureGroup
ORDER BY MIN(tenure);

-- Q10. High-value churned customers
-- High-value = top 25% of monthly charges (NTILE window function)
WITH ranked AS (
    SELECT
        customerID, Contract, tenure, MonthlyCharges, ChurnFlag,
        NTILE(4) OVER (ORDER BY MonthlyCharges DESC)      AS charge_quartile
    FROM telco
)
SELECT customerID, Contract, tenure, MonthlyCharges
FROM ranked
WHERE charge_quartile = 1 AND ChurnFlag = 1
ORDER BY MonthlyCharges DESC
LIMIT 50;

-- Q11. Share of churn by revenue category with a running total (window function)
SELECT
    MonthlyRevenueCategory,
    COUNT(*)                                              AS customers,
    SUM(ChurnFlag)                                        AS churned,
    SUM(SUM(ChurnFlag)) OVER (ORDER BY MonthlyRevenueCategory) AS running_churned
FROM telco
GROUP BY MonthlyRevenueCategory
ORDER BY MonthlyRevenueCategory;
