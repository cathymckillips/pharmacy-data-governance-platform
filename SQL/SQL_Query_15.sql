USE PharmacyGovernance;
GO

SELECT
    'Medication' AS Dataset,
    COUNT(*) AS Total_Rows,
    SUM(CASE 
        WHEN Data_Quality_Status = 'Issue' THEN 1 
        ELSE 0 
    END) AS Issue_Rows
FROM staging.medication

UNION ALL

SELECT
    'Pharmacy',
    COUNT(*),
    SUM(CASE 
        WHEN Data_Quality_Status = 'Issue' THEN 1 
        ELSE 0 
    END)
FROM staging.pharmacy

UNION ALL

SELECT
    'Formulary',
    COUNT(*),
    SUM(CASE 
        WHEN Data_Quality_Status = 'Issue' THEN 1 
        ELSE 0 
    END)
FROM staging.formulary

UNION ALL

SELECT
    'Pricing',
    COUNT(*),
    SUM(CASE 
        WHEN Data_Quality_Status = 'Issue' THEN 1 
        ELSE 0 
    END)
FROM staging.drug_pricing

UNION ALL

SELECT
    'Claims',
    COUNT(*),
    SUM(CASE 
        WHEN Data_Quality_Status = 'Issue' THEN 1 
        ELSE 0 
    END)
FROM staging.pharmacy_claim;
GO