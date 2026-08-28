--Check imported Rows--
SELECT COUNT(*) AS ImportedRows
FROM dbo.import_drug_reference_raw;


--Run Query to Compare with import--
SELECT TOP 10 *
FROM dbo.import_drug_reference_raw;

--Insert real raw table data--

INSERT INTO raw.drug_reference
(
    Drug_Reference_ID,
    NDC,
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
    Source_System
)
SELECT
    Drug_Reference_ID,
    NDC,
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
    Source_System
FROM dbo.import_drug_reference_raw;

--Verify Raw Drug References--

SELECT COUNT(*) AS RawDrugReferenceRows
FROM raw.drug_reference;

--Inspect messy data records--

SELECT TOP 25 *
FROM raw.drug_reference
WHERE
    NDC IS NULL
    OR LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) <> 11
    OR Generic_Name IS NULL
    OR Dosage_Form = UPPER(Dosage_Form);

    USE PharmacyGovernance;

--Check temporary import first--
GO

SELECT COUNT(*) AS ImportedRows
FROM dbo.import_pharmacy_master;
GO

SELECT TOP 10 *
FROM dbo.import_pharmacy_master;
GO

--Insert Raw Table--

INSERT INTO raw.pharmacy_master
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
    Source_System
)
SELECT
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
    Source_System
FROM dbo.import_pharmacy_master;
GO

--Check Raw Load--
SELECT COUNT(*) AS RawPharmacyRows
FROM raw.pharmacy_master;
GO

SELECT TOP 10 *
FROM raw.pharmacy_master;
GO

--Check Deliberate Bad Data--
SELECT
    Pharmacy_Source_ID,
    NPI,
    NCPDP_ID,
    Pharmacy_Name,
    State,
    ZIP,
    Network_Status,
    End_Date
FROM raw.pharmacy_master
WHERE
       NPI IS NULL
    OR LEN(NPI) <> 10
    OR LEN(State) <> 2
    OR State IN ('XX', 'ZZ')
    OR LEN(ZIP) <> 5
    OR ZIP LIKE '%[^0-9]%';
GO

--Check Duplicate NPIs--
SELECT
    NPI,
    COUNT(*) AS Record_Count
FROM raw.pharmacy_master
WHERE NPI IS NOT NULL
GROUP BY NPI
HAVING COUNT(*) > 1
ORDER BY Record_Count DESC;
GO

--Check terminated pharmacies that still appear active--
SELECT
    Pharmacy_Source_ID,
    Pharmacy_Name,
    NPI,
    Network_Status,
    Effective_Date,
    End_Date
FROM raw.pharmacy_master
WHERE
    End_Date IS NOT NULL
    AND Network_Status = 'In Network'
ORDER BY End_Date;
GO