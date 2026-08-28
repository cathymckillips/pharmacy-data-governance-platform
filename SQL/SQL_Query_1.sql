TRUNCATE TABLE staging.drug_pricing;
GO

INSERT INTO staging.drug_pricing
(
    Pricing_Record_ID,
    Source_NDC,
    NDC_11,
    Pricing_Methodology,
    Unit_Price,
    Package_Price,
    Effective_Date,
    End_Date,
    Source_System,
    Last_Updated,
    Data_Quality_Status
)
SELECT
    Pricing_Record_ID,
    NDC,

    CASE
        WHEN NDC IS NULL THEN NULL
        WHEN REPLACE(REPLACE(NDC, '-', ''), ' ', '') LIKE '%[^0-9]%' THEN NULL
        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) = 11
            THEN REPLACE(REPLACE(NDC, '-', ''), ' ', '')
        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) = 10
            THEN '0' + REPLACE(REPLACE(NDC, '-', ''), ' ', '')
        ELSE NULL
    END,

    Pricing_Methodology,
    Unit_Price,
    Package_Price,
    Effective_Date,
    End_Date,
    Source_System,
    Last_Updated,

    CASE
        WHEN NDC IS NULL THEN 'Issue'
        WHEN Unit_Price IS NULL OR Unit_Price <= 0 THEN 'Issue'
        WHEN Pricing_Methodology NOT IN ('AWP','WAC','MAC','NADAC','Contract Rate') THEN 'Issue'
        ELSE 'Valid'
    END

FROM raw.drug_pricing;
GO

--Validate--
SELECT
    Data_Quality_Status,
    COUNT(*) AS Total_Rows
FROM staging.drug_pricing
GROUP BY Data_Quality_Status;
GO

--Populate--
TRUNCATE TABLE staging.pharmacy_claim;
GO

INSERT INTO staging.pharmacy_claim
(
    Claim_ID,
    Member_ID,
    Claim_Date,
    Source_NDC,
    NDC_11,
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
    Source_System,
    Data_Quality_Status
)
SELECT
    Claim_ID,
    Member_ID,
    Claim_Date,
    NDC,

    CASE
        WHEN NDC IS NULL THEN NULL
        WHEN REPLACE(REPLACE(NDC, '-', ''), ' ', '') LIKE '%[^0-9]%' THEN NULL
        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) = 11
            THEN REPLACE(REPLACE(NDC, '-', ''), ' ', '')
        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) = 10
            THEN '0' + REPLACE(REPLACE(NDC, '-', ''), ' ', '')
        ELSE NULL
    END,

    LTRIM(RTRIM(Drug_Name)),
    Pharmacy_ID,
    Quantity,
    Days_Supply,
    Ingredient_Cost,
    Dispensing_Fee,
    Member_Pay,
    Plan_Pay,
    Paid_Amount,
    Claim_Status,
    Source_System,

    CASE
        WHEN NDC IS NULL THEN 'Issue'
        WHEN REPLACE(REPLACE(NDC, '-', ''), ' ', '') LIKE '%[^0-9]%' THEN 'Issue'
        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) NOT IN (10,11) THEN 'Issue'
        WHEN Pharmacy_ID IS NULL THEN 'Issue'
        WHEN Paid_Amount < 0 THEN 'Issue'
        WHEN Claim_Status = 'Paid' AND Paid_Amount = 0 THEN 'Issue'
        WHEN Days_Supply <= 0 OR Days_Supply > 365 THEN 'Issue'
        WHEN Claim_Status NOT IN ('Paid','Rejected','Reversed') THEN 'Issue'
        ELSE 'Valid'
    END

FROM raw.pharmacy_claim;
GO

SELECT
    Data_Quality_Status,
    COUNT(*) AS Total_Rows
FROM staging.pharmacy_claim
GROUP BY Data_Quality_Status;
GO