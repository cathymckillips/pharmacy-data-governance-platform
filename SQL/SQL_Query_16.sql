--Staging Pharmacy--
USE PharmacyGovernance;
GO

TRUNCATE TABLE staging.pharmacy;
GO

INSERT INTO staging.pharmacy
(
    Pharmacy_Source_ID,
    NPI,
    NCPDP_ID,
    Pharmacy_Name,
    Pharmacy_Type,
    Address,
    City,
    State,
    ZIP,
    Network_Status,
    Effective_Date,
    End_Date,
    Source_System,
    Data_Quality_Status
)
SELECT
    Pharmacy_Source_ID,
    NULLIF(LTRIM(RTRIM(NPI)), ''),
    NULLIF(LTRIM(RTRIM(NCPDP_ID)), ''),
    LTRIM(RTRIM(Pharmacy_Name)),
    LTRIM(RTRIM(Pharmacy_Type)),
    LTRIM(RTRIM(Address)),
    LTRIM(RTRIM(City)),
    UPPER(LTRIM(RTRIM(State))),
    LTRIM(RTRIM(ZIP)),
    LTRIM(RTRIM(Network_Status)),
    Effective_Date,
    End_Date,
    Source_System,

    CASE
        WHEN NPI IS NULL OR LTRIM(RTRIM(NPI)) = ''
            THEN 'Issue'

        WHEN LEN(LTRIM(RTRIM(NPI))) <> 10
            THEN 'Issue'

        WHEN State IS NULL
            OR LEN(LTRIM(RTRIM(State))) <> 2
            THEN 'Issue'

        WHEN ZIP IS NULL
            OR LEN(LTRIM(RTRIM(ZIP))) <> 5
            OR LTRIM(RTRIM(ZIP)) LIKE '%[^0-9]%'
            THEN 'Issue'

        ELSE 'Valid'
    END AS Data_Quality_Status

FROM raw.pharmacy_master;
GO

--fix varchar from 2 to 20--
USE PharmacyGovernance;
GO

ALTER TABLE staging.pharmacy
ALTER COLUMN State VARCHAR(20) NULL;
GO

--check data quality--
SELECT
    Data_Quality_Status,
    COUNT(*) AS Total_Rows
FROM staging.pharmacy
GROUP BY Data_Quality_Status;
GO

--inspect invalid state values--
SELECT
    Pharmacy_Source_ID,
    Pharmacy_Name,
    State,
    Data_Quality_Status
FROM staging.pharmacy
WHERE LEN(State) <> 2;
GO