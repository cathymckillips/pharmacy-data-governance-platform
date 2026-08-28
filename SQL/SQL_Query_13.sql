USE PharmacyGovernance;
GO

SELECT 'Drug Reference' AS Dataset, COUNT(*) AS Total_Rows
FROM raw.drug_reference

UNION ALL

SELECT 'Pharmacy Master', COUNT(*)
FROM raw.pharmacy_master

UNION ALL

SELECT 'Formulary', COUNT(*)
FROM raw.formulary

UNION ALL

SELECT 'Drug Pricing', COUNT(*)
FROM raw.drug_pricing

UNION ALL

SELECT 'Pharmacy Claims', COUNT(*)
FROM raw.pharmacy_claim;
GO