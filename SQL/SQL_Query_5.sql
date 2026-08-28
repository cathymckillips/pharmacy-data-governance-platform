--Check Temporary Table--
USE PharmacyGovernance;
GO

SELECT COUNT(*) AS ImportedRows
FROM dbo.import_drug_pricing;
GO

SELECT TOP 10 *
FROM dbo.import_drug_pricing;
GO

--Insert Table--
INSERT INTO raw.drug_pricing
(
    Pricing_Record_ID,
    NDC,
    Pricing_Methodology,
    Unit_Price,
    Package_Price,
    Effective_Date,
    End_Date,
    Source_System,
    Last_Updated
)
SELECT
    Pricing_Record_ID,
    NDC,
    Pricing_Methodology,
    Unit_Price,
    Package_Price,
    Effective_Date,
    End_Date,
    Source_System,
    Last_Updated
FROM dbo.import_drug_pricing;
GO

--Verify Load--
SELECT COUNT(*) AS RawDrugPricingRows
FROM raw.drug_pricing;
GO

SELECT TOP 10 *
FROM raw.drug_pricing;
GO

--Seeded Pricing Issues--
SELECT
    Pricing_Record_ID,
    NDC,
    Pricing_Methodology,
    Unit_Price,
    Package_Price
FROM raw.drug_pricing
WHERE
    Unit_Price <= 0
    OR Package_Price <= 0;
GO

--Check for missing unit prices--
SELECT
    Pricing_Record_ID,
    NDC,
    Pricing_Methodology,
    Unit_Price,
    Package_Price
FROM raw.drug_pricing
WHERE Unit_Price IS NULL;
GO

--Check for unsupported pricing --
SELECT
    Pricing_Record_ID,
    NDC,
    Pricing_Methodology
FROM raw.drug_pricing
WHERE Pricing_Methodology NOT IN
(
    'AWP',
    'WAC',
    'MAC',
    'NADAC',
    'Contract Rate'
);
GO

--Deliberate duplicate pricing rows--
SELECT *
FROM raw.drug_pricing
WHERE Pricing_Record_ID LIKE 'PRC_DUP%';
GO

--Deliberate overlapping pricing records --
SELECT *
FROM raw.drug_pricing
WHERE Pricing_Record_ID LIKE 'PRC_OVR%';
GO

--Check NDCs--
SELECT
    p.Pricing_Record_ID,
    p.NDC,
    p.Pricing_Methodology,
    p.Unit_Price
FROM raw.drug_pricing p
LEFT JOIN raw.drug_reference d
    ON p.NDC = d.NDC
WHERE d.NDC IS NULL;
GO
