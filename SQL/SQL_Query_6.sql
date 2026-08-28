--Verify--
USE PharmacyGovernance;
GO

SELECT COUNT(*) AS ImportedRows
FROM dbo.import_pharmacy_claims;
GO

SELECT TOP 10 *
FROM dbo.import_pharmacy_claims;
GO

--insert table--
INSERT INTO raw.pharmacy_claim
(
    Claim_ID,
    Member_ID,
    Claim_Date,
    NDC,
    Drug_Name,
    Pharmacy_ID,
    Quantity,
    Days_Supply,
    Ingredient_Cost,
    Dispensing_Fee,
    Member_Pay,
    Plan_Pay,
    Paid_Amount,
    Claim_Status,
    Source_System
)
SELECT
    Claim_ID,
    Member_ID,
    Claim_Date,
    NDC,
    Drug_Name,
    Pharmacy_ID,
    Quantity,
    Days_Supply,
    Ingredient_Cost,
    Dispensing_Fee,
    Member_Pay,
    Plan_Pay,
    Paid_Amount,
    Claim_Status,
    Source_System
FROM dbo.import_pharmacy_claims;
GO

--Verify load--
SELECT COUNT(*) AS RawClaimRows
FROM raw.pharmacy_claim;
GO

SELECT TOP 10 *
FROM raw.pharmacy_claim;
GO

--Missing or malformed NDCs--
SELECT TOP 50
    Claim_ID,
    NDC,
    Drug_Name
FROM raw.pharmacy_claim
WHERE
    NDC IS NULL
    OR LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) NOT IN (9,10,11)
    OR REPLACE(REPLACE(NDC, '-', ''), ' ', '') LIKE '%[^0-9]%';
GO

--Missing or unknown pharmacies--
SELECT TOP 50
    Claim_ID,
    Pharmacy_ID,
    Claim_Status,
    Paid_Amount
FROM raw.pharmacy_claim
WHERE
    Pharmacy_ID IS NULL
    OR Pharmacy_ID LIKE 'PHM_UNKNOWN%';
GO

--Negative paid amounts--
SELECT
    Claim_ID,
    Member_ID,
    Paid_Amount,
    Claim_Status
FROM raw.pharmacy_claim
WHERE Paid_Amount < 0;
GO

--Paid Cliams with zero paid--
SELECT
    Claim_ID,
    Paid_Amount,
    Claim_Status
FROM raw.pharmacy_claim
WHERE
    Claim_Status = 'Paid'
    AND Paid_Amount = 0;
GO

--Invalid Days Supply--
SELECT
    Claim_ID,
    Days_Supply,
    Drug_Name
FROM raw.pharmacy_claim
WHERE
    Days_Supply <= 0
    OR Days_Supply > 365;
GO

--Duplicate Claims--
SELECT
    Claim_ID,
    COUNT(*) AS Record_Count
FROM raw.pharmacy_claim
GROUP BY Claim_ID
HAVING COUNT(*) > 1
ORDER BY Record_Count DESC;
GO