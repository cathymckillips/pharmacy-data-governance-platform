--Phase 3--
--Clear exception table--
USE PharmacyGovernance;
GO

TRUNCATE TABLE governance.data_quality_exception;
GO

--Log medication exceptions--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ001',
    Drug_Reference_ID,
    Source_System,
    'raw.drug_reference',
    'NDC',
    'Missing NDC',
    'Medication record is missing an NDC value.',
    'Critical',
    NDC,
    'Valid 10- or 11-digit NDC',
    'Pharmacy Data Steward'
FROM raw.drug_reference
WHERE NDC IS NULL;
GO

--Invalid NDC format--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ002',
    Drug_Reference_ID,
    Source_System,
    'raw.drug_reference',
    'NDC',
    'Invalid NDC Format',
    'NDC cannot be standardized to an 11-digit numeric value.',
    'Critical',
    NDC,
    '10- or 11-digit numeric NDC',
    'Pharmacy Data Steward'
FROM raw.drug_reference
WHERE NDC IS NOT NULL
AND
(
       REPLACE(REPLACE(NDC, '-', ''), ' ', '') LIKE '%[^0-9]%'
    OR LEN(REPLACE(REPLACE(NDC, '-', ''), ' ', '')) NOT IN (10,11)
);
GO

--Duplicate active NDC--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ004',
    m.Drug_Reference_ID,
    m.Source_System,
    'staging.medication',
    'NDC_11',
    'Duplicate Active NDC',
    'More than one active medication record exists for the same standardized NDC.',
    'Critical',
    m.NDC_11,
    'One active medication record per NDC-11',
    'Pharmacy Data Steward'
FROM staging.medication m
INNER JOIN
(
    SELECT NDC_11
    FROM staging.medication
    WHERE NDC_11 IS NOT NULL
      AND Active_Flag = 'Y'
    GROUP BY NDC_11
    HAVING COUNT(*) > 1
) d
    ON m.NDC_11 = d.NDC_11
WHERE m.Active_Flag = 'Y';
GO

--Missing generic name--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ006',
    Drug_Reference_ID,
    Source_System,
    'raw.drug_reference',
    'Generic_Name',
    'Missing Generic Name',
    'Medication record is missing the generic medication name.',
    'Medium',
    Generic_Name,
    'Populated generic medication name',
    'Pharmacy Data Steward'
FROM raw.drug_reference
WHERE Generic_Name IS NULL
   OR LTRIM(RTRIM(Generic_Name)) = '';
GO

--log pharmacy exceptions--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ016',
    p.Pharmacy_Source_ID,
    p.Source_System,
    'raw.pharmacy_master',
    'NPI',
    'Duplicate NPI',
    'More than one pharmacy record uses the same NPI.',
    'Critical',
    p.NPI,
    'Unique NPI per governed pharmacy',
    'Provider Data Steward'
FROM raw.pharmacy_master p
INNER JOIN
(
    SELECT NPI
    FROM raw.pharmacy_master
    WHERE NPI IS NOT NULL
    GROUP BY NPI
    HAVING COUNT(*) > 1
) d
    ON p.NPI = d.NPI;
GO

--missing NPI--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ017',
    Pharmacy_Source_ID,
    Source_System,
    'raw.pharmacy_master',
    'NPI',
    'Missing NPI',
    'Pharmacy record does not contain an NPI.',
    'Medium',
    NPI,
    '10-digit NPI',
    'Provider Data Steward'
FROM raw.pharmacy_master
WHERE NPI IS NULL
   OR LTRIM(RTRIM(NPI)) = '';
GO

--invalid state code--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ018',
    Pharmacy_Source_ID,
    Source_System,
    'raw.pharmacy_master',
    'State',
    'Invalid State Code',
    'State value is not a valid two-character state code.',
    'Low',
    State,
    'Valid two-character US state code',
    'Provider Data Steward'
FROM raw.pharmacy_master
WHERE State IS NULL
   OR LEN(LTRIM(RTRIM(State))) <> 2
   OR UPPER(LTRIM(RTRIM(State))) IN ('XX','ZZ');
GO

--log formulary exceptions--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ010',
    f.Formulary_Record_ID,
    f.Source_System,
    'staging.formulary',
    'NDC_11',
    'Medication Not Found',
    'Formulary NDC does not match a standardized medication record.',
    'High',
    f.NDC_11,
    'NDC present in medication master',
    'Formulary Data Steward'
FROM staging.formulary f
LEFT JOIN staging.medication m
    ON f.NDC_11 = m.NDC_11
WHERE f.NDC_11 IS NOT NULL
  AND m.NDC_11 IS NULL;
GO

--invalid formulary tier--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ011',
    Formulary_Record_ID,
    Source_System,
    'raw.formulary',
    'Formulary_Tier',
    'Invalid Formulary Tier',
    'Formulary tier falls outside the approved range.',
    'Medium',
    CAST(Formulary_Tier AS VARCHAR(20)),
    'Tier 1 through 5',
    'Formulary Data Steward'
FROM raw.formulary
WHERE Formulary_Tier NOT BETWEEN 1 AND 5;
GO

--log pricing expections--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ009',
    Pricing_Record_ID,
    Source_System,
    'raw.drug_pricing',
    'Unit_Price',
    'Invalid Price',
    'Unit price is missing, zero, or negative.',
    'Critical',
    CAST(Unit_Price AS VARCHAR(50)),
    'Unit price greater than zero',
    'Pricing Data Steward'
FROM raw.drug_pricing
WHERE Unit_Price IS NULL
   OR Unit_Price <= 0;
GO

--log claim exceptions--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ013',
    c.Claim_ID,
    c.Source_System,
    'raw.pharmacy_claim',
    'Claim_ID',
    'Duplicate Claim',
    'Claim ID appears more than once in the source data.',
    'High',
    c.Claim_ID,
    'Unique Claim ID',
    'Claims Data Steward'
FROM raw.pharmacy_claim c
INNER JOIN
(
    SELECT Claim_ID
    FROM raw.pharmacy_claim
    GROUP BY Claim_ID
    HAVING COUNT(*) > 1
) d
    ON c.Claim_ID = d.Claim_ID;
GO

--negative paid amount--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ014',
    Claim_ID,
    Source_System,
    'raw.pharmacy_claim',
    'Paid_Amount',
    'Negative Paid Amount',
    'Claim contains an unexpectedly negative paid amount.',
    'High',
    CAST(Paid_Amount AS VARCHAR(50)),
    'Paid amount greater than or equal to zero',
    'Claims Data Steward'
FROM raw.pharmacy_claim
WHERE Paid_Amount < 0;
GO

--pharmacy not found--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ015',
    c.Claim_ID,
    c.Source_System,
    'raw.pharmacy_claim',
    'Pharmacy_ID',
    'Pharmacy Not Found',
    'Claim references a pharmacy that cannot be matched to the pharmacy master.',
    'High',
    c.Pharmacy_ID,
    'Valid Pharmacy_Source_ID',
    'Claims Data Steward'
FROM raw.pharmacy_claim c
LEFT JOIN raw.pharmacy_master p
    ON c.Pharmacy_ID = p.Pharmacy_Source_ID
WHERE c.Pharmacy_ID IS NULL
   OR p.Pharmacy_Source_ID IS NULL;
GO

--paid claim with zero paid amount--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ019',
    Claim_ID,
    Source_System,
    'raw.pharmacy_claim',
    'Paid_Amount',
    'Paid Claim With Zero Amount',
    'Claim status is Paid but paid amount equals zero.',
    'Medium',
    CAST(Paid_Amount AS VARCHAR(50)),
    'Paid amount greater than zero for Paid claims',
    'Claims Data Steward'
FROM raw.pharmacy_claim
WHERE Claim_Status = 'Paid'
  AND Paid_Amount = 0;
GO

--invalid days supply--
INSERT INTO governance.data_quality_exception
(
    Rule_ID,
    Record_ID,
    Source_System,
    Source_Table,
    Source_Field,
    Issue_Type,
    Issue_Description,
    Severity,
    Detected_Value,
    Expected_Value,
    Assigned_Steward
)
SELECT
    'DQ020',
    Claim_ID,
    Source_System,
    'raw.pharmacy_claim',
    'Days_Supply',
    'Invalid Days Supply',
    'Days supply falls outside the accepted range.',
    'Medium',
    CAST(Days_Supply AS VARCHAR(50)),
    'Days supply between 1 and 365',
    'Claims Data Steward'
FROM raw.pharmacy_claim
WHERE Days_Supply <= 0
   OR Days_Supply > 365;
GO

--validate the exception layer--
SELECT
    Rule_ID,
    COUNT(*) AS Exception_Count
FROM governance.data_quality_exception
GROUP BY Rule_ID
ORDER BY Rule_ID;
GO

--Servity--
SELECT
    Severity,
    COUNT(*) AS Exception_Count
FROM governance.data_quality_exception
GROUP BY Severity
ORDER BY Exception_Count DESC;
GO

--Governance Summary--
SELECT
    r.Domain,
    COUNT(e.Exception_ID) AS Exception_Count
FROM governance.data_quality_rule r
LEFT JOIN governance.data_quality_exception e
    ON r.Rule_ID = e.Rule_ID
GROUP BY r.Domain
ORDER BY Exception_Count DESC;
GO
