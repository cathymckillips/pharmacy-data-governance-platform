--Staging for Formulary--

USE PharmacyGovernance;
GO

TRUNCATE TABLE staging.formulary;
GO

INSERT INTO staging.formulary
(
    Formulary_Record_ID,
    Plan_ID,
    Source_NDC,
    NDC_11,
    Drug_Name,
    Formulary_Tier,
    Coverage_Status,
    Prior_Authorization_Flag,
    Step_Therapy_Flag,
    Quantity_Limit_Flag,
    Effective_Date,
    End_Date,
    Source_System,
    Data_Quality_Status
)
SELECT
    Formulary_Record_ID,
    Plan_ID,
    NDC,

    CASE
        WHEN NDC IS NULL THEN NULL
        WHEN REPLACE(REPLACE(NDC, '-', ''), ' ', '') LIKE '%[^0-9]%' THEN NULL
        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) = 11
            THEN REPLACE(REPLACE(NDC, '-', ''), ' ', '')
        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) = 10
            THEN '0' + REPLACE(REPLACE(NDC, '-', ''), ' ', '')
        ELSE NULL
    END AS NDC_11,

    LTRIM(RTRIM(Drug_Name)),
    Formulary_Tier,
    NULLIF(LTRIM(RTRIM(Coverage_Status)), ''),
    Prior_Authorization_Flag,
    Step_Therapy_Flag,
    Quantity_Limit_Flag,
    Effective_Date,
    End_Date,
    Source_System,

    CASE
        WHEN NDC IS NULL THEN 'Issue'
        WHEN REPLACE(REPLACE(NDC, '-', ''), ' ', '') LIKE '%[^0-9]%' THEN 'Issue'
        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) NOT IN (10,11) THEN 'Issue'
        WHEN Formulary_Tier NOT BETWEEN 1 AND 5 THEN 'Issue'
        WHEN Coverage_Status IS NULL OR LTRIM(RTRIM(Coverage_Status)) = '' THEN 'Issue'
        ELSE 'Valid'
    END AS Data_Quality_Status

FROM raw.formulary;
GO

--Validate--
SELECT
    Data_Quality_Status,
    COUNT(*) AS Total_Rows
FROM staging.formulary
GROUP BY Data_Quality_Status;
GO

--inspect issues--
SELECT TOP 25
    Formulary_Record_ID,
    Plan_ID,
    Source_NDC,
    NDC_11,
    Drug_Name,
    Formulary_Tier,
    Coverage_Status,
    Data_Quality_Status
FROM staging.formulary
WHERE Data_Quality_Status = 'Issue';
GO

--re-run staging summary--
SELECT
    'Medication' AS Dataset,
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN Data_Quality_Status = 'Issue' THEN 1 ELSE 0 END) AS Issue_Rows
FROM staging.medication

UNION ALL

SELECT
    'Pharmacy',
    COUNT(*),
    SUM(CASE WHEN Data_Quality_Status = 'Issue' THEN 1 ELSE 0 END)
FROM staging.pharmacy

UNION ALL

SELECT
    'Formulary',
    COUNT(*),
    SUM(CASE WHEN Data_Quality_Status = 'Issue' THEN 1 ELSE 0 END)
FROM staging.formulary

UNION ALL

SELECT
    'Pricing',
    COUNT(*),
    SUM(CASE WHEN Data_Quality_Status = 'Issue' THEN 1 ELSE 0 END)
FROM staging.drug_pricing

UNION ALL

SELECT
    'Claims',
    COUNT(*),
    SUM(CASE WHEN Data_Quality_Status = 'Issue' THEN 1 ELSE 0 END)
FROM staging.pharmacy_claim;
GO