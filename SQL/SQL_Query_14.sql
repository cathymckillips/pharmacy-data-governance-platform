--run staging--
USE PharmacyGovernance;
GO

TRUNCATE TABLE staging.medication;
GO

INSERT INTO staging.medication
(
    Drug_Reference_ID,
    Source_NDC,
    NDC_11,
    Drug_Name,
    Generic_Name,
    Brand_Name,
    Strength,
    Strength_Unit,
    Dosage_Form,
    Route,
    Manufacturer,
    Drug_Class,
    Active_Flag,
    Effective_Date,
    End_Date,
    Source_System,
    NDC_Valid_Flag,
    Data_Quality_Status
)
SELECT
    Drug_Reference_ID,
    NDC,

    /* Standardize source NDC */
    CASE
        WHEN NDC IS NULL THEN NULL

        WHEN REPLACE(REPLACE(NDC, '-', ''), ' ', '')
             LIKE '%[^0-9]%'
            THEN NULL

        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) = 11
            THEN REPLACE(REPLACE(NDC, '-', ''), ' ', '')

        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) = 10
            THEN '0' + REPLACE(REPLACE(NDC, '-', ''), ' ', '')

        ELSE NULL
    END AS NDC_11,

    LTRIM(RTRIM(Drug_Name)),
    LTRIM(RTRIM(Generic_Name)),
    LTRIM(RTRIM(Brand_Name)),
    Strength,
    LTRIM(RTRIM(Strength_Unit)),

    /* Standardize dosage-form capitalization */
    CASE
        WHEN Dosage_Form IS NULL THEN NULL
        ELSE
            UPPER(LEFT(LTRIM(RTRIM(Dosage_Form)),1))
            +
            LOWER(
                SUBSTRING(
                    LTRIM(RTRIM(Dosage_Form)),
                    2,
                    100
                )
            )
    END,

    LTRIM(RTRIM(Route)),
    LTRIM(RTRIM(Manufacturer)),
    LTRIM(RTRIM(Drug_Class)),
    Active_Flag,
    Effective_Date,
    End_Date,
    Source_System,

    /* NDC validation */
    CASE
        WHEN NDC IS NOT NULL
         AND REPLACE(REPLACE(NDC, '-', ''), ' ', '')
             NOT LIKE '%[^0-9]%'
         AND LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', ''))
             IN (10,11)
        THEN 1
        ELSE 0
    END AS NDC_Valid_Flag,

    /* Initial quality classification */
    CASE
        WHEN NDC IS NULL
            THEN 'Issue'

        WHEN REPLACE(REPLACE(NDC, '-', ''), ' ', '')
             LIKE '%[^0-9]%'
            THEN 'Issue'

        WHEN LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', ''))
             NOT IN (10,11)
            THEN 'Issue'

        WHEN Generic_Name IS NULL
            THEN 'Issue'

        ELSE 'Valid'
    END AS Data_Quality_Status

FROM raw.drug_reference;
GO

--check to see if it worked--
SELECT COUNT(*) AS Medication_Staging_Rows
FROM staging.medication;
GO

--check data quality--
SELECT
    Data_Quality_Status,
    COUNT(*) AS Total_Rows
FROM staging.medication
GROUP BY Data_Quality_Status;
GO

--what it actually did--
SELECT TOP 25
    Drug_Reference_ID,
    Source_NDC,
    NDC_11,
    Drug_Name,
    Generic_Name,
    Dosage_Form,
    NDC_Valid_Flag,
    Data_Quality_Status
FROM staging.medication
WHERE Data_Quality_Status = 'Issue';
GO