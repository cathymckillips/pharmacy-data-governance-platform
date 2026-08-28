--Validate exception table--
USE PharmacyGovernance;
GO

SELECT
    Rule_ID,
    COUNT(*) AS Exception_Count
FROM governance.data_quality_exception
GROUP BY Rule_ID
ORDER BY Rule_ID;
GO

SELECT
    Severity,
    COUNT(*) AS Exception_Count
FROM governance.data_quality_exception
GROUP BY Severity
ORDER BY Exception_Count DESC;
GO

SELECT
    r.Domain,
    COUNT(e.Exception_ID) AS Exception_Count
FROM governance.data_quality_rule r
LEFT JOIN governance.data_quality_exception e
    ON r.Rule_ID = e.Rule_ID
GROUP BY r.Domain
ORDER BY Exception_Count DESC;
GO

--clear target table--
TRUNCATE TABLE governed.dim_medication;
GO

--Delete--USE PharmacyGovernance;
GO

DELETE FROM governed.fact_drug_pricing;
GO

--Verify--
SELECT COUNT(*) AS Medication_Count
FROM governed.dim_medication;
GO

--Load--

;WITH RankedMedication AS
(
    SELECT
        Drug_Reference_ID,
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

        ROW_NUMBER() OVER
        (
            PARTITION BY NDC_11
            ORDER BY
                CASE WHEN Active_Flag = 'Y' THEN 0 ELSE 1 END,
                Effective_Date DESC,
                Drug_Reference_ID
        ) AS rn

    FROM staging.medication

    WHERE
        NDC_11 IS NOT NULL
        AND NDC_Valid_Flag = 1
        AND Generic_Name IS NOT NULL
)
INSERT INTO governed.dim_medication
(
    Governed_Medication_ID,
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
    Certification_Status
)
SELECT
    'MED-' + RIGHT('000000' + CAST(ROW_NUMBER() OVER (ORDER BY NDC_11) AS VARCHAR(6)), 6),
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
    'Certified'
FROM RankedMedication
WHERE rn = 1;
GO

--Validate--
SELECT COUNT(*) AS Governed_Medications
FROM governed.dim_medication;
GO

--Confirm--
SELECT
    NDC_11,
    COUNT(*) AS Record_Count
FROM governed.dim_medication
GROUP BY NDC_11
HAVING COUNT(*) > 1;
GO